program models_loading_iqm;

{$mode objfpc}{$H+}

uses cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  texture: TTexture2D;
  position: TVector3;
  animCount: Integer;
  anims: PModelAnimation;
  animIndex: Integer;
  animCurrentFrame: Single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - loading iqm');

  camera.position := Vector3Create(10.0, 10.0, 10.0);
  camera.target := Vector3Create(0.0, 4.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/iqm/guy.iqm'));
  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/models/iqm/guytex.png'));
  SetMaterialTexture(@model.materials[0], MATERIAL_MAP_DIFFUSE, texture);
  position := Vector3Create(0.0, 0.0, 0.0);

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/iqm/guyanim.iqm'), @animCount);

  animIndex := 0;
  animCurrentFrame := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    animCurrentFrame := animCurrentFrame + 1.0;
    UpdateModelAnimation(model, anims[animIndex], Trunc(animCurrentFrame));
    if animCurrentFrame >= anims[animIndex].keyframeCount then
      animCurrentFrame := 0;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModelEx(model, position, Vector3Create(1.0, 0.0, 0.0), -90.0, Vector3Create(1.0, 1.0, 1.0), WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText(PChar(Format('Current animation: %s', [anims[animIndex].name])), 10, 10, 20, MAROON);
      DrawText('(c) Guy IQM 3D model by @culacant', screenWidth - 200, screenHeight - 20, 10, GRAY);

    EndDrawing();
  end;

  UnloadTexture(texture);
  UnloadModelAnimations(anims, animCount);
  UnloadModel(model);

  CloseWindow();
end.
