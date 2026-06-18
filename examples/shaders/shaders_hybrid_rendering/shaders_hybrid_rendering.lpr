program shaders_hybrid_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, rlgl, raymath, math;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

type
  TRayLocs = record
    camPos, camDir, screenCenter: cardinal;
  end;

function LoadRenderTextureDepthTex(w, h: integer): TRenderTexture2D;
var
  target: TRenderTexture2D;
begin
  target := Default(TRenderTexture2D);
  target.id := rlLoadFramebuffer();
  if target.id > 0 then
  begin
    rlEnableFramebuffer(target.id);
    target.texture.id := rlLoadTexture(nil, w, h, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 1);
    target.texture.width := w;
    target.texture.height := h;
    target.texture.format := PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    target.texture.mipmaps := 1;
    target.depth.id := rlLoadTextureDepth(w, h, False);
    target.depth.width := w;
    target.depth.height := h;
    target.depth.format := 19;
    target.depth.mipmaps := 1;
    rlFramebufferAttach(target.id, target.texture.id, RL_ATTACHMENT_COLOR_CHANNEL0, RL_ATTACHMENT_TEXTURE2D, 0);
    rlFramebufferAttach(target.id, target.depth.id, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_TEXTURE2D, 0);
    if rlFramebufferComplete(target.id) then
      TraceLog(LOG_INFO, 'FBO: [ID %i] Framebuffer object created successfully', target.id);
    rlDisableFramebuffer();
  end
  else
    TraceLog(LOG_WARNING, 'FBO: Framebuffer object can not be created');
  Result := target;
end;

var
  shdrRaymarch, shdrRaster: TShader;
  marchLocs: TRayLocs;
  screenCenter: TVector2;
  target: TRenderTexture2D;
  camera: TCamera;
  camDist: single;
  camDir: TVector3;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - hybrid rendering');

  shdrRaymarch := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/hybrid_raymarch.fs', GLSL_VERSION)));
  shdrRaster := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/hybrid_raster.fs', GLSL_VERSION)));

  marchLocs := Default(TRayLocs);
  marchLocs.camPos := GetShaderLocation(shdrRaymarch, 'camPos');
  marchLocs.camDir := GetShaderLocation(shdrRaymarch, 'camDir');
  marchLocs.screenCenter := GetShaderLocation(shdrRaymarch, 'screenCenter');

  screenCenter := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);
  SetShaderValue(shdrRaymarch, marchLocs.screenCenter, @screenCenter, SHADER_UNIFORM_VEC2);

  target := LoadRenderTextureDepthTex(screenWidth, screenHeight);

  camera := Default(TCamera);
  camera.position := Vector3Create(0.5, 1.0, 1.5);
  camera.target := Vector3Create(0.0, 0.5, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  camDist := 1.0 / single(math.Tan(camera.fovy * 0.5 * DEG2RAD));

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);
    SetShaderValue(shdrRaymarch, marchLocs.camPos, @camera.position, RL_SHADER_UNIFORM_VEC3);

    camDir := Vector3Scale(Vector3Normalize(Vector3Subtract(camera.target, camera.position)), camDist);
    SetShaderValue(shdrRaymarch, marchLocs.camDir, @camDir, RL_SHADER_UNIFORM_VEC3);

    BeginTextureMode(target);
      ClearBackground(WHITE);

      rlEnableDepthTest();
      BeginShaderMode(shdrRaymarch);
        DrawRectangleRec(RectangleCreate(0, 0, screenWidth, screenHeight), WHITE);
      EndShaderMode();

      BeginMode3D(camera);
        BeginShaderMode(shdrRaster);
          DrawCubeWiresV(Vector3Create(0.0, 0.5, 1.0), Vector3Create(1.0, 1.0, 1.0), RED);
          DrawCubeV(Vector3Create(0.0, 0.5, 1.0), Vector3Create(1.0, 1.0, 1.0), PURPLE);
          DrawCubeWiresV(Vector3Create(0.0, 0.5, -1.0), Vector3Create(1.0, 1.0, 1.0), DARKGREEN);
          DrawCubeV(Vector3Create(0.0, 0.5, -1.0), Vector3Create(1.0, 1.0, 1.0), YELLOW);
          DrawGrid(10, 1.0);
        EndShaderMode();
      EndMode3D();
    EndTextureMode();

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawTextureRec(target.texture, RectangleCreate(0, 0, screenWidth, -screenHeight), Vector2Create(0, 0), WHITE);
      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadRenderTexture(target);
  UnloadShader(shdrRaymarch);
  UnloadShader(shdrRaster);
  CloseWindow();
end.
