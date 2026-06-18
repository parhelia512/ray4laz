program models_cubicmap_rendering;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  image: TImage;
  cubicmap: TTexture2D;
  mesh: TMesh;
  model: TModel;
  texture: TTexture2D;
  mapPosition: TVector3;
  pause: boolean;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - cubicmap rendering');

  camera.position := Vector3Create(16.0, 14.0, 16.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  image := LoadImage(PChar(GetApplicationDirectory + 'resources/cubicmap.png'));
  cubicmap := LoadTextureFromImage(image);

  mesh := GenMeshCubicmap(image, Vector3Create(1.0, 1.0, 1.0));
  model := LoadModelFromMesh(mesh);

  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/cubicmap_atlas.png'));
  model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture := texture;

  mapPosition := Vector3Create(-16.0, 0.0, -8.0);

  UnloadImage(image);

  pause := false;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_P) then pause := not pause;

    if not pause then UpdateCamera(@camera, CAMERA_ORBITAL);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, mapPosition, 1.0, WHITE);
      EndMode3D();

      DrawTextureEx(cubicmap, Vector2Create(screenWidth - cubicmap.width*4.0 - 20, 20.0), 0.0, 4.0, WHITE);
      DrawRectangleLines(screenWidth - cubicmap.width*4 - 20, 20, cubicmap.width*4, cubicmap.height*4, GREEN);

      DrawText('cubicmap image used to', 658, 90, 10, GRAY);
      DrawText('generate map 3d model', 658, 104, 10, GRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadTexture(cubicmap);
  UnloadTexture(texture);
  UnloadModel(model);
  CloseWindow();
end.
