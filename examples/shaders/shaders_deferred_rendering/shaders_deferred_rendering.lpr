program shaders_deferred_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, rlgl, raymath, rlights;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  MAX_CUBES = 30;

type
  TGBuffer = record
    framebufferId: cardinal;
    positionTextureId: cardinal;
    normalTextureId: cardinal;
    albedoSpecTextureId: cardinal;
    depthRenderbufferId: cardinal;
  end;

  TDeferredMode = (DEFERRED_POSITION, DEFERRED_NORMAL, DEFERRED_ALBEDO, DEFERRED_SHADING);

var
  camera: TCamera;
  model, cube: TModel;
  gbufferShader, deferredShader: TShader;
  gBuffer: TGBuffer;
  lights: array[0..MAX_LIGHTS - 1] of TLight;
  cubePositions: array[0..MAX_CUBES - 1] of TVector3;
  cubeRotations: array[0..MAX_CUBES - 1] of single;
  i: integer;
  mode: TDeferredMode;
  texUnitPosition, texUnitNormal, texUnitAlbedoSpec: integer;
  cameraPos: array[0..2] of single;
  lightView, lightProj, lightViewProj: TMatrix;
  textureActiveSlot: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - deferred rendering');

  camera := Default(TCamera);
  camera.position := Vector3Create(5.0, 4.0, 5.0);
  camera.target := Vector3Create(0.0, 1.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 60.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModelFromMesh(GenMeshPlane(10.0, 10.0, 3, 3));
  cube := LoadModelFromMesh(GenMeshCube(2.0, 2.0, 2.0));

  gbufferShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/gbuffer.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/gbuffer.fs', GLSL_VERSION)));

  deferredShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/deferred_shading.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/deferred_shading.fs', GLSL_VERSION)));
  deferredShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)] := GetShaderLocation(deferredShader, 'viewPosition');

  gBuffer := Default(TGBuffer);
  gBuffer.framebufferId := rlLoadFramebuffer();
  if gBuffer.framebufferId = 0 then TraceLog(LOG_WARNING, 'Failed to create framebufferId');

  rlEnableFramebuffer(gBuffer.framebufferId);

  gBuffer.positionTextureId := rlLoadTexture(nil, screenWidth, screenHeight, RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16, 1);
  gBuffer.normalTextureId := rlLoadTexture(nil, screenWidth, screenHeight, RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16, 1);
  gBuffer.albedoSpecTextureId := rlLoadTexture(nil, screenWidth, screenHeight, RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 1);

  rlActiveDrawBuffers(3);

  rlFramebufferAttach(gBuffer.framebufferId, gBuffer.positionTextureId, RL_ATTACHMENT_COLOR_CHANNEL0, RL_ATTACHMENT_TEXTURE2D, 0);
  rlFramebufferAttach(gBuffer.framebufferId, gBuffer.normalTextureId, RL_ATTACHMENT_COLOR_CHANNEL1, RL_ATTACHMENT_TEXTURE2D, 0);
  rlFramebufferAttach(gBuffer.framebufferId, gBuffer.albedoSpecTextureId, RL_ATTACHMENT_COLOR_CHANNEL2, RL_ATTACHMENT_TEXTURE2D, 0);

  gBuffer.depthRenderbufferId := rlLoadTextureDepth(screenWidth, screenHeight, True);
  rlFramebufferAttach(gBuffer.framebufferId, gBuffer.depthRenderbufferId, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_RENDERBUFFER, 0);

  if not rlFramebufferComplete(gBuffer.framebufferId) then TraceLog(LOG_WARNING, 'Framebuffer is not complete');

  rlEnableShader(deferredShader.id);
  texUnitPosition := 0;
  texUnitNormal := 1;
  texUnitAlbedoSpec := 2;
  SetShaderValue(deferredShader, rlGetLocationUniform(deferredShader.id, 'gPosition'), @texUnitPosition, RL_SHADER_UNIFORM_SAMPLER2D);
  SetShaderValue(deferredShader, rlGetLocationUniform(deferredShader.id, 'gNormal'), @texUnitNormal, RL_SHADER_UNIFORM_SAMPLER2D);
  SetShaderValue(deferredShader, rlGetLocationUniform(deferredShader.id, 'gAlbedoSpec'), @texUnitAlbedoSpec, RL_SHADER_UNIFORM_SAMPLER2D);
  rlDisableShader();

  model.materials[0].shader := gbufferShader;
  cube.materials[0].shader := gbufferShader;

  lights[0] := CreateLight(LIGHT_POINT, Vector3Create(-2, 1, -2), Vector3Zero(), YELLOW, deferredShader);
  lights[1] := CreateLight(LIGHT_POINT, Vector3Create(2, 1, 2), Vector3Zero(), RED, deferredShader);
  lights[2] := CreateLight(LIGHT_POINT, Vector3Create(-2, 1, 2), Vector3Zero(), GREEN, deferredShader);
  lights[3] := CreateLight(LIGHT_POINT, Vector3Create(2, 1, -2), Vector3Zero(), BLUE, deferredShader);

  for i := 0 to MAX_CUBES - 1 do
  begin
    cubePositions[i] := Vector3Create(Random(10) - 5, Random(5), Random(10) - 5);
    cubeRotations[i] := Random(360);
  end;

  mode := DEFERRED_SHADING;
  rlEnableDepthTest();
  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    cameraPos[0] := camera.position.x;
    cameraPos[1] := camera.position.y;
    cameraPos[2] := camera.position.z;
    SetShaderValue(deferredShader, deferredShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)], @cameraPos, SHADER_UNIFORM_VEC3);

    if IsKeyPressed(KEY_Y) then lights[0].enabled := not lights[0].enabled;
    if IsKeyPressed(KEY_R) then lights[1].enabled := not lights[1].enabled;
    if IsKeyPressed(KEY_G) then lights[2].enabled := not lights[2].enabled;
    if IsKeyPressed(KEY_B) then lights[3].enabled := not lights[3].enabled;

    if IsKeyPressed(KEY_ONE) then mode := DEFERRED_POSITION;
    if IsKeyPressed(KEY_TWO) then mode := DEFERRED_NORMAL;
    if IsKeyPressed(KEY_THREE) then mode := DEFERRED_ALBEDO;
    if IsKeyPressed(KEY_FOUR) then mode := DEFERRED_SHADING;

    for i := 0 to MAX_LIGHTS - 1 do
      UpdateLightValues(deferredShader, lights[i]);

    BeginDrawing();

      rlEnableFramebuffer(gBuffer.framebufferId);
      rlClearColor(0, 0, 0, 0);
      rlClearScreenBuffers();
      rlDisableColorBlend();

      BeginMode3D(camera);
        rlEnableShader(gbufferShader.id);
          DrawModel(model, Vector3Zero(), 1.0, WHITE);
          DrawModel(cube, Vector3Create(0.0, 1.0, 0.0), 1.0, WHITE);
          for i := 0 to MAX_CUBES - 1 do
            DrawModelEx(cube, cubePositions[i], Vector3Create(1, 1, 1), cubeRotations[i], Vector3Create(0.25, 0.25, 0.25), WHITE);
        rlDisableShader();
      EndMode3D();

      rlEnableColorBlend();
      rlDisableFramebuffer();
      rlClearScreenBuffers();

      case mode of
        DEFERRED_SHADING:
        begin
          BeginMode3D(camera);
            rlDisableColorBlend();
            rlEnableShader(deferredShader.id);
              rlActiveTextureSlot(texUnitPosition);
              rlEnableTexture(gBuffer.positionTextureId);
              rlActiveTextureSlot(texUnitNormal);
              rlEnableTexture(gBuffer.normalTextureId);
              rlActiveTextureSlot(texUnitAlbedoSpec);
              rlEnableTexture(gBuffer.albedoSpecTextureId);
              rlLoadDrawQuad();
            rlDisableShader();
            rlEnableColorBlend();
          EndMode3D();

          rlBindFramebuffer(RL_READ_FRAMEBUFFER, gBuffer.framebufferId);
          rlBindFramebuffer(RL_DRAW_FRAMEBUFFER, 0);
          rlBlitFramebuffer(0, 0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight, $00000100);
          rlDisableFramebuffer();

          BeginMode3D(camera);
            rlEnableShader(rlGetShaderIdDefault());
              for i := 0 to MAX_LIGHTS - 1 do
              begin
                if lights[i].enabled then
                  DrawSphereEx(lights[i].position, 0.2, 8, 8, lights[i].color)
                else
                  DrawSphereWires(lights[i].position, 0.2, 8, 8, ColorAlpha(lights[i].color, 0.3));
              end;
            rlDisableShader();
          EndMode3D();
          DrawText('FINAL RESULT', 10, screenHeight - 30, 20, DARKGREEN);
        end;
        DEFERRED_POSITION:
        begin
          DrawTextureRec(Default(TTexture2D), RectangleCreate(0, 0, 0, 0), Vector2Zero(), WHITE);
          DrawText('POSITION TEXTURE', 10, screenHeight - 30, 20, DARKGREEN);
        end;
        DEFERRED_NORMAL:
        begin
          DrawTextureRec(Default(TTexture2D), RectangleCreate(0, 0, 0, 0), Vector2Zero(), WHITE);
          DrawText('NORMAL TEXTURE', 10, screenHeight - 30, 20, DARKGREEN);
        end;
        DEFERRED_ALBEDO:
        begin
          DrawTextureRec(Default(TTexture2D), RectangleCreate(0, 0, 0, 0), Vector2Zero(), WHITE);
          DrawText('ALBEDO TEXTURE', 10, screenHeight - 30, 20, DARKGREEN);
        end;
      end;

      DrawText('Toggle lights keys: [Y][R][G][B]', 10, 40, 20, DARKGRAY);
      DrawText('Switch G-buffer textures: [1][2][3][4]', 10, 70, 20, DARKGRAY);
      DrawFPS(10, 10);

    EndDrawing();
  end;

  UnloadModel(model);
  UnloadModel(cube);
  UnloadShader(deferredShader);
  UnloadShader(gbufferShader);
  rlUnloadFramebuffer(gBuffer.framebufferId);
  rlUnloadTexture(gBuffer.positionTextureId);
  rlUnloadTexture(gBuffer.normalTextureId);
  rlUnloadTexture(gBuffer.albedoSpecTextureId);
  rlUnloadTexture(gBuffer.depthRenderbufferId);
  CloseWindow();
end.
