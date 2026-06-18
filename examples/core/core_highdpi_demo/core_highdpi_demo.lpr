program core_highdpi_demo;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

// Draw text centered at given position
procedure DrawTextCenter(text: PChar; x, y, fontSize: integer; color: TColorB);
var
  size: TVector2;
  pos: TVector2;
begin
  size := MeasureTextEx(GetFontDefault(), text, fontSize, 3);
  pos := Vector2Create(x - size.x / 2, y - size.y / 2);
  DrawTextEx(GetFontDefault(), text, pos, fontSize, 3, color);
end;

var
  logicalGridDescY, logicalGridLabelY, logicalGridTop, logicalGridBottom: integer;
  pixelGridTop, pixelGridBottom, pixelGridLabelY, pixelGridDescY: integer;
  cellSize: integer;
  cellSizePx: single;
  monitorCount, currentMonitor, windowCenter: integer;
  dpiScale: TVector2;
  odd: boolean;
  i, x: integer;
  minTextSpace, lastTextX: integer;
  text: PChar;
  textSize: TVector2;
  textPos: TVector2;

begin
  SetConfigFlags(FLAG_WINDOW_HIGHDPI or FLAG_WINDOW_RESIZABLE);
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - highdpi demo');
  SetWindowMinSize(450, 450);

  logicalGridDescY := 120;
  logicalGridLabelY := logicalGridDescY + 30;
  logicalGridTop := logicalGridLabelY + 30;
  logicalGridBottom := logicalGridTop + 80;
  pixelGridTop := logicalGridBottom - 20;
  pixelGridBottom := pixelGridTop + 80;
  pixelGridLabelY := pixelGridBottom + 30;
  pixelGridDescY := pixelGridLabelY + 30;
  cellSize := 50;
  cellSizePx := cellSize;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    monitorCount := GetMonitorCount();
    if (monitorCount > 1) and IsKeyPressed(KEY_N) then
      SetWindowMonitor((GetCurrentMonitor() + 1) mod monitorCount);

    currentMonitor := GetCurrentMonitor();
    dpiScale := GetWindowScaleDPI();
    cellSizePx := cellSize / dpiScale.x;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      windowCenter := GetScreenWidth() div 2;
      DrawTextCenter(PChar(Format('Dpi Scale: %f', [dpiScale.x])), windowCenter, 30, 40, DARKGRAY);
      DrawTextCenter(PChar(Format('Monitor: %d/%d ([N] next monitor)', [currentMonitor + 1, monitorCount])), windowCenter, 70, 20, LIGHTGRAY);
      DrawTextCenter(PChar(Format('Window is %d "logical points" wide', [GetScreenWidth()])), windowCenter, logicalGridDescY, 20, ORANGE);

      // Logical grid (points)
      odd := True;
      i := cellSize;
      while i < GetScreenWidth() do
      begin
        if odd then
          DrawRectangle(i, logicalGridTop, cellSize, logicalGridBottom - logicalGridTop, ORANGE);
        DrawTextCenter(PChar(IntToStr(i)), i, logicalGridLabelY, 10, LIGHTGRAY);
        DrawLine(i, logicalGridLabelY + 10, i, logicalGridBottom, GRAY);
        odd := not odd;
        i := i + cellSize;
      end;

      // Pixel grid (physical pixels)
      odd := True;
      minTextSpace := 30;
      lastTextX := -minTextSpace;
      i := cellSize;
      while i < GetRenderWidth() do
      begin
        x := Trunc(i / dpiScale.x);
        if odd then
          DrawRectangle(x, pixelGridTop, Trunc(cellSizePx), pixelGridBottom - pixelGridTop, ColorCreate(0, 121, 241, 100));
        DrawLine(x, pixelGridTop, x, pixelGridLabelY - 10, GRAY);
        if (x - lastTextX) >= minTextSpace then
        begin
          DrawTextCenter(PChar(IntToStr(i)), x, pixelGridLabelY, 10, LIGHTGRAY);
          lastTextX := x;
        end;
        odd := not odd;
        i := i + cellSize;
      end;

      DrawTextCenter(PChar(Format('Window is %d "physical pixels" wide', [GetRenderWidth()])), windowCenter, pixelGridDescY, 20, BLUE);

      // Bottom right corner text
      text := 'Can you see this?';
      textSize := MeasureTextEx(GetFontDefault(), text, 20, 3);
      textPos := Vector2Create(GetScreenWidth() - textSize.x - 5, GetScreenHeight() - textSize.y - 5);
      DrawTextEx(GetFontDefault(), text, textPos, 20, 3, LIGHTGRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
