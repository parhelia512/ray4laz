program shaders_cel_shading;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath, rlgl, rlights;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

var
  camera: TCamera;
  model: TModel;
  celShader, defaultShader, outlineShader: TShader;
  numBands: single;
  numBandsLoc, outlineThicknessLoc: integer;
  lights: array[0..MAX_LIGHTS] of TLight;
  celEnabled, outlineEnabled: boolean;
  t: single;
  thickness: single;
  cameraPos: array[0..2] of single;
  i: integer;
begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - cel shading');

  camera := Default(TCamera);
  camera.position := Vector3Create(9.0, 6.0, 9.0);
  camera.target := Vector3Create(0.0, 1.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/old_car_new.glb'));

  celShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/cel.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/cel.fs', GLSL_VERSION)));
  celShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)] := GetShaderLocation(celShader, 'viewPos');

  defaultShader := model.materials[0].shader;
  model.materials[0].shader := celShader;

  numBands := 10.0;
  numBandsLoc := GetShaderLocation(celShader, 'numBands');
  SetShaderValue(celShader, numBandsLoc, @numBands, SHADER_UNIFORM_FLOAT);

  outlineShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/outline_hull.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/outline_hull.fs', GLSL_VERSION)));
  outlineThicknessLoc := GetShaderLocation(outlineShader, 'outlineThickness');

  lights[0] := CreateLight(LIGHT_DIRECTIONAL, Vector3Create(50.0, 50.0, 50.0), Vector3Zero(), WHITE, celShader);

  celEnabled := True;
  outlineEnabled := True;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    cameraPos[0] := camera.position.x;
    cameraPos[1] := camera.position.y;
    cameraPos[2] := camera.position.z;
    SetShaderValue(celShader, celShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)], @cameraPos, SHADER_UNIFORM_VEC3);

    if IsKeyPressed(KEY_Z) then
    begin
      celEnabled := not celEnabled;
      if celEnabled then model.materials[0].shader := celShader
      else model.materials[0].shader := defaultShader;
    end;

    if IsKeyPressed(KEY_C) then outlineEnabled := not outlineEnabled;

    if IsKeyPressed(KEY_E) or IsKeyPressedRepeat(KEY_E) then numBands := Clamp(numBands + 1.0, 2.0, 20.0);
    if IsKeyPressed(KEY_Q) or IsKeyPressedRepeat(KEY_Q) then numBands := Clamp(numBands - 1.0, 2.0, 20.0);
    SetShaderValue(celShader, numBandsLoc, @numBands, SHADER_UNIFORM_FLOAT);

    t := GetTime();
    lights[0].position := Vector3Create(Sin(-t * 0.3) * 5.0, 5.0, Cos(-t * 0.3) * 5.0);

    for  i := 0 to MAX_LIGHTS - 1 do
      UpdateLightValues(celShader, lights[i]);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        if outlineEnabled then
        begin
          thickness := 0.005;
          SetShaderValue(outlineShader, outlineThicknessLoc, @thickness, SHADER_UNIFORM_FLOAT);
          rlSetCullFace(RL_CULL_FACE_FRONT);
          model.materials[0].shader := outlineShader;
          DrawModel(model, Vector3Zero(), 0.75, WHITE);
          if celEnabled then model.materials[0].shader := celShader
          else model.materials[0].shader := defaultShader;
          rlSetCullFace(RL_CULL_FACE_BACK);
        end;

        DrawModel(model, Vector3Zero(), 0.75, WHITE);
        DrawSphereEx(lights[0].position, 0.2, 50, 50, YELLOW);
        DrawGrid(10, 10.0);
      EndMode3D();

      DrawFPS(10, 10);
      if celEnabled then
        DrawText('Cel: ON  [Z]', 10, 65, 20, DARKGREEN)
      else
        DrawText('Cel: OFF  [Z]', 10, 65, 20, DARKGRAY);
      if outlineEnabled then
        DrawText('Outline: ON  [C]', 10, 90, 20, DARKGREEN)
      else
        DrawText('Outline: OFF  [C]', 10, 90, 20, DARKGRAY);
      DrawText(PChar(Format('Bands: %.0f  [Q/E]', [numBands])), 10, 115, 20, DARKGRAY);
    EndDrawing();
  end;

  UnloadModel(model);
  UnloadShader(celShader);
  UnloadShader(outlineShader);
  CloseWindow();
end.
