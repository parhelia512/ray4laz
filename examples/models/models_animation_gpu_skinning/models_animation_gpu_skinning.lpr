program models_animation_gpu_skinning;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  position: TVector3;
  anims: PModelAnimation;
  animCount: integer;
  animIndex: integer;
  animCurrentFrame: integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - animation gpu skinning');

  camera.position := Vector3Create(5.0, 5.0, 5.0);
  camera.target := Vector3Create(0.0, 1.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'));
  position := Vector3Create(0.0, 0.0, 0.0);

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/gltf/greenman.glb'), @animCount);

  animIndex := 0;
  animCurrentFrame := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    if IsKeyPressed(KEY_RIGHT) then animIndex := (animIndex + 1) mod animCount
    else if IsKeyPressed(KEY_LEFT) then animIndex := (animIndex + animCount - 1) mod animCount;

    animCurrentFrame := (animCurrentFrame + 1) mod anims[animIndex].keyframeCount;
    UpdateModelAnimation(model, anims[animIndex], animCurrentFrame);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, position, 1.0, WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText(PChar(Format('Current animation: %s', [anims[animIndex].name])), 10, 40, 20, MAROON);
      DrawText('Use the LEFT/RIGHT keys to switch animation', 10, 10, 20, GRAY);
    EndDrawing();
  end;

  UnloadModelAnimations(anims, animCount);
  UnloadModel(model);
  CloseWindow();
end.
