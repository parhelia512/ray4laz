program models_first_person_maze;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  imMap: TImage;
  cubicmap: TTexture2D;
  mesh: TMesh;
  model: TModel;
  texture: TTexture2D;
  mapPixels: PColorB;
  mapPosition: TVector3;
  oldCamPos: TVector3;
  playerPos: TVector2;
  playerRadius: Single;
  playerCellX, playerCellY: Integer;
  x, y: Integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - first person maze');

  camera.position := Vector3Create(0.2, 0.4, 0.2);
  camera.target := Vector3Create(0.185, 0.4, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  imMap := LoadImage(PChar(GetApplicationDirectory + 'resources/cubicmap.png'));
  cubicmap := LoadTextureFromImage(imMap);
  mesh := GenMeshCubicmap(imMap, Vector3Create(1.0, 1.0, 1.0));
  model := LoadModelFromMesh(mesh);

  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/cubicmap_atlas.png'));
  model.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture := texture;

  mapPixels := LoadImageColors(imMap);
  UnloadImage(imMap);

  mapPosition := Vector3Create(-16.0, 0.0, -8.0);

  DisableCursor();

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    oldCamPos := camera.position;
    UpdateCamera(@camera, CAMERA_FIRST_PERSON);

    playerPos := Vector2Create(camera.position.x, camera.position.z);
    playerRadius := 0.1;

    playerCellX := Trunc(playerPos.x - mapPosition.x + 0.5);
    playerCellY := Trunc(playerPos.y - mapPosition.z + 0.5);

    if playerCellX < 0 then playerCellX := 0
    else if playerCellX >= cubicmap.width then playerCellX := cubicmap.width - 1;

    if playerCellY < 0 then playerCellY := 0
    else if playerCellY >= cubicmap.height then playerCellY := cubicmap.height - 1;

    for y := playerCellY - 1 to playerCellY + 1 do
    begin
      if (y >= 0) and (y < cubicmap.height) then
      begin
        for x := playerCellX - 1 to playerCellX + 1 do
        begin
          if ((x >= 0) and (x < cubicmap.width)) and
             (mapPixels[y * cubicmap.width + x].r = 255) and
             CheckCollisionCircleRec(playerPos, playerRadius,
               RectangleCreate(mapPosition.x - 0.5 + x * 1.0, mapPosition.z - 0.5 + y * 1.0, 1.0, 1.0)) then
          begin
            camera.position := oldCamPos;
          end;
        end;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, mapPosition, 1.0, WHITE);
      EndMode3D();

      DrawTextureEx(cubicmap, Vector2Create(GetScreenWidth() - cubicmap.width * 4.0 - 20, 20.0), 0.0, 4.0, WHITE);
      DrawRectangleLines(GetScreenWidth() - cubicmap.width * 4 - 20, 20, cubicmap.width * 4, cubicmap.height * 4, GREEN);

      DrawRectangle(GetScreenWidth() - cubicmap.width * 4 - 20 + playerCellX * 4, 20 + playerCellY * 4, 4, 4, RED);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadImageColors(mapPixels);
  UnloadTexture(cubicmap);
  UnloadTexture(texture);
  UnloadModel(model);

  CloseWindow();
end.
