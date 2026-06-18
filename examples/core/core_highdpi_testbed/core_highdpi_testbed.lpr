program core_highdpi_testbed;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  scaleDpi, mousePos, windowPos: TVector2;
  currentMonitor: integer;
  gridSpacing: integer;
  h, v: integer;
  mouseX, mouseY: integer;

begin
  SetConfigFlags(FLAG_WINDOW_RESIZABLE or FLAG_WINDOW_HIGHDPI);
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - highdpi testbed');

  scaleDpi := GetWindowScaleDPI();
  mousePos := GetMousePosition();
  currentMonitor := GetCurrentMonitor();
  windowPos := GetWindowPosition();
  gridSpacing := 40;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    mousePos := GetMousePosition();
    currentMonitor := GetCurrentMonitor();
    scaleDpi := GetWindowScaleDPI();
    windowPos := GetWindowPosition();

    if IsKeyPressed(KEY_SPACE) then
      ToggleBorderlessWindowed();
    if IsKeyPressed(KEY_F) then
      ToggleFullscreen();

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw horizontal grid lines
      h := 0;
      while h <= GetScreenHeight() div gridSpacing do
      begin
        DrawText(PChar(Format('%.2d', [h * gridSpacing])), 4, h * gridSpacing - 4, 10, GRAY);
        DrawLine(24, h * gridSpacing, GetScreenWidth(), h * gridSpacing, LIGHTGRAY);
        Inc(h);
      end;

      // Draw vertical grid lines
      v := 0;
      while v <= GetScreenWidth() div gridSpacing do
      begin
        DrawText(PChar(Format('%.2d', [v * gridSpacing])), v * gridSpacing - 10, 4, 10, GRAY);
        DrawLine(v * gridSpacing, 20, v * gridSpacing, GetScreenHeight(), LIGHTGRAY);
        Inc(v);
      end;

      // Draw UI info
      DrawText(PChar(Format('CURRENT MONITOR: %d/%d (%dx%d)', [
        currentMonitor + 1,
        GetMonitorCount(),
        GetMonitorWidth(currentMonitor),
        GetMonitorHeight(currentMonitor)
      ])), 50, 50, 20, DARKGRAY);

      DrawText(PChar(Format('WINDOW POSITION: %dx%d', [
        Trunc(windowPos.x),
        Trunc(windowPos.y)
      ])), 50, 90, 20, DARKGRAY);

      DrawText(PChar(Format('SCREEN SIZE: %dx%d', [
        GetScreenWidth(),
        GetScreenHeight()
      ])), 50, 130, 20, DARKGRAY);

      DrawText(PChar(Format('RENDER SIZE: %dx%d', [
        GetRenderWidth(),
        GetRenderHeight()
      ])), 50, 170, 20, DARKGRAY);

      DrawText(PChar(Format('DPI SCALE: %.2fx%.2f', [
        scaleDpi.x,
        scaleDpi.y
      ])), 50, 210, 20, GRAY);

      // Draw reference rectangles, top-left and bottom-right corners
      DrawRectangle(0, 0, 30, 60, RED);
      DrawRectangle(GetScreenWidth() - 30, GetScreenHeight() - 60, 30, 60, BLUE);

      // Draw mouse position
      mouseX := GetMouseX();
      mouseY := GetMouseY();
      DrawCircleV(GetMousePosition(), 20, MAROON);
      DrawRectangle(mouseX - 25, mouseY, 50, 2, BLACK);
      DrawRectangle(mouseX, mouseY - 25, 2, 50, BLACK);

      if mouseY > GetScreenHeight() - 60 then
        DrawText(PChar(Format('[%d,%d]', [mouseX, mouseY])), mouseX - 44, mouseY - 46, 20, BLACK)
      else
        DrawText(PChar(Format('[%d,%d]', [mouseX, mouseY])), mouseX - 44, mouseY + 30, 20, BLACK);

      // Help text
      DrawText('Press [SPACE] for borderless windowed, [F] for fullscreen', 50, GetScreenHeight() - 30, 10, LIGHTGRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
