program models_bone_socket;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  BONE_SOCKETS = 3;
  BONE_SOCKET_HAT = 0;
  BONE_SOCKET_HAND_R = 1;
  BONE_SOCKET_HAND_L = 2;

type
  PBoneInfoArray = ^TBoneInfoArray;
  TBoneInfoArray = array[0..255] of TBoneInfo;

  PTransformArray = ^TTransformArray;
  TTransformArray = array[0..255] of TTransform;

  PModelAnimPoseArray = ^TModelAnimPoseArray;
  TModelAnimPoseArray = array[0..255] of PTransformArray;

function GetBoneInfo(model: TModel; index: integer): PBoneInfo;
begin
  Result := @(PBoneInfoArray(model.skeleton.BoneInfo)^)[index];
end;

function GetBindPose(model: TModel; index: integer): TTransform;
begin
  Result := PTransformArray(model.skeleton.bindPose)^[index];
end;

function GetKeyframePose(anims: PModelAnimation; animIndex, keyframe, bone: integer): TTransform;
begin
  Result := PModelAnimPoseArray(anims[animIndex].keyframePoses)^[keyframe]^[bone];
end;

var
  camera: TCamera3D;
  characterModel: TModel;
  equipModels: array[0..BONE_SOCKETS-1] of TModel;
  showEquip: array[0..BONE_SOCKETS-1] of boolean;
  modelAnimations: PModelAnimation;
  animsCount: integer;
  animIndex: integer;
  animCurrentFrame: integer;
  boneSocketIndex: array[0..BONE_SOCKETS-1] of integer;
  position: TVector3;
  angle: integer;
  i, j: integer;
  anim: TModelAnimation;
  characterRotate: TQuaternion;
  transform: TTransform;
  inRotation: TQuaternion;
  outRotation: TQuaternion;
  rotate: TQuaternion;
  matrixTransform: TMatrix;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - bone socket');

  camera.position := Vector3Create(5.0, 5.0, 5.0);
  camera.target := Vector3Create(0.0, 2.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  characterModel := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'));
  equipModels[0] := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman_hat.glb'));
  equipModels[1] := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman_sword.glb'));
  equipModels[2] := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman_shield.glb'));

  showEquip[0] := true;
  showEquip[1] := true;
  showEquip[2] := true;

  animsCount := 0;
  animIndex := 0;
  animCurrentFrame := 0;
  modelAnimations := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'), @animsCount);

  boneSocketIndex[0] := -1;
  boneSocketIndex[1] := -1;
  boneSocketIndex[2] := -1;

  for i := 0 to characterModel.skeleton.boneCount - 1 do
  begin
    if TextIsEqual(GetBoneInfo(characterModel, i)^.name, 'socket_hat') then
    begin
      boneSocketIndex[BONE_SOCKET_HAT] := i;
      continue;
    end;
    if TextIsEqual(GetBoneInfo(characterModel, i)^.name, 'socket_hand_R') then
    begin
      boneSocketIndex[BONE_SOCKET_HAND_R] := i;
      continue;
    end;
    if TextIsEqual(GetBoneInfo(characterModel, i)^.name, 'socket_hand_L') then
    begin
      boneSocketIndex[BONE_SOCKET_HAND_L] := i;
      continue;
    end;
  end;

  position := Vector3Create(0.0, 0.0, 0.0);
  angle := 0;

  DisableCursor();

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_THIRD_PERSON);

    if IsKeyDown(KEY_F) then angle := (angle + 1) mod 360
    else if IsKeyDown(KEY_H) then angle := (360 + angle - 1) mod 360;

    if IsKeyPressed(KEY_T) then animIndex := (animIndex + 1) mod animsCount
    else if IsKeyPressed(KEY_G) then animIndex := (animIndex + animsCount - 1) mod animsCount;

    if IsKeyPressed(KEY_ONE) then showEquip[BONE_SOCKET_HAT] := not showEquip[BONE_SOCKET_HAT];
    if IsKeyPressed(KEY_TWO) then showEquip[BONE_SOCKET_HAND_R] := not showEquip[BONE_SOCKET_HAND_R];
    if IsKeyPressed(KEY_THREE) then showEquip[BONE_SOCKET_HAND_L] := not showEquip[BONE_SOCKET_HAND_L];

    anim := modelAnimations[animIndex];
    animCurrentFrame := (animCurrentFrame + 1) mod anim.keyframeCount;
    UpdateModelAnimation(characterModel, anim, animCurrentFrame);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        characterRotate := QuaternionFromAxisAngle(Vector3Create(0.0, 1.0, 0.0), angle * DEG2RAD);
        characterModel.transform := MatrixMultiply(QuaternionToMatrix(characterRotate),
          MatrixTranslate(position.x, position.y, position.z));
        UpdateModelAnimation(characterModel, anim, animCurrentFrame);
        DrawMesh(characterModel.meshes[0], characterModel.materials[1], characterModel.transform);

        for i := 0 to BONE_SOCKETS - 1 do
        begin
          if not showEquip[i] then continue;

          transform := GetKeyframePose(modelAnimations, animIndex, animCurrentFrame, boneSocketIndex[i]);
          inRotation := GetBindPose(characterModel, boneSocketIndex[i]).rotation;
          outRotation := transform.rotation;

          rotate := QuaternionMultiply(outRotation, QuaternionInvert(inRotation));
          matrixTransform := QuaternionToMatrix(rotate);
          matrixTransform := MatrixMultiply(matrixTransform,
            MatrixTranslate(transform.translation.x, transform.translation.y, transform.translation.z));
          matrixTransform := MatrixMultiply(matrixTransform, characterModel.transform);

          DrawMesh(equipModels[i].meshes[0], equipModels[i].materials[1], matrixTransform);
        end;

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText('Use the T/G to switch animation', 10, 10, 20, GRAY);
      DrawText('Use the F/H to rotate character left/right', 10, 35, 20, GRAY);
      DrawText('Use the 1,2,3 to toggle shown of hat, sword and shield', 10, 60, 20, GRAY);
    EndDrawing();
  end;

  UnloadModelAnimations(modelAnimations, animsCount);
  UnloadModel(characterModel);

  for i := 0 to BONE_SOCKETS - 1 do
    UnloadModel(equipModels[i]);

  CloseWindow();
end.
