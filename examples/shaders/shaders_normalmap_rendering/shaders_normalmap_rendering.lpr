program shaders_normalmap_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

var
  camera: TCamera;
  shader: TShader;
  plane: TModel;
  lightPosition: TVector3;
  lightPosLoc: integer;
  specularExponent: single;
  specularExponentLoc: integer;
  useNormalMap: integer;
  useNormalMapLoc: integer;
  direction: TVector3;
  lightPos, camPos: array[0..2] of single;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - normalmap rendering');

  camera := Default(TCamera);
  camera.position := Vector3Create(0.0, 2.0, -4.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  shader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/normalmap.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/normalmap.fs', GLSL_VERSION)));

  shader.locs[Ord(SHADER_LOC_MAP_NORMAL)] := GetShaderLocation(shader, 'normalMap');
  shader.locs[Ord(SHADER_LOC_VECTOR_VIEW)] := GetShaderLocation(shader, 'viewPos');

  lightPosition := Vector3Create(0.0, 1.0, 0.0);
  lightPosLoc := GetShaderLocation(shader, 'lightPos');

  plane := LoadModel(PChar(GetApplicationDirectory + 'resources/models/plane.glb'));
  plane.materials[0].shader := shader;
  plane.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/tiles_diffuse.png'));
  plane.materials[0].maps[Ord(MATERIAL_MAP_NORMAL)].texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/tiles_normal.png'));

  GenTextureMipmaps(@plane.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture);
  GenTextureMipmaps(@plane.materials[0].maps[Ord(MATERIAL_MAP_NORMAL)].texture);
  SetTextureFilter(plane.materials[0].maps[Ord(MATERIAL_MAP_DIFFUSE)].texture, TEXTURE_FILTER_TRILINEAR);
  SetTextureFilter(plane.materials[0].maps[Ord(MATERIAL_MAP_NORMAL)].texture, TEXTURE_FILTER_TRILINEAR);

  specularExponent := 8.0;
  specularExponentLoc := GetShaderLocation(shader, 'specularExponent');
  useNormalMap := 1;
  useNormalMapLoc := GetShaderLocation(shader, 'useNormalMap');

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    direction := Vector3Create(0, 0, 0);
    if IsKeyDown(KEY_W) then direction := Vector3Add(direction, Vector3Create(0.0, 0.0, 1.0));
    if IsKeyDown(KEY_S) then direction := Vector3Add(direction, Vector3Create(0.0, 0.0, -1.0));
    if IsKeyDown(KEY_D) then direction := Vector3Add(direction, Vector3Create(-1.0, 0.0, 0.0));
    if IsKeyDown(KEY_A) then direction := Vector3Add(direction, Vector3Create(1.0, 0.0, 0.0));

    direction := Vector3Normalize(direction);
    lightPosition := Vector3Add(lightPosition, Vector3Scale(direction, GetFrameTime() * 3.0));

    if IsKeyDown(KEY_UP) then specularExponent := Clamp(specularExponent + 40.0 * GetFrameTime(), 2.0, 128.0);
    if IsKeyDown(KEY_DOWN) then specularExponent := Clamp(specularExponent - 40.0 * GetFrameTime(), 2.0, 128.0);

    if IsKeyPressed(KEY_N) then
    begin
      if useNormalMap = 1 then useNormalMap := 0
      else useNormalMap := 1;
    end;

    plane.transform := MatrixRotateY(GetTime() * 0.5);

    lightPos[0] := lightPosition.x;
    lightPos[1] := lightPosition.y;
    lightPos[2] := lightPosition.z;
    SetShaderValue(shader, lightPosLoc, @lightPos, SHADER_UNIFORM_VEC3);

    camPos[0] := camera.position.x;
    camPos[1] := camera.position.y;
    camPos[2] := camera.position.z;
    SetShaderValue(shader, shader.locs[Ord(SHADER_LOC_VECTOR_VIEW)], @camPos, SHADER_UNIFORM_VEC3);

    SetShaderValue(shader, specularExponentLoc, @specularExponent, SHADER_UNIFORM_FLOAT);
    SetShaderValue(shader, useNormalMapLoc, @useNormalMap, SHADER_UNIFORM_INT);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        BeginShaderMode(shader);
          DrawModel(plane, Vector3Zero(), 2.0, WHITE);
        EndShaderMode();
        DrawSphereWires(lightPosition, 0.2, 8, 8, ORANGE);
      EndMode3D();

      if useNormalMap = 1 then
        DrawText('Use key [N] to toggle normal map: On', 10, 10, 10, DARKGREEN)
      else
        DrawText('Use key [N] to toggle normal map: Off', 10, 10, 10, RED);

      DrawText('Use keys [W][A][S][D] to move the light', 10, 34, 10, BLACK);
      DrawText('Use keys [Up][Down] to change specular exponent', 10, 58, 10, BLACK);
      DrawText(PChar(Format('Specular Exponent: %.2f', [specularExponent])), 10, 82, 10, BLUE);

      DrawFPS(screenWidth - 90, 10);
    EndDrawing();
  end;

  UnloadShader(shader);
  UnloadModel(plane);
  CloseWindow();
end.
