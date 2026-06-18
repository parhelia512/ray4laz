program models_mesh_generation;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  NUM_MODELS = 9;

// Generate a simple triangle mesh from code
function GenMeshCustom: TMesh;
begin
  FillChar(Result, SizeOf(Result), 0);

  Result.triangleCount := 1;
  Result.vertexCount := Result.triangleCount * 3;

  // Allocate memory for vertex data
  Result.vertices := GetMem(Result.vertexCount * 3 * SizeOf(Single));
  Result.texcoords := GetMem(Result.vertexCount * 2 * SizeOf(Single));
  Result.normals := GetMem(Result.vertexCount * 3 * SizeOf(Single));

  // Vertex at (0, 0, 0)
  Result.vertices[0] := 0.0;
  Result.vertices[1] := 0.0;
  Result.vertices[2] := 0.0;
  Result.normals[0] := 0.0;
  Result.normals[1] := 1.0;
  Result.normals[2] := 0.0;
  Result.texcoords[0] := 0.0;
  Result.texcoords[1] := 0.0;

  // Vertex at (1, 0, 2)
  Result.vertices[3] := 1.0;
  Result.vertices[4] := 0.0;
  Result.vertices[5] := 2.0;
  Result.normals[3] := 0.0;
  Result.normals[4] := 1.0;
  Result.normals[5] := 0.0;
  Result.texcoords[2] := 0.5;
  Result.texcoords[3] := 1.0;

  // Vertex at (2, 0, 0)
  Result.vertices[6] := 2.0;
  Result.vertices[7] := 0.0;
  Result.vertices[8] := 0.0;
  Result.normals[6] := 0.0;
  Result.normals[7] := 1.0;
  Result.normals[8] := 0.0;
  Result.texcoords[4] := 1.0;
  Result.texcoords[5] := 0.0;

  // Upload mesh data from CPU (RAM) to GPU (VRAM) memory
  UploadMesh(@Result, False);

  Result := Result;
end;

var
  camera: TCamera3D;
  checked: TImage;
  texture: TTexture2D;
  models: array[0..NUM_MODELS - 1] of TModel;
  position: TVector3;
  currentModel: integer;
  i: integer;
  modelNames: array[0..NUM_MODELS - 1] of string;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - mesh generation');

  // Generate a checked image for texturing
  checked := GenImageChecked(2, 2, 1, 1, RED, GREEN);
  texture := LoadTextureFromImage(checked);
  UnloadImage(checked);

  // Generate all models
  models[0] := LoadModelFromMesh(GenMeshPlane(2, 2, 4, 3));
  models[1] := LoadModelFromMesh(GenMeshCube(2.0, 1.0, 2.0));
  models[2] := LoadModelFromMesh(GenMeshSphere(2, 32, 32));
  models[3] := LoadModelFromMesh(GenMeshHemiSphere(2, 16, 16));
  models[4] := LoadModelFromMesh(GenMeshCylinder(1, 2, 16));
  models[5] := LoadModelFromMesh(GenMeshTorus(0.25, 4.0, 16, 32));
  models[6] := LoadModelFromMesh(GenMeshKnot(1.0, 2.0, 16, 128));
  models[7] := LoadModelFromMesh(GenMeshPoly(5, 2.0));
  models[8] := LoadModelFromMesh(GenMeshCustom);

  // Set checked texture as default diffuse component for all models material
  for i := 0 to NUM_MODELS - 1 do
    models[i].materials[0].maps[MATERIAL_MAP_ALBEDO].texture := texture;

  // Define the camera
  camera.position := Vector3Create(5.0, 5.0, 5.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  position := Vector3Create(0.0, 0.0, 0.0);
  currentModel := 0;

  // Model names for display
  modelNames[0] := 'PLANE';
  modelNames[1] := 'CUBE';
  modelNames[2] := 'SPHERE';
  modelNames[3] := 'HEMISPHERE';
  modelNames[4] := 'CYLINDER';
  modelNames[5] := 'TORUS';
  modelNames[6] := 'KNOT';
  modelNames[7] := 'POLY';
  modelNames[8] := 'Custom (triangle)';

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    UpdateCamera(@camera, CAMERA_ORBITAL);

    // Cycle models on mouse click
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
      currentModel := (currentModel + 1) mod NUM_MODELS;
    end;

    // Cycle models on keyboard
    if IsKeyPressed(KEY_RIGHT) then
    begin
      currentModel := (currentModel + 1) mod NUM_MODELS;
    end
    else if IsKeyPressed(KEY_LEFT) then
    begin
      currentModel := (currentModel - 1 + NUM_MODELS) mod NUM_MODELS;
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(models[currentModel], position, 1.0, WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      // Info box
      DrawRectangle(30, 400, 310, 30, Fade(SKYBLUE, 0.5));
      DrawRectangleLines(30, 400, 310, 30, Fade(DARKBLUE, 0.5));
      DrawText('MOUSE LEFT BUTTON to CYCLE PROCEDURAL MODELS', 40, 410, 10, BLUE);

      // Model name
      if currentModel = 8 then
        DrawText(PChar(modelNames[currentModel]), 580, 10, 20, DARKBLUE)
      else
        DrawText(PChar(modelNames[currentModel]), 640, 10, 20, DARKBLUE);

    EndDrawing();
  end;

  // De-Initialization
  UnloadTexture(texture);
  for i := 0 to NUM_MODELS - 1 do
  UnloadModel(models[i]);



  CloseWindow();
end.
