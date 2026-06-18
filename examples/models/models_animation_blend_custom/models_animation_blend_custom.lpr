program models_animation_blend_custom;

{$mode objfpc}{$H+}

uses
  cmem, raylib, raymath, rlgl, sysutils, math;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

// Check if a bone is part of upper body (for selective blending)
function IsUpperBodyBone(const boneName: PAnsiChar): Boolean;
begin
  Result := False;

  // Common upper body bone names
  if TextIsEqual(boneName, 'spine') or TextIsEqual(boneName, 'spine1') or TextIsEqual(boneName, 'spine2') or
     TextIsEqual(boneName, 'chest') or TextIsEqual(boneName, 'upperChest') or
     TextIsEqual(boneName, 'neck') or TextIsEqual(boneName, 'head') or
     TextIsEqual(boneName, 'shoulder') or TextIsEqual(boneName, 'shoulder_L') or TextIsEqual(boneName, 'shoulder_R') or
     TextIsEqual(boneName, 'upperArm') or TextIsEqual(boneName, 'upperArm_L') or TextIsEqual(boneName, 'upperArm_R') or
     TextIsEqual(boneName, 'lowerArm') or TextIsEqual(boneName, 'lowerArm_L') or TextIsEqual(boneName, 'lowerArm_R') or
     TextIsEqual(boneName, 'hand') or TextIsEqual(boneName, 'hand_L') or TextIsEqual(boneName, 'hand_R') or
     TextIsEqual(boneName, 'clavicle') or TextIsEqual(boneName, 'clavicle_L') or TextIsEqual(boneName, 'clavicle_R') then
  begin
    Result := True;
    Exit;
  end;

  // Check if bone name contains upper body keywords
  if (Pos('spine', boneName) > 0) or (Pos('chest', boneName) > 0) or
     (Pos('neck', boneName) > 0) or (Pos('head', boneName) > 0) or
     (Pos('shoulder', boneName) > 0) or (Pos('arm', boneName) > 0) or
     (Pos('hand', boneName) > 0) or (Pos('clavicle', boneName) > 0) then
  begin
    Result := True;
  end;
end;

// Blend two animations per-bone with selective upper/lower body blending
procedure UpdateModelAnimationBones(model: PModel; anim0, anim1: PModelAnimation;
  frame0, frame1: Integer; blend: Single; upperBodyBlend: Boolean);
var
  boneCount, boneIndex, m, vCounter, j, boneCounter: Integer;
  boneBlendFactor: Single;
  boneName: PAnsiChar;
  bindTransform, animTransform0, animTransform1: PTransform;
  blended: TTransform;
  bindMatrix, blendedMatrix: TMatrix;
  mesh: TMesh;
  vertexValuesCount: Integer;
  animVertex, animNormal: TVector3;
  boneWeight: Single;
  boneIndexV: Integer;
  bufferUpdateRequired: Boolean;
  transpMatrix: TMatrix;
begin
  // Validate inputs
  if (anim0^.boneCount = 0) or (anim0^.keyframePoses = nil) or
     (anim1^.boneCount = 0) or (anim1^.keyframePoses = nil) or
     (model^.skeleton.boneCount = 0) or (model^.skeleton.bindPose = nil) then
  begin
    Exit;
  end;

  // Clamp blend factor to [0, 1]
  if blend < 0.0 then blend := 0.0;
  if blend > 1.0 then blend := 1.0;

  // Ensure frame indices are valid
  if frame0 >= anim0^.keyframeCount then frame0 := anim0^.keyframeCount - 1;
  if frame1 >= anim1^.keyframeCount then frame1 := anim1^.keyframeCount - 1;
  if frame0 < 0 then frame0 := 0;
  if frame1 < 0 then frame1 := 0;

  // Get bone count (use minimum of all to be safe)
  boneCount := model^.skeleton.boneCount;
  if anim0^.boneCount < boneCount then boneCount := anim0^.boneCount;
  if anim1^.boneCount < boneCount then boneCount := anim1^.boneCount;

  // Blend each bone
  for boneIndex := 0 to boneCount - 1 do
  begin
    // Determine blend factor for this bone
    boneBlendFactor := blend;

    // If upper body blending is enabled, use different blend factors for upper vs lower body
    if upperBodyBlend then
    begin
      boneName := model^.skeleton.BoneInfo[boneIndex].name;
      if IsUpperBodyBone(boneName) then
        boneBlendFactor := blend  // Upper body: blend towards anim1 (attack)
      else
        boneBlendFactor := 1.0 - blend; // Lower body: blend towards anim0 (walk)
    end;

    // Get transforms from both animations
    bindTransform := @model^.skeleton.bindPose[boneIndex];
    animTransform0 := @anim0^.keyframePoses[frame0][boneIndex];
    animTransform1 := @anim1^.keyframePoses[frame1][boneIndex];

    // Blend the transforms
    blended.translation := Vector3Lerp(animTransform0^.translation, animTransform1^.translation, boneBlendFactor);
    blended.rotation := QuaternionSlerp(animTransform0^.rotation, animTransform1^.rotation, boneBlendFactor);
    blended.scale := Vector3Lerp(animTransform0^.scale, animTransform1^.scale, boneBlendFactor);

    // Convert bind pose to matrix
    bindMatrix := MatrixMultiply(
      MatrixMultiply(
        MatrixScale(bindTransform^.scale.x, bindTransform^.scale.y, bindTransform^.scale.z),
        QuaternionToMatrix(bindTransform^.rotation)),
      MatrixTranslate(bindTransform^.translation.x, bindTransform^.translation.y, bindTransform^.translation.z));

    // Convert blended transform to matrix
    blendedMatrix := MatrixMultiply(
      MatrixMultiply(
        MatrixScale(blended.scale.x, blended.scale.y, blended.scale.z),
        QuaternionToMatrix(blended.rotation)),
      MatrixTranslate(blended.translation.x, blended.translation.y, blended.translation.z));

    // Calculate final bone matrix
    model^.boneMatrices[boneIndex] := MatrixMultiply(MatrixInvert(bindMatrix), blendedMatrix);
  end;

  // CPU skinning, updates CPU buffers and uploads them to GPU
  for m := 0 to model^.meshCount - 1 do
  begin
    mesh := model^.meshes[m];

    // Skip if missing bone data or anim buffers
    if (mesh.boneWeights = nil) or (mesh.boneIndices = nil) or
       (mesh.animVertices = nil) or (mesh.animNormals = nil) then
      Continue;

    vertexValuesCount := mesh.vertexCount * 3;
    bufferUpdateRequired := False;
    boneCounter := 0;

    for vCounter := 0 to vertexValuesCount - 1 do
    begin
      // Initialize anim vertices
      if vCounter mod 3 = 0 then
      begin
        mesh.animVertices[vCounter] := 0;
        mesh.animVertices[vCounter + 1] := 0;
        mesh.animVertices[vCounter + 2] := 0;

        if mesh.animNormals <> nil then
        begin
          mesh.animNormals[vCounter] := 0;
          mesh.animNormals[vCounter + 1] := 0;
          mesh.animNormals[vCounter + 2] := 0;
        end;

        // Process 4 bones per vertex
        for j := 0 to 3 do
        begin
          boneWeight := mesh.boneWeights[boneCounter];
          boneIndexV := mesh.boneIndices[boneCounter];
          Inc(boneCounter);

          // Early stop when no transformation will be applied
          if boneWeight = 0.0 then Continue;

          // Transform vertex position
          animVertex := Vector3Create(
            mesh.vertices[vCounter],
            mesh.vertices[vCounter + 1],
            mesh.vertices[vCounter + 2]
          );
          animVertex := Vector3Transform(animVertex, model^.boneMatrices[boneIndexV]);

          mesh.animVertices[vCounter] := mesh.animVertices[vCounter] + animVertex.x * boneWeight;
          mesh.animVertices[vCounter + 1] := mesh.animVertices[vCounter + 1] + animVertex.y * boneWeight;
          mesh.animVertices[vCounter + 2] := mesh.animVertices[vCounter + 2] + animVertex.z * boneWeight;
          bufferUpdateRequired := True;

          // Transform normal
          if (mesh.normals <> nil) and (mesh.animNormals <> nil) then
          begin
            animNormal := Vector3Create(
              mesh.normals[vCounter],
              mesh.normals[vCounter + 1],
              mesh.normals[vCounter + 2]
            );
            transpMatrix := MatrixTranspose(MatrixInvert(model^.boneMatrices[boneIndexV]));
            animNormal := Vector3Transform(animNormal, transpMatrix);

            mesh.animNormals[vCounter] := mesh.animNormals[vCounter] + animNormal.x * boneWeight;
            mesh.animNormals[vCounter + 1] := mesh.animNormals[vCounter + 1] + animNormal.y * boneWeight;
            mesh.animNormals[vCounter + 2] := mesh.animNormals[vCounter + 2] + animNormal.z * boneWeight;
          end;
        end;
      end;
    end;

    if bufferUpdateRequired then
    begin
      // Update GPU vertex buffers
      rlUpdateVertexBuffer(
        mesh.vboId[SHADER_LOC_VERTEX_POSITION],
        mesh.animVertices,
        mesh.vertexCount * 3 * SizeOf(Single),
        0
      );

      if mesh.normals <> nil then
      begin
        rlUpdateVertexBuffer(
          mesh.vboId[SHADER_LOC_VERTEX_NORMAL],
          mesh.animNormals,
          mesh.vertexCount * 3 * SizeOf(Single),
          0
        );
      end;
    end;
  end;
end;

var
  camera: TCamera3D;
  model: TModel;
  position: TVector3;
  skinningShader: TShader;
  animCount: Integer;
  anims: PModelAnimation;
  animIndex0, animIndex1: Integer;
  animCurrentFrame0, animCurrentFrame1: Integer;
  upperBodyBlend: Boolean;
  anim0, anim1: TModelAnimation;
  blendFactor: Single;

begin
  // Initialization
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - animation blend custom');

  // Camera setup
  camera.position := Vector3Create(4.0, 4.0, 4.0);
  camera.target := Vector3Create(0.0, 1.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  // Load model
  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'));
  position := Vector3Create(0.0, 0.0, 0.0);

  // Load skinning shader
  skinningShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/skinning.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/skinning.fs', GLSL_VERSION))
  );
  model.materials[1].shader := skinningShader;

  // Load animations
  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'), @animCount);

  // Use specific animation indices: 2-walk/move, 3-attack
  animIndex0 := 2;
  animIndex1 := 3;
  animCurrentFrame0 := 0;
  animCurrentFrame1 := 0;

  // Validate indices
  if animIndex0 >= animCount then animIndex0 := 0;
  if animIndex1 >= animCount then
  begin
    if animCount > 1 then animIndex1 := 1
    else animIndex1 := 0;
  end;

  upperBodyBlend := True;

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    UpdateCamera(@camera, CAMERA_ORBITAL);

    // Toggle blending mode
    if IsKeyPressed(KEY_SPACE) then
      upperBodyBlend := not upperBodyBlend;

    // Update animation frames
    anim0 := anims[animIndex0];
    anim1 := anims[animIndex1];

    animCurrentFrame0 := (animCurrentFrame0 + 1) mod anim0.keyframeCount;
    animCurrentFrame1 := (animCurrentFrame1 + 1) mod anim1.keyframeCount;

    // Blend factor
    if upperBodyBlend then
      blendFactor := 1.0
    else
      blendFactor := 0.5;

    // Apply custom animation blending
    UpdateModelAnimationBones(@model, @anim0, @anim1,
      animCurrentFrame0, animCurrentFrame1, blendFactor, upperBodyBlend);

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, position, 1.0, WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      // UI
      DrawText(PChar(Format('ANIM 0: %s', [anim0.name])), 10, 10, 20, GRAY);
      DrawText(PChar(Format('ANIM 1: %s', [anim1.name])), 10, 40, 20, GRAY);

      if upperBodyBlend then
        DrawText('[SPACE] Toggle blending mode: Upper/Lower Body Blending', 10, GetScreenHeight() - 30, 20, DARKGRAY)
      else
        DrawText('[SPACE] Toggle blending mode: Uniform Blending', 10, GetScreenHeight() - 30, 20, DARKGRAY);

    EndDrawing();
  end;

  // De-Initialization
  UnloadModelAnimations(anims, animCount);
  UnloadModel(model);
  UnloadShader(skinningShader);

  CloseWindow();
end.
