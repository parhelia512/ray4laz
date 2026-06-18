program models_rotating_cube;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  img, crop: TImage;
  texture: TTexture2D;
  rotation: single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - rotating cube');

  camera.position := Vector3Create(0.0, 3.0, 3.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModelFromMesh(GenMeshCube(1.0, 1.0, 1.0));
  img := LoadImage(PChar(GetApplicationDirectory + 'resources/cubicmap_atlas.png'));
  crop := ImageFromImage(img, RectangleCreate(0, img.height / 2.0, img.width / 2.0, img.height / 2.0));
  texture := LoadTextureFromImage(crop);
  UnloadImage(img);
  UnloadImage(crop);

  model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture := texture;

  rotation := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    rotation += 1.0;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModelEx(model, Vector3Create(0.0, 0.0, 0.0), Vector3Create(0.5, 1.0, 0.0),
          rotation, Vector3Create(1.0, 1.0, 1.0), WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadTexture(texture);
  UnloadModel(model);
  CloseWindow();
end.
