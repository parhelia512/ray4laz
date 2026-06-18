program models_loading_m3d;

{$mode objfpc}{$H+}

uses cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

procedure DrawModelSkeleton(skeleton: TModelSkeleton; pose: TModelAnimPose; scale: Single; color: TColorB);
var
  i: Integer;
  boneData: PBoneInfo;
  poseArr: PTransform;
begin
  boneData := skeleton.BoneInfo;
  poseArr := pose;

  for i := 0 to skeleton.boneCount - 2 do
  begin
    DrawCube(poseArr[i].translation, scale * 0.05, scale * 0.05, scale * 0.05, color);
    if boneData[i].parent >= 0 then
      DrawLine3D(poseArr[i].translation, poseArr[boneData[i].parent].translation, color);
  end;
end;

var
  camera: TCamera3D;
  model: TModel;
  position: TVector3;
  animCount: Integer;
  anims: PModelAnimation;
  animIndex: Integer;
  animCurrentFrame: Single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - loading m3d');

  camera.position := Vector3Create(1.5, 1.5, 1.5);
  camera.target := Vector3Create(0.0, 0.4, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/m3d/cesium_man.m3d'));
  position := Vector3Create(0.0, 0.0, 0.0);

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/m3d/cesium_man.m3d'), @animCount);

  animIndex := 0;
  animCurrentFrame := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    if IsKeyPressed(KEY_RIGHT) then
      animIndex := (animIndex + 1) mod animCount
    else if IsKeyPressed(KEY_LEFT) then
      animIndex := (animIndex + animCount - 1) mod animCount;

    animCurrentFrame := animCurrentFrame + 1.0;
    if animCurrentFrame >= anims[animIndex].keyframeCount then
      animCurrentFrame := 0.0;
    UpdateModelAnimation(model, anims[animIndex], Trunc(animCurrentFrame));

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        if not IsKeyDown(KEY_SPACE) then
          DrawModel(model, position, 1.0, WHITE)
        else
          DrawModelSkeleton(model.skeleton, anims[animIndex].keyframePoses[Trunc(animCurrentFrame)], 1.0, RED);

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText(PChar(Format('Current animation: %s', [anims[animIndex].name])), 10, 10, 20, LIGHTGRAY);
      DrawText('Press SPACE to draw skeleton', 10, 40, 20, MAROON);
      DrawText('(c) CesiumMan model by KhronosGroup', GetScreenWidth() - 210, GetScreenHeight() - 20, 10, GRAY);

    EndDrawing();
  end;

  UnloadModelAnimations(anims, animCount);
  UnloadModel(model);

  CloseWindow();
end.
