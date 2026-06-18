program shaders_lightmap_rendering;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, raymath, rlgl;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  MAP_SIZE = 16;

var
  camera: TCamera;
  mesh: TMesh;
  shader: TShader;
  texture, light: TTexture2D;
  lightmap: TRenderTexture2D;
  material: TMaterial;
  i: integer;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - lightmap rendering');

  camera := Default(TCamera);
  camera.position := Vector3Create(4.0, 6.0, 8.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  mesh := GenMeshPlane(MAP_SIZE, MAP_SIZE, 1, 1);

  // GenMeshPlane doesn't generate texcoords2 so we will upload them separately
  mesh.texcoords2 := MemAlloc(mesh.vertexCount * 2 * SizeOf(single));
  if mesh.texcoords2 = nil then
  begin
    WriteLn('Error: Failed to allocate texcoords2 memory');
    Halt(1);
  end;

  // X                          // Y
  mesh.texcoords2[0] := 0.0;    mesh.texcoords2[1] := 0.0;
  mesh.texcoords2[2] := 1.0;    mesh.texcoords2[3] := 0.0;
  mesh.texcoords2[4] := 0.0;    mesh.texcoords2[5] := 1.0;
  mesh.texcoords2[6] := 1.0;    mesh.texcoords2[7] := 1.0;

  // Load a new texcoords2 attributes buffer
  mesh.vboId[SHADER_LOC_VERTEX_TEXCOORD02] := rlLoadVertexBuffer(mesh.texcoords2, mesh.vertexCount * 2 * SizeOf(single), False);
  rlEnableVertexArray(mesh.vaoId);
  // Index 5 is for texcoords2
  rlSetVertexAttribute(5, 2, RL_FLOAT, False, 0, 0);
  rlEnableVertexAttribute(5);
  rlDisableVertexArray();

  // Load lightmap shader
  shader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/lightmap.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/lightmap.fs', GLSL_VERSION)));

  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/cubicmap_atlas.png'));
  light := LoadTexture(PChar(GetApplicationDirectory + 'resources/spark_flame.png'));

  GenTextureMipmaps(@texture);
  SetTextureFilter(texture, TEXTURE_FILTER_TRILINEAR);

  lightmap := LoadRenderTexture(MAP_SIZE, MAP_SIZE);

  material := LoadMaterialDefault();
  material.shader := shader;
  material.maps[MATERIAL_MAP_ALBEDO].texture := texture;
  material.maps[MATERIAL_MAP_METALNESS].texture := lightmap.texture;

  // Drawing to lightmap
  BeginTextureMode(lightmap);
    ClearBackground(BLACK);

    BeginBlendMode(BLEND_ADDITIVE);
      DrawTexturePro(light,
        RectangleCreate(0, 0, light.width, light.height),
        RectangleCreate(0, 0, 2.0 * MAP_SIZE, 2.0 * MAP_SIZE),
        Vector2Create(MAP_SIZE, MAP_SIZE), 0.0, RED);
      DrawTexturePro(light,
        RectangleCreate(0, 0, light.width, light.height),
        RectangleCreate(MAP_SIZE * 0.8, MAP_SIZE / 2.0, 2.0 * MAP_SIZE, 2.0 * MAP_SIZE),
        Vector2Create(MAP_SIZE, MAP_SIZE), 0.0, BLUE);
      DrawTexturePro(light,
        RectangleCreate(0, 0, light.width, light.height),
        RectangleCreate(MAP_SIZE * 0.8, MAP_SIZE * 0.8, MAP_SIZE, MAP_SIZE),
        Vector2Create(MAP_SIZE / 2.0, MAP_SIZE / 2.0), 0.0, GREEN);
    EndBlendMode();
  EndTextureMode();

  // NOTE: To enable trilinear filtering we need mipmaps available for texture
  GenTextureMipmaps(@lightmap.texture);
  SetTextureFilter(lightmap.texture, TEXTURE_FILTER_TRILINEAR);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    UpdateCamera(@camera, CAMERA_ORBITAL);

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawMesh(mesh, material, MatrixIdentity());
      EndMode3D();

      DrawTexturePro(lightmap.texture,
        RectangleCreate(0, 0, -MAP_SIZE, -MAP_SIZE),
        RectangleCreate(GetRenderWidth() - MAP_SIZE * 8 - 10, 10, MAP_SIZE * 8, MAP_SIZE * 8),
        Vector2Create(0.0, 0.0), 0.0, WHITE);

      DrawText(PChar(Format('LIGHTMAP: %ix%i pixels', [MAP_SIZE, MAP_SIZE])),
        GetRenderWidth() - 130, 20 + MAP_SIZE * 8, 10, GREEN);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  // De-Initialization
  UnloadMesh(mesh);
  UnloadShader(shader);
  UnloadTexture(texture);
  UnloadTexture(light);
  UnloadRenderTexture(lightmap);
  CloseWindow();
end.
