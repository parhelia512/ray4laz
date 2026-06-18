program textures_screen_buffer;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_COLORS = 256;
  SCALE_FACTOR = 2;

var
  imageWidth, imageHeight, flameWidth: integer;
  palette: array[0..MAX_COLORS - 1] of TColorB;
  indexBuffer: array of byte;
  flameRootBuffer: array of byte;
  screenImage: TImage;
  screenTexture: TTexture;
  t: single;
  i, x, y: integer;
  flame, moveX, newX, iabove, decay: integer;
  colorIndex: byte;
  col: TColorB;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - screen buffer');

  imageWidth := screenWidth div SCALE_FACTOR;
  imageHeight := screenHeight div SCALE_FACTOR;
  flameWidth := screenWidth div SCALE_FACTOR;

  SetLength(indexBuffer, imageWidth * imageHeight);
  SetLength(flameRootBuffer, flameWidth);

  for i := 0 to imageWidth * imageHeight - 1 do
    indexBuffer[i] := 0;
  for i := 0 to flameWidth - 1 do
    flameRootBuffer[i] := 0;

  screenImage := GenImageColor(imageWidth, imageHeight, BLACK);
  screenTexture := LoadTextureFromImage(screenImage);

  // Generate flame color palette
  for i := 0 to MAX_COLORS - 1 do
  begin
    t := i / (MAX_COLORS - 1);
    palette[i] := ColorFromHSV(250.0 + 150.0 * t * t, t, t);
  end;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Grow flameRoot
    for x := 2 to flameWidth - 1 do
    begin
      flame := flameRootBuffer[x];
      flame := flame + GetRandomValue(0, 2);
      if flame > 255 then flame := 255;
      flameRootBuffer[x] := flame;
    end;

    // Transfer flameRoot to indexBuffer
    for x := 0 to flameWidth - 1 do
    begin
      i := x + (imageHeight - 1) * imageWidth;
      indexBuffer[i] := flameRootBuffer[x];
    end;

    // Clear top row
    for x := 0 to imageWidth - 1 do
    begin
      if indexBuffer[x] <> 0 then indexBuffer[x] := 0;
    end;

    // Skip top row, it is already cleared
    for y := 1 to imageHeight - 1 do
    begin
      for x := 0 to imageWidth - 1 do
      begin
        i := x + y * imageWidth;
        colorIndex := indexBuffer[i];

        if colorIndex <> 0 then
        begin
          indexBuffer[i] := 0;
          moveX := GetRandomValue(0, 2) - 1;
          newX := x + moveX;

          if (newX > 0) and (newX < imageWidth) then
          begin
            iabove := i - imageWidth + moveX;
            decay := GetRandomValue(0, 3);
            if decay < colorIndex then
              colorIndex := colorIndex - decay
            else
              colorIndex := 0;
            indexBuffer[iabove] := colorIndex;
          end;
        end;
      end;
    end;

    // Update screenImage with palette colors
    for y := 1 to imageHeight - 1 do
    begin
      for x := 0 to imageWidth - 1 do
      begin
        i := x + y * imageWidth;
        colorIndex := indexBuffer[i];
        col := palette[colorIndex];
        ImageDrawPixel(@screenImage, x, y, col);
      end;
    end;

    UpdateTexture(screenTexture, screenImage.data);

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawTextureEx(screenTexture, Vector2Create(0, 0), 0.0, 2.0, WHITE);
    EndDrawing();
  end;

  UnloadTexture(screenTexture);
  UnloadImage(screenImage);
  CloseWindow();
end.
