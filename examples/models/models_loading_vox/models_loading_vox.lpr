program models_loading_vox;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath, rlights, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_VOX_FILES = 4;
  GLSL_VERSION = 330;

var
  camera: TCamera3D;
  models: array[0..MAX_VOX_FILES - 1] of TModel;
  i, j: Integer;
  t0, t1: Double;
  bb: TBoundingBox;
  center: TVector3;
  matTranslate: TMatrix;
  currentModel: Integer;
  modelpos, camerarot: TVector3;
  shader: TShader;
  ambientLoc: Integer;
  ambientVal: array[0..3] of Single;
  lights: array[0..MAX_LIGHTS - 1] of TLight;
  cameraPos: array[0..2] of Single;
  mouseDelta: TVector2;
  fileName: PAnsiChar;
  voxFileNames: array[0..MAX_VOX_FILES - 1] of PAnsiChar;
begin
  voxFileNames[0] := 'resources/models/vox/chr_knight.vox';
  voxFileNames[1] := 'resources/models/vox/chr_sword.vox';
  voxFileNames[2] := 'resources/models/vox/monu9.vox';
  voxFileNames[3] := 'resources/models/vox/fez.vox';

  InitWindow(screenWidth, screenHeight, 'raylib [models] example - loading vox');

  camera.position := Vector3Create(10.0, 10.0, 10.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  for i := 0 to MAX_VOX_FILES - 1 do
  begin
    t0 := GetTime() * 1000.0;
    models[i] := LoadModel(PChar(string(GetApplicationDirectory) + string(voxFileNames[i])));
    t1 := GetTime() * 1000.0;

    TraceLog(LOG_INFO, PChar(Format('[%s] Model file loaded in %.3f ms', [voxFileNames[i], t1 - t0])));

    bb := GetModelBoundingBox(models[i]);
    center := Vector3Create(0, 0, 0);
    center.x := bb.min.x + ((bb.max.x - bb.min.x) / 2);
    center.z := bb.min.z + ((bb.max.z - bb.min.z) / 2);

    matTranslate := MatrixTranslate(-center.x, 0, -center.z);
    models[i].transform := matTranslate;
  end;

  currentModel := 0;
  modelpos := Vector3Create(0, 0, 0);
  camerarot := Vector3Create(0, 0, 0);

  shader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/voxel_lighting.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/voxel_lighting.fs', GLSL_VERSION)));

  shader.locs[SHADER_LOC_VECTOR_VIEW] := GetShaderLocation(shader, 'viewPos');

  ambientLoc := GetShaderLocation(shader, 'ambient');
  ambientVal[0] := 0.1; ambientVal[1] := 0.1; ambientVal[2] := 0.1; ambientVal[3] := 1.0;
  SetShaderValue(shader, ambientLoc, @ambientVal, SHADER_UNIFORM_VEC4);

  for i := 0 to MAX_VOX_FILES - 1 do
    for j := 0 to models[i].materialCount - 1 do
      models[i].materials[j].shader := shader;

  lights[0] := CreateLight(LIGHT_POINT, Vector3Create(-20, 20, -20), Vector3Zero(), GRAY, shader);
  lights[1] := CreateLight(LIGHT_POINT, Vector3Create(20, -20, 20), Vector3Zero(), GRAY, shader);
  lights[2] := CreateLight(LIGHT_POINT, Vector3Create(-20, 20, 20), Vector3Zero(), GRAY, shader);
  lights[3] := CreateLight(LIGHT_POINT, Vector3Create(20, -20, -20), Vector3Zero(), GRAY, shader);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsMouseButtonDown(MOUSE_BUTTON_MIDDLE) then
    begin
      mouseDelta := GetMouseDelta();
      camerarot.x := mouseDelta.x * 0.05;
      camerarot.y := mouseDelta.y * 0.05;
    end
    else
    begin
      camerarot.x := 0;
      camerarot.y := 0;
    end;

    UpdateCameraPro(@camera,
      Vector3Create(
        (Ord(IsKeyDown(KEY_W)) + Ord(IsKeyDown(KEY_UP))) * 0.1 - (Ord(IsKeyDown(KEY_S)) + Ord(IsKeyDown(KEY_DOWN))) * 0.1,
        (Ord(IsKeyDown(KEY_D)) + Ord(IsKeyDown(KEY_RIGHT))) * 0.1 - (Ord(IsKeyDown(KEY_A)) + Ord(IsKeyDown(KEY_LEFT))) * 0.1,
        0.0),
      camerarot,
      GetMouseWheelMove() * -2.0);

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
      currentModel := (currentModel + 1) mod MAX_VOX_FILES;

    cameraPos[0] := camera.position.x;
    cameraPos[1] := camera.position.y;
    cameraPos[2] := camera.position.z;
    SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], @cameraPos, SHADER_UNIFORM_VEC3);

    for i := 0 to MAX_LIGHTS - 1 do
      UpdateLightValues(shader, lights[i]);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(models[currentModel], modelpos, 1.0, WHITE);
        DrawGrid(10, 1.0);

        for i := 0 to MAX_LIGHTS - 1 do
        begin
          if lights[i].enabled then
            DrawSphereEx(lights[i].position, 0.2, 8, 8, lights[i].color)
          else
            DrawSphereWires(lights[i].position, 0.2, 8, 8, ColorAlpha(lights[i].color, 0.3));
        end;
      EndMode3D();

      DrawRectangle(10, 40, 340, 70, Fade(SKYBLUE, 0.5));
      DrawRectangleLines(10, 40, 340, 70, Fade(DARKBLUE, 0.5));
      DrawText('- MOUSE LEFT BUTTON: CYCLE VOX MODELS', 20, 50, 10, BLUE);
      DrawText('- MOUSE MIDDLE BUTTON: ZOOM OR ROTATE CAMERA', 20, 70, 10, BLUE);
      DrawText('- UP-DOWN-LEFT-RIGHT KEYS: MOVE CAMERA', 20, 90, 10, BLUE);

      fileName := GetFileName(voxFileNames[currentModel]);
      DrawText(PChar(Format('VOX model file: %s', [fileName])), 10, 10, 20, GRAY);

    EndDrawing();
  end;

  for i := 0 to MAX_VOX_FILES - 1 do
    UnloadModel(models[i]);

  CloseWindow();
end.
