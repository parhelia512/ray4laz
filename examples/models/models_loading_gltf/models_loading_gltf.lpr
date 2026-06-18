program models_loading_gltf;

{$mode objfpc}{$H+}

uses cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  position: TVector3;
  anims: PModelAnimation;
  animCount: integer;
  animIndex: cardinal;
  animCurrentFrame: cardinal;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - loading gltf');

  camera.position := Vector3Create(6.0, 6.0, 6.0);
  camera.target := Vector3Create(0.0, 2.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/robot.glb'));
  position := Vector3Create(0.0, 0.0, 0.0);

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/gltf/robot.glb'), @animCount);

  animIndex := 0;
  animCurrentFrame := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    if IsKeyPressed(KEY_RIGHT) then
    begin
      animIndex := (animIndex + 1) mod cardinal(animCount);
    end
    else if IsKeyPressed(KEY_LEFT) then
    begin
      animIndex := (animIndex + cardinal(animCount) - 1) mod cardinal(animCount);
    end;

    animCurrentFrame := (animCurrentFrame + 1) mod cardinal(anims[animIndex].keyframeCount);
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
