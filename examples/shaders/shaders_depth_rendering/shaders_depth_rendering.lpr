program shaders_depth_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, rlgl;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

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

procedure UnloadRenderTextureDepthTex(target: TRenderTexture2D);
begin
  if target.id > 0 then
  begin
    rlUnloadTexture(target.texture.id);
    rlUnloadTexture(target.depth.id);
    rlUnloadFramebuffer(target.id);
  end;
end;

var
  camera: TCamera;
  target: TRenderTexture2D;
  depthShader: TShader;
  depthLoc, flipTextureLoc: integer;
  cube, floor: TModel;
  flipValue: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - depth rendering');

  camera := Default(TCamera);
  camera.position := Vector3Create(4.0, 1.0, 5.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  target := LoadRenderTextureDepthTex(screenWidth, screenHeight);

  depthShader := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/depth_render.fs', GLSL_VERSION)));
  depthLoc := GetShaderLocation(depthShader, 'depthTexture');
  flipTextureLoc := GetShaderLocation(depthShader, 'flipY');
  flipValue := 1;
  SetShaderValue(depthShader, flipTextureLoc, @flipValue, SHADER_UNIFORM_INT);

  cube := LoadModelFromMesh(GenMeshCube(1.0, 1.0, 1.0));
  floor := LoadModelFromMesh(GenMeshPlane(20.0, 20.0, 1, 1));

  DisableCursor();
  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_FREE);

    BeginTextureMode(target);
      ClearBackground(WHITE);
      BeginMode3D(camera);
        DrawModel(cube, Vector3Create(0.0, 0.0, 0.0), 3.0, YELLOW);
        DrawModel(floor, Vector3Create(10.0, 0.0, 2.0), 2.0, RED);
      EndMode3D();
    EndTextureMode();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginShaderMode(depthShader);
        SetShaderValueTexture(depthShader, depthLoc, target.depth);
        DrawTexture(target.depth, 0, 0, WHITE);
      EndShaderMode();

      DrawRectangle(10, 10, 320, 93, Fade(SKYBLUE, 0.5));
      DrawRectangleLines(10, 10, 320, 93, BLUE);
      DrawText('Camera Controls:', 20, 20, 10, BLACK);
      DrawText('- WASD to move', 40, 40, 10, DARKGRAY);
      DrawText('- Mouse Wheel Pressed to Pan', 40, 60, 10, DARKGRAY);
      DrawText('- Z to zoom to (0, 0, 0)', 40, 80, 10, DARKGRAY);
    EndDrawing();
  end;

  UnloadModel(cube);
  UnloadModel(floor);
  UnloadRenderTextureDepthTex(target);
  UnloadShader(depthShader);
  CloseWindow();
end.
