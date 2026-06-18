program models_skybox_rendering;

{$mode objfpc}{$H+}

uses cmem, raylib, rlgl, raymath, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

function GenTextureCubemap(shader: TShader; panorama: TTexture2D; size: Integer; format: Integer): TTextureCubemap;
var
  cubemap: TTextureCubemap;
  rbo, fbo: LongWord;
  matFboProjection: TMatrix;
  fboViews: array[0..5] of TMatrix;
  i: Integer;
begin
  cubemap.id := 0;
  cubemap.width := 0;
  cubemap.height := 0;
  cubemap.mipmaps := 0;
  cubemap.format := 0;

  rlDisableBackfaceCulling();

  rbo := rlLoadTextureDepth(size, size, True);
  cubemap.id := rlLoadTextureCubemap(nil, size, format, 1);

  fbo := rlLoadFramebuffer();
  rlFramebufferAttach(fbo, rbo, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_RENDERBUFFER, 0);
  rlFramebufferAttach(fbo, cubemap.id, RL_ATTACHMENT_COLOR_CHANNEL0, RL_ATTACHMENT_CUBEMAP_POSITIVE_X, 0);

  if rlFramebufferComplete(fbo) then
    TraceLog(LOG_INFO, 'FBO: [ID %i] Framebuffer object created successfully', fbo);

  rlEnableShader(shader.id);

  matFboProjection := MatrixPerspective(90.0 * DEG2RAD, 1.0, rlGetCullDistanceNear(), rlGetCullDistanceFar());
  rlSetUniformMatrix(shader.locs[SHADER_LOC_MATRIX_PROJECTION], matFboProjection);

  fboViews[0] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(1, 0, 0), Vector3Create(0, -1, 0));
  fboViews[1] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(-1, 0, 0), Vector3Create(0, -1, 0));
  fboViews[2] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(0, 1, 0), Vector3Create(0, 0, 1));
  fboViews[3] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(0, -1, 0), Vector3Create(0, 0, -1));
  fboViews[4] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(0, 0, 1), Vector3Create(0, -1, 0));
  fboViews[5] := MatrixLookAt(Vector3Create(0, 0, 0), Vector3Create(0, 0, -1), Vector3Create(0, -1, 0));

  rlViewport(0, 0, size, size);

  rlActiveTextureSlot(0);
  rlEnableTexture(panorama.id);

  for i := 0 to 5 do
  begin
    rlSetUniformMatrix(shader.locs[SHADER_LOC_MATRIX_VIEW], fboViews[i]);
    rlFramebufferAttach(fbo, cubemap.id, RL_ATTACHMENT_COLOR_CHANNEL0, RL_ATTACHMENT_CUBEMAP_POSITIVE_X + i, 0);
    rlEnableFramebuffer(fbo);
    rlClearScreenBuffers();
    rlLoadDrawCube();
  end;

  rlDisableShader();
  rlDisableTexture();
  rlDisableFramebuffer();
  rlUnloadFramebuffer(fbo);

  rlViewport(0, 0, rlGetFramebufferWidth(), rlGetFramebufferHeight());
  rlEnableBackfaceCulling();

  cubemap.width := size;
  cubemap.height := size;
  cubemap.mipmaps := 1;
  cubemap.format := format;

  Result := cubemap;
end;

var
  camera: TCamera3D;
  cube: TMesh;
  skybox: TModel;
  useHDR: Boolean;
  shdrCubemap: TShader;
  skyboxFileName: array[0..255] of AnsiChar;
  image: TImage;
  droppedFiles: TFilePathList;
  fp: PAnsiChar;
  val1: Integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - skybox rendering');

  camera.position := Vector3Create(1.0, 1.0, 1.0);
  camera.target := Vector3Create(4.0, 1.0, 4.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  cube := GenMeshCube(1.0, 1.0, 1.0);
  skybox := LoadModelFromMesh(cube);

  useHDR := False;

  skybox.materials[0].shader := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/skybox.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/skybox.fs', GLSL_VERSION)));

  val1 := Ord(MATERIAL_MAP_CUBEMAP);
  SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, 'environmentMap'), @val1, SHADER_UNIFORM_INT);

  val1 := 0;
  SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, 'doGamma'), @val1, SHADER_UNIFORM_INT);
  SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, 'vflipped'), @val1, SHADER_UNIFORM_INT);

  shdrCubemap := LoadShader(
    PChar(TextFormat('resources/shaders/glsl%i/cubemap.vs', GLSL_VERSION)),
    PChar(TextFormat('resources/shaders/glsl%i/cubemap.fs', GLSL_VERSION)));

  val1 := 0;
  SetShaderValue(shdrCubemap, GetShaderLocation(shdrCubemap, 'equirectangularMap'), @val1, SHADER_UNIFORM_INT);

  FillChar(skyboxFileName, SizeOf(skyboxFileName), 0);
  TextCopy(skyboxFileName, 'resources/skybox.png');

  image := LoadImage('resources/skybox.png');
  skybox.materials[0].maps[Ord(MATERIAL_MAP_CUBEMAP)].texture := LoadTextureCubemap(image, CUBEMAP_LAYOUT_AUTO_DETECT);
  UnloadImage(image);

  DisableCursor();

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_FIRST_PERSON);

    if IsFileDropped() then
    begin
      droppedFiles := LoadDroppedFiles();

      if droppedFiles.count = 1 then
      begin
        fp := droppedFiles.paths[0];
        if IsFileExtension(fp, '.png;.jpg;.hdr;.bmp;.tga') then
        begin
          UnloadTexture(skybox.materials[0].maps[Ord(MATERIAL_MAP_CUBEMAP)].texture);

          image := LoadImage(fp);
          skybox.materials[0].maps[Ord(MATERIAL_MAP_CUBEMAP)].texture := LoadTextureCubemap(image, CUBEMAP_LAYOUT_AUTO_DETECT);
          UnloadImage(image);

          TextCopy(skyboxFileName, fp);
        end;
      end;

      UnloadDroppedFiles(droppedFiles);
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        rlDisableBackfaceCulling();
        rlDisableDepthMask();
          DrawModel(skybox, Vector3Create(0, 0, 0), 1.0, WHITE);
        rlEnableBackfaceCulling();
        rlEnableDepthMask();

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText(PChar(Format(': %s', [GetFileName(skyboxFileName)])), 10, GetScreenHeight() - 20, 10, BLACK);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadShader(skybox.materials[0].shader);
  UnloadTexture(skybox.materials[0].maps[Ord(MATERIAL_MAP_CUBEMAP)].texture);
  UnloadModel(skybox);

  CloseWindow();
end.
