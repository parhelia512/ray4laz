program models_loading;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  texture: TTexture2D;
  position: TVector3;
  bounds: TBoundingBox;
  selected: Boolean;
  droppedFiles: TFilePathList;
  fp: PAnsiChar;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - loading');

  camera.position := Vector3Create(50.0, 50.0, 50.0);
  camera.target := Vector3Create(0.0, 12.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/obj/castle.obj'));
  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/models/obj/castle_diffuse.png'));
  model.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture := texture;

  position := Vector3Create(0.0, 0.0, 0.0);
  bounds := GetMeshBoundingBox(model.meshes[0]);
  selected := False;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    if IsFileDropped() then
    begin
      droppedFiles := LoadDroppedFiles();

      if droppedFiles.count = 1 then
      begin
        fp := droppedFiles.paths[0];

        if IsFileExtension(fp, '.obj') or
           IsFileExtension(fp, '.gltf') or
           IsFileExtension(fp, '.glb') or
           IsFileExtension(fp, '.vox') or
           IsFileExtension(fp, '.iqm') or
           IsFileExtension(fp, '.m3d') then
        begin
          UnloadModel(model);
          model := LoadModel(fp);
          model.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture := texture;
          bounds := GetMeshBoundingBox(model.meshes[0]);

          camera.position.x := bounds.max.x + 10.0;
          camera.position.y := bounds.max.y + 10.0;
          camera.position.z := bounds.max.z + 10.0;
        end
        else if IsFileExtension(fp, '.png') then
        begin
          UnloadTexture(texture);
          texture := LoadTexture(fp);
          model.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture := texture;
        end;
      end;

      UnloadDroppedFiles(droppedFiles);
    end;

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
      if GetRayCollisionBox(GetScreenToWorldRay(GetMousePosition(), camera), bounds).hit then
        selected := not selected
      else
        selected := False;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, position, 1.0, WHITE);
        DrawGrid(20, 10.0);
        if selected then DrawBoundingBox(bounds, GREEN);
      EndMode3D();

      DrawText('Drag & drop model to load mesh/texture.', 10, GetScreenHeight() - 20, 10, DARKGRAY);
      if selected then DrawText('MODEL SELECTED', GetScreenWidth() - 110, 10, 10, GREEN);

      DrawText('(c) Castle 3D model by Alberto Cano', screenWidth - 200, screenHeight - 20, 10, GRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadTexture(texture);
  UnloadModel(model);

  CloseWindow();
end.
