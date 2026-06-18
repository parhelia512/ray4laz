program shaders_rlgl_compute;

{$mode objfpc}{$H+}

uses
  cmem, raylib, rlgl, sysutils;

const
  GOL_WIDTH = 768;
  MAX_BUFFERED_TRANSFERTS = 48;

type
  PGolUpdateCmd = ^TGolUpdateCmd;
  TGolUpdateCmd = record
    x: Cardinal;         // x coordinate of the gol command
    y: Cardinal;         // y coordinate of the gol command
    w: Cardinal;         // width of the filled zone
    enabled: Cardinal;   // whether to enable or disable zone
  end;

  PGolUpdateSSBO = ^TGolUpdateSSBO;
  TGolUpdateSSBO = record
    count: Cardinal;
    commands: array[0..MAX_BUFFERED_TRANSFERTS - 1] of TGolUpdateCmd;
  end;

var
  resolution: TVector2;
  brushSize: Integer;
  golLogicCode: PChar;
  golLogicShader: Cardinal;
  golLogicProgram: Cardinal;
  golRenderShader: TShader;
  resUniformLoc: Integer;
  golTransfertCode: PChar;
  golTransfertShader: Cardinal;
  golTransfertProgram: Cardinal;
  ssboA: Cardinal;
  ssboB: Cardinal;
  ssboTransfert: Cardinal;
  transfertBuffer: TGolUpdateSSBO;
  whiteImage: TImage;
  whiteTex: TTexture2D;
  i: Integer;
  temp: Cardinal;
  mouseWheel: Single;

begin
  // Initialization
  InitWindow(GOL_WIDTH, GOL_WIDTH, 'raylib [shaders] example - rlgl compute');

  resolution := Vector2Create(GOL_WIDTH, GOL_WIDTH);
  brushSize := 8;

  // Game of Life logic compute shader
  golLogicCode := LoadFileText(PChar(GetApplicationDirectory + 'resources/shaders/glsl430/gol.glsl'));
  if golLogicCode = nil then
  begin
    WriteLn('Error: Failed to load gol.glsl shader');
    Halt(1);
  end;

  golLogicShader := rlLoadShader(golLogicCode, RL_COMPUTE_SHADER);
  golLogicProgram := rlLoadShaderProgramCompute(golLogicShader);
  UnloadFileText(golLogicCode);

  // Game of Life logic render shader
  golRenderShader := LoadShader(nil, PChar(GetApplicationDirectory + 'resources/shaders/glsl430/gol_render.glsl'));
  resUniformLoc := GetShaderLocation(golRenderShader, 'resolution');

  // Game of Life transfer shader (CPU<->GPU download and upload)
  golTransfertCode := LoadFileText(PChar(GetApplicationDirectory + 'resources/shaders/glsl430/gol_transfert.glsl'));
  if golTransfertCode = nil then
  begin
    WriteLn('Error: Failed to load gol_transfert.glsl shader');
    Halt(1);
  end;

  golTransfertShader := rlLoadShader(golTransfertCode, RL_COMPUTE_SHADER);
  golTransfertProgram := rlLoadShaderProgramCompute(golTransfertShader);
  UnloadFileText(golTransfertCode);

  // Load shader storage buffer objects (SSBO)
  ssboA := rlLoadShaderBuffer(GOL_WIDTH * GOL_WIDTH * SizeOf(Cardinal), nil, RL_DYNAMIC_COPY);
  ssboB := rlLoadShaderBuffer(GOL_WIDTH * GOL_WIDTH * SizeOf(Cardinal), nil, RL_DYNAMIC_COPY);
  ssboTransfert := rlLoadShaderBuffer(SizeOf(TGolUpdateSSBO), nil, RL_DYNAMIC_COPY);

  // Initialize transfer buffer
  FillChar(transfertBuffer, SizeOf(transfertBuffer), 0);

  // Create a white texture of the size of the window
  whiteImage := GenImageColor(GOL_WIDTH, GOL_WIDTH, WHITE);
  whiteTex := LoadTextureFromImage(whiteImage);
  UnloadImage(whiteImage);

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    mouseWheel := GetMouseWheelMove();
    brushSize := brushSize + Trunc(mouseWheel);
    if brushSize < 1 then brushSize := 1;

    if ((IsMouseButtonDown(MOUSE_BUTTON_LEFT) or IsMouseButtonDown(MOUSE_BUTTON_RIGHT)) and
        (transfertBuffer.count < MAX_BUFFERED_TRANSFERTS)) then
    begin
      // Buffer a new command
      transfertBuffer.commands[transfertBuffer.count].x := GetMouseX() - brushSize div 2;
      transfertBuffer.commands[transfertBuffer.count].y := GetMouseY() - brushSize div 2;
      transfertBuffer.commands[transfertBuffer.count].w := brushSize;

      if IsMouseButtonDown(MOUSE_BUTTON_LEFT) then
        transfertBuffer.commands[transfertBuffer.count].enabled := 1
      else
        transfertBuffer.commands[transfertBuffer.count].enabled := 0;

      Inc(transfertBuffer.count);
    end
    else if transfertBuffer.count > 0 then  // Process transfer buffer
    begin
      // Send SSBO buffer to GPU
      rlUpdateShaderBuffer(ssboTransfert, @transfertBuffer, SizeOf(TGolUpdateSSBO), 0);

      // Process SSBO commands on GPU
      rlEnableShader(golTransfertProgram);
      rlBindShaderBuffer(ssboA, 1);
      rlBindShaderBuffer(ssboTransfert, 3);
      rlComputeShaderDispatch(transfertBuffer.count, 1, 1); // Each GPU unit will process a command!
      rlDisableShader();

      transfertBuffer.count := 0;
    end
    else
    begin
      // Process game of life logic
      rlEnableShader(golLogicProgram);
      rlBindShaderBuffer(ssboA, 1);
      rlBindShaderBuffer(ssboB, 2);
      rlComputeShaderDispatch(GOL_WIDTH div 16, GOL_WIDTH div 16, 1);
      rlDisableShader();

      // ssboA <-> ssboB
      temp := ssboA;
      ssboA := ssboB;
      ssboB := temp;
    end;

    rlBindShaderBuffer(ssboA, 1);
    SetShaderValue(golRenderShader, resUniformLoc, @resolution, SHADER_UNIFORM_VEC2);

    // Draw
    BeginDrawing();
      ClearBackground(BLANK);

      BeginShaderMode(golRenderShader);
        DrawTexture(whiteTex, 0, 0, WHITE);
      EndShaderMode();

      DrawRectangleLines(GetMouseX() - brushSize div 2, GetMouseY() - brushSize div 2,
        brushSize, brushSize, RED);

      DrawText('Use Mouse wheel to increase/decrease brush size', 10, 10, 20, WHITE);
      DrawFPS(GetScreenWidth() - 100, 10);
    EndDrawing();
  end;

  // De-Initialization
  rlUnloadShaderBuffer(ssboA);
  rlUnloadShaderBuffer(ssboB);
  rlUnloadShaderBuffer(ssboTransfert);

  rlUnloadShader(golLogicShader);
  rlUnloadShader(golTransfertShader);
  rlUnloadShaderProgram(golTransfertProgram);
  rlUnloadShaderProgram(golLogicProgram);

  UnloadTexture(whiteTex);
  UnloadShader(golRenderShader);

  CloseWindow();
end.
