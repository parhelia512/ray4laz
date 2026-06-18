program shaders_game_of_life;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, raygui, math;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

type
  TInteractionMode = (MODE_RUN = 0, MODE_PAUSE, MODE_DRAW);

  TPresetPattern = record
    name: PChar;
    position: TVector2;
  end;

var
  shdrGameOfLife: TShader;
  resolutionLoc: integer;
  resolution: array[0..1] of single;
  world1, world2: TRenderTexture2D;
  startPattern: TImage;
  currentWorld, previousWorld: ^TRenderTexture2D;
  imageToDraw: PImage;
  frame, zoom, framesPerStep: integer;
  offsetX, offsetY: single;
  preset, mode, windowWidth, windowHeight, worldWidth, worldHeight: integer;
  buttonZoomIn, buttonZoomOut, buttonFaster, buttonSlower: integer;
  presetPatterns: array[0..9] of TPresetPattern;
  numberOfPresets: integer;
  mouseWheelMove: single;
  centerX, centerY: single;
  textureSourceToScreen, textureOnScreen: TRectangle;
  worldRectSource, worldRectDest: TRectangle;
  tempWorld: TRenderTexture2D;
  i, j, randomTiles: integer;
  pattern: TImage;
  toggleGroupIndex: integer;
  previousMousePosition: TVector2;
  mousePosition: TVector2;
  offsetDecimalX, offsetDecimalY: single;
  sizeInWorldX, sizeInWorldY: integer;
  firstColor: integer;
  mouseX, mouseY, prevColor: integer;
  worldOnScreen: TRenderTexture2D;
  x, y: integer;

// Helper function to create preset pattern
function CreatePreset(name: PChar; x, y: single): TPresetPattern;
begin
  Result.name := name;
  Result.position := Vector2Create(x, y);
end;

// Free image if allocated
procedure FreeImageToDraw(var imageToDraw: PImage);
begin
  if imageToDraw <> nil then
  begin
    UnloadImage(imageToDraw^);
    Dispose(imageToDraw);
    imageToDraw := nil;
  end;
end;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - game of life');

  windowWidth := screenWidth - 100;
  windowHeight := screenHeight;
  worldWidth := 2048;
  worldHeight := 2048;
  randomTiles := 8;

  worldRectSource := RectangleCreate(0, 0, worldWidth, -worldHeight);
  worldRectDest := RectangleCreate(0, 0, worldWidth, worldHeight);
  textureOnScreen := RectangleCreate(0, 0, windowWidth, windowHeight);

  // Инициализация пресетов
  presetPatterns[0] := CreatePreset('Glider', 0.5, 0.5);
  presetPatterns[1] := CreatePreset('R-pentomino', 0.5, 0.5);
  presetPatterns[2] := CreatePreset('Acorn', 0.5, 0.5);
  presetPatterns[3] := CreatePreset('Spaceships', 0.1, 0.5);
  presetPatterns[4] := CreatePreset('Still lifes', 0.5, 0.5);
  presetPatterns[5] := CreatePreset('Oscillators', 0.5, 0.5);
  presetPatterns[6] := CreatePreset('Puffer train', 0.1, 0.5);
  presetPatterns[7] := CreatePreset('Glider Gun', 0.2, 0.2);
  presetPatterns[8] := CreatePreset('Breeder', 0.1, 0.5);
  presetPatterns[9] := CreatePreset('Random', 0.5, 0.5);
  numberOfPresets := 10;

  zoom := 1;
  offsetX := (worldWidth - windowWidth) / 2.0;
  offsetY := (worldHeight - windowHeight) / 2.0;
  framesPerStep := 1;
  frame := 0;
  preset := -1;
  mode := Ord(MODE_RUN);
  buttonZoomIn := 0;
  buttonZoomOut := 0;
  buttonFaster := 0;
  buttonSlower := 0;

  shdrGameOfLife := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/game_of_life.fs', GLSL_VERSION)));
  resolutionLoc := GetShaderLocation(shdrGameOfLife, 'resolution');
  resolution[0] := worldWidth;
  resolution[1] := worldHeight;
  SetShaderValue(shdrGameOfLife, resolutionLoc, @resolution, SHADER_UNIFORM_VEC2);

  world1 := LoadRenderTexture(worldWidth, worldHeight);
  world2 := LoadRenderTexture(worldWidth, worldHeight);
  BeginTextureMode(world2);
    ClearBackground(RAYWHITE);
  EndTextureMode();

  startPattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/r_pentomino.png'));
  UpdateTextureRec(world2.texture, RectangleCreate(worldWidth / 2.0, worldHeight / 2.0, startPattern.width, startPattern.height), startPattern.data);
  UnloadImage(startPattern);

  currentWorld := @world2;
  previousWorld := @world1;
  imageToDraw := nil;
  previousMousePosition := Vector2Create(0, 0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    Inc(frame);

    mouseWheelMove := GetMouseWheelMove();

    // Zoom handling
    if (buttonZoomIn = 1) or ((mouseWheelMove > 0.0) and (zoom < 64)) then
    begin
      FreeImageToDraw(imageToDraw);
      centerX := offsetX + (windowWidth / 2.0) / zoom;
      centerY := offsetY + (windowHeight / 2.0) / zoom;
      zoom := zoom * 2;
      offsetX := centerX - (windowWidth / 2.0) / zoom;
      offsetY := centerY - (windowHeight / 2.0) / zoom;
    end
    else if (buttonZoomOut = 1) or ((mouseWheelMove < 0.0) and (zoom > 1)) then
    begin
      FreeImageToDraw(imageToDraw);
      centerX := offsetX + (windowWidth / 2.0) / zoom;
      centerY := offsetY + (windowHeight / 2.0) / zoom;
      zoom := zoom div 2;
      if zoom < 1 then zoom := 1;
      offsetX := centerX - (windowWidth / 2.0) / zoom;
      offsetY := centerY - (windowHeight / 2.0) / zoom;
    end;

    // Speed controls
    if (buttonFaster = 1) and (framesPerStep > 1) then Dec(framesPerStep);
    if (buttonSlower = 1) then Inc(framesPerStep);

    // Mouse management
    if (mode = Ord(MODE_RUN)) or (mode = Ord(MODE_PAUSE)) then
    begin
      FreeImageToDraw(imageToDraw);

      // Pan with mouse left button
      mousePosition := GetMousePosition();
      if IsMouseButtonDown(MOUSE_BUTTON_LEFT) and (mousePosition.x < windowWidth) then
      begin
        offsetX := offsetX - (mousePosition.x - previousMousePosition.x) / zoom;
        offsetY := offsetY - (mousePosition.y - previousMousePosition.y) / zoom;
      end;
      previousMousePosition := mousePosition;
    end
    else // MODE_DRAW
    begin
      offsetDecimalX := offsetX - Floor(offsetX);
      offsetDecimalY := offsetY - Floor(offsetY);
      sizeInWorldX := Trunc(Ceil((windowWidth + offsetDecimalX * zoom) / zoom));
      sizeInWorldY := Trunc(Ceil((windowHeight + offsetDecimalY * zoom) / zoom));
      if offsetX + sizeInWorldX >= worldWidth then
        sizeInWorldX := worldWidth - Trunc(Floor(offsetX));
      if offsetY + sizeInWorldY >= worldHeight then
        sizeInWorldY := worldHeight - Trunc(Floor(offsetY));

      // Create image to draw if not created yet
      if imageToDraw = nil then
      begin
        worldOnScreen := LoadRenderTexture(sizeInWorldX, sizeInWorldY);
        BeginTextureMode(worldOnScreen);
          DrawTexturePro(currentWorld^.texture,
            RectangleCreate(Floor(offsetX), Floor(offsetY), sizeInWorldX, -sizeInWorldY),
            RectangleCreate(0, 0, sizeInWorldX, sizeInWorldY),
            Vector2Create(0, 0), 0.0, WHITE);
        EndTextureMode();
        New(imageToDraw);
        imageToDraw^ := LoadImageFromTexture(worldOnScreen.texture);
        UnloadRenderTexture(worldOnScreen);
      end;

      mousePosition := GetMousePosition();
      firstColor := -1;
      if IsMouseButtonDown(MOUSE_BUTTON_LEFT) and (mousePosition.x < windowWidth) then
      begin
        mouseX := Trunc((mousePosition.x + offsetDecimalX * zoom) / zoom);
        mouseY := Trunc((mousePosition.y + offsetDecimalY * zoom) / zoom);
        if mouseX >= sizeInWorldX then mouseX := sizeInWorldX - 1;
        if mouseY >= sizeInWorldY then mouseY := sizeInWorldY - 1;
        if firstColor = -1 then
        begin
          if GetImageColor(imageToDraw^, mouseX, mouseY).r < 5 then
            firstColor := 0
          else
            firstColor := 1;
        end;
        prevColor := 0;
        if GetImageColor(imageToDraw^, mouseX, mouseY).r >= 5 then
          prevColor := 1;

        if firstColor = 0 then
          ImageDrawPixel(imageToDraw, mouseX, mouseY, BLACK)
        else
          ImageDrawPixel(imageToDraw, mouseX, mouseY, RAYWHITE);

        if prevColor <> firstColor then
          UpdateTextureRec(currentWorld^.texture,
            RectangleCreate(Floor(offsetX), Floor(offsetY), sizeInWorldX, sizeInWorldY),
            imageToDraw^.data);
      end;
    end;

    // Load selected preset
    if preset >= 0 then
    begin
      if preset < numberOfPresets - 1 then // Preset with pattern image to load
      begin
        case preset of
          0: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/glider.png'));
          1: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/r_pentomino.png'));
          2: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/acorn.png'));
          3: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/spaceships.png'));
          4: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/still_lifes.png'));
          5: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/oscillators.png'));
          6: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/puffer_train.png'));
          7: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/glider_gun.png'));
          8: pattern := LoadImage(PChar(GetApplicationDirectory + 'resources/game_of_life/breeder.png'));
        end;

        BeginTextureMode(currentWorld^);
          ClearBackground(RAYWHITE);
        EndTextureMode();

        UpdateTextureRec(currentWorld^.texture,
          RectangleCreate(
            worldWidth * presetPatterns[preset].position.x - pattern.width / 2.0,
            worldHeight * presetPatterns[preset].position.y - pattern.height / 2.0,
            pattern.width, pattern.height),
          pattern.data);
      end
      else // Last preset: Random values
      begin
        pattern := GenImageColor(worldWidth div randomTiles, worldHeight div randomTiles, RAYWHITE);
        for i := 0 to randomTiles - 1 do
        begin
          for j := 0 to randomTiles - 1 do
          begin
            ImageClearBackground(@pattern, RAYWHITE);
            for x := 0 to pattern.width - 1 do
            begin
              for y := 0 to pattern.height - 1 do
              begin
                if GetRandomValue(0, 100) < 15 then
                  ImageDrawPixel(@pattern, x, y, BLACK);
              end;
            end;
            UpdateTextureRec(currentWorld^.texture,
              RectangleCreate(pattern.width * i, pattern.height * j, pattern.width, pattern.height),
              pattern.data);
          end;
        end;
      end;

      UnloadImage(pattern);
      mode := Ord(MODE_PAUSE);
      offsetX := worldWidth * presetPatterns[preset].position.x - windowWidth / zoom / 2.0;
      offsetY := worldHeight * presetPatterns[preset].position.y - windowHeight / zoom / 2.0;
    end;

    // Check window draw inside world limits
    if offsetX < 0 then offsetX := 0;
    if offsetY < 0 then offsetY := 0;
    if offsetX > worldWidth - windowWidth / zoom then offsetX := worldWidth - windowWidth / zoom;
    if offsetY > worldHeight - windowHeight / zoom then offsetY := worldHeight - windowHeight / zoom;

    textureSourceToScreen := RectangleCreate(offsetX, offsetY, windowWidth / zoom, windowHeight / zoom);

    // Run simulation
    if (mode = Ord(MODE_RUN)) and ((frame mod framesPerStep) = 0) then
    begin
      tempWorld := currentWorld^;
      currentWorld^ := previousWorld^;
      previousWorld^ := tempWorld;

      BeginTextureMode(currentWorld^);
        BeginShaderMode(shdrGameOfLife);
          DrawTexturePro(previousWorld^.texture, worldRectSource, worldRectDest, Vector2Create(0, 0), 0.0, RAYWHITE);
        EndShaderMode();
      EndTextureMode();
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw world
      DrawTexturePro(currentWorld^.texture, textureSourceToScreen, textureOnScreen, Vector2Create(0, 0), 0.0, WHITE);

      // Right panel
      DrawLine(windowWidth, 0, windowWidth, screenHeight, ColorCreate(218, 218, 218, 255));
      DrawRectangle(windowWidth, 0, screenWidth - windowWidth, screenHeight, ColorCreate(232, 232, 232, 255));

      DrawText('Conway''s', 704, 4, 20, DARKBLUE);
      DrawText(' game of', 704, 19, 20, DARKBLUE);
      DrawText('  life', 708, 34, 20, DARKBLUE);
      DrawText('in raylib', 757, 42, 6, BLACK);

      // Presets
      DrawText('Presets', 710, 58, 8, GRAY);
      preset := -1;
      for i := 0 to numberOfPresets - 1 do
        if GuiButton(RectangleCreate(710.0, 70.0 + 18 * i, 80.0, 16.0), presetPatterns[i].name) = 1 then
          preset := i;

      // Mode toggle
      toggleGroupIndex := mode;
      GuiToggleGroup(RectangleCreate(710, 258, 80, 16), 'Run'#10'Pause'#10'Draw', @toggleGroupIndex);
      mode := toggleGroupIndex;

      // Zoom controls
      DrawText(PChar(Format('Zoom: %ix', [zoom])), 710, 316, 8, GRAY);
      buttonZoomIn := GuiButton(RectangleCreate(710, 328, 80, 16), 'Zoom in');
      buttonZoomOut := GuiButton(RectangleCreate(710, 346, 80, 16), 'Zoom out');

      // Speed controls
      if framesPerStep > 1 then
        DrawText(PChar(Format('Speed: %i frames', [framesPerStep])), 710, 370, 8, GRAY)
      else
        DrawText('Speed: 1 frame', 710, 370, 8, GRAY);
      buttonFaster := GuiButton(RectangleCreate(710, 382, 80, 16), 'Faster');
      buttonSlower := GuiButton(RectangleCreate(710, 400, 80, 16), 'Slower');

      DrawFPS(712, 426);
    EndDrawing();
  end;

  UnloadShader(shdrGameOfLife);
  UnloadRenderTexture(world1);
  UnloadRenderTexture(world2);
  FreeImageToDraw(imageToDraw);
  CloseWindow();
end.
