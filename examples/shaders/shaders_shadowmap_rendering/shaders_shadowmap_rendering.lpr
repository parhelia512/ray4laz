program shaders_shadowmap_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath, rlgl;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  SHADOWMAP_RESOLUTION = 1024;

function LoadShadowmapRenderTexture(w, h: integer): TRenderTexture2D;
var
  target: TRenderTexture2D;
begin
  target := Default(TRenderTexture2D);
  target.id := rlLoadFramebuffer();
  target.texture.width := w;
  target.texture.height := h;
  if target.id > 0 then
  begin
    rlEnableFramebuffer(target.id);
    target.depth.id := rlLoadTextureDepth(w, h, False);
    target.depth.width := w;
    target.depth.height := h;
    target.depth.format := 19;
    target.depth.mipmaps := 1;
    rlFramebufferAttach(target.id, target.depth.id, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_TEXTURE2D, 0);
    if rlFramebufferComplete(target.id) then
      TraceLog(LOG_INFO, 'FBO: [ID %i] Framebuffer object created successfully', target.id);
    rlDisableFramebuffer();
  end
  else
    TraceLog(LOG_WARNING, 'FBO: Framebuffer object can not be created');
  Result := target;
end;

procedure DrawScene(cube, robot: TModel);
begin
  DrawModelEx(cube, Vector3Zero(), Vector3Create(0, 1, 0), 0.0, Vector3Create(10.0, 1.0, 10.0), BLUE);
  DrawModelEx(cube, Vector3Create(1.5, 1.0, -1.5), Vector3Create(0, 1, 0), 0.0, Vector3One(), WHITE);
  DrawModelEx(robot, Vector3Create(0.0, 0.5, 0.0), Vector3Create(0, 1, 0), 0.0, Vector3Create(1.0, 1.0, 1.0), RED);
end;

var
  camera: TCamera3D;
  shadowShader: TShader;
  lightDir: TVector3;
  lightColor: TColorB;
  lightColorNormalized: TVector4;
  lightDirLoc, lightColLoc, ambientLoc, lightVPLoc, shadowMapLoc, shadowMapResolutionLoc: integer;
  ambient: array[0..3] of single;
  cube, robot: TModel;
  anims: PModelAnimation;
  animCount: integer;
  shadowMap: TRenderTexture2D;
  lightCamera: TCamera3D;
  frameCounter: integer;
  lightView, lightProj, lightViewProj: TMatrix;
  textureActiveSlot: integer;
  deltaTime: single;
  cameraPos: TVector3;
  cameraSpeed: single;
  shadowMapRes: integer;
  i: integer;
begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - shadowmap rendering');

  camera := Default(TCamera3D);
  camera.position := Vector3Create(10.0, 10.0, 10.0);
  camera.target := Vector3Zero();
  camera.projection := CAMERA_PERSPECTIVE;
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;

  shadowShader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/shadowmap.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/shadowmap.fs', GLSL_VERSION)));
  shadowShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)] := GetShaderLocation(shadowShader, 'viewPos');

  lightDir := Vector3Normalize(Vector3Create(0.35, -1.0, -0.35));
  lightColor := WHITE;
  lightColorNormalized := ColorNormalize(lightColor);
  lightDirLoc := GetShaderLocation(shadowShader, 'lightDir');
  lightColLoc := GetShaderLocation(shadowShader, 'lightColor');
  SetShaderValue(shadowShader, lightDirLoc, @lightDir, SHADER_UNIFORM_VEC3);
  SetShaderValue(shadowShader, lightColLoc, @lightColorNormalized, SHADER_UNIFORM_VEC4);
  ambientLoc := GetShaderLocation(shadowShader, 'ambient');
  ambient[0] := 0.1; ambient[1] := 0.1; ambient[2] := 0.1; ambient[3] := 1.0;
  SetShaderValue(shadowShader, ambientLoc, @ambient, SHADER_UNIFORM_VEC4);
  lightVPLoc := GetShaderLocation(shadowShader, 'lightVP');
  shadowMapLoc := GetShaderLocation(shadowShader, 'shadowMap');
  shadowMapResolutionLoc := GetShaderLocation(shadowShader, 'shadowMapResolution');

  shadowMapRes := SHADOWMAP_RESOLUTION;
  SetShaderValue(shadowShader, shadowMapResolutionLoc, @shadowMapRes, SHADER_UNIFORM_INT);

  cube := LoadModelFromMesh(GenMeshCube(1.0, 1.0, 1.0));
  cube.materials[0].shader := shadowShader;
  robot := LoadModel(PChar(GetApplicationDirectory + 'resources/models/robot.glb'));

  for i := 0 to robot.materialCount - 1 do
    robot.materials[i].shader := shadowShader;

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/robot.glb'), @animCount);

  shadowMap := LoadShadowmapRenderTexture(SHADOWMAP_RESOLUTION, SHADOWMAP_RESOLUTION);

  lightCamera := Default(TCamera3D);
  lightCamera.position := Vector3Scale(lightDir, -15.0);
  lightCamera.target := Vector3Zero();
  lightCamera.projection := CAMERA_ORTHOGRAPHIC;
  lightCamera.up := Vector3Create(0.0, 1.0, 0.0);
  lightCamera.fovy := 20.0;

  frameCounter := 0;
  lightView := Default(TMatrix);
  lightProj := Default(TMatrix);
  lightViewProj := Default(TMatrix);
  textureActiveSlot := 10;
  cameraSpeed := 0.05;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    deltaTime := GetFrameTime();
    cameraPos := camera.position;
    SetShaderValue(shadowShader, shadowShader.locs[Ord(SHADER_LOC_VECTOR_VIEW)], @cameraPos, SHADER_UNIFORM_VEC3);
    UpdateCamera(@camera, CAMERA_ORBITAL);

    Inc(frameCounter);
    frameCounter := frameCounter mod anims[0].keyframeCount;
    UpdateModelAnimation(robot, anims[0], frameCounter);

    if IsKeyDown(KEY_LEFT) then
      if lightDir.x < 0.6 then lightDir.x := lightDir.x + cameraSpeed * 60.0 * deltaTime;
    if IsKeyDown(KEY_RIGHT) then
      if lightDir.x > -0.6 then lightDir.x := lightDir.x - cameraSpeed * 60.0 * deltaTime;
    if IsKeyDown(KEY_UP) then
      if lightDir.z < 0.6 then lightDir.z := lightDir.z + cameraSpeed * 60.0 * deltaTime;
    if IsKeyDown(KEY_DOWN) then
      if lightDir.z > -0.6 then lightDir.z := lightDir.z - cameraSpeed * 60.0 * deltaTime;

    lightDir := Vector3Normalize(lightDir);
    lightCamera.position := Vector3Scale(lightDir, -15.0);
    SetShaderValue(shadowShader, lightDirLoc, @lightDir, SHADER_UNIFORM_VEC3);

    // PASS 01: Render all objects into the shadowmap render texture
    BeginTextureMode(shadowMap);
      ClearBackground(WHITE);
      BeginMode3D(lightCamera);
        lightView := rlGetMatrixModelview();
        lightProj := rlGetMatrixProjection();
        DrawScene(cube, robot);
      EndMode3D();
    EndTextureMode();
    lightViewProj := MatrixMultiply(lightView, lightProj);

    // PASS 02: Draw the scene into main framebuffer, using the generated shadowmap
    BeginDrawing();
      ClearBackground(RAYWHITE);

      SetShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);
      rlEnableShader(shadowShader.id);

      rlActiveTextureSlot(textureActiveSlot);
      rlEnableTexture(shadowMap.depth.id);
      rlSetUniform(shadowMapLoc, @textureActiveSlot, SHADER_UNIFORM_INT, 1);

      BeginMode3D(camera);
        DrawScene(cube, robot);
      EndMode3D();

      DrawText('Use the arrow keys to rotate the light!', 10, 10, 30, RED);
      DrawText('Shadows in raylib using the shadowmapping algorithm!', screenWidth - 280, screenHeight - 20, 10, GRAY);
    EndDrawing();

    if IsKeyPressed(KEY_F) then TakeScreenshot('shaders_shadowmap.png');
  end;

  UnloadShader(shadowShader);
  UnloadModel(cube);
  UnloadModel(robot);
  UnloadModelAnimations(anims, animCount);
  CloseWindow();
end.
