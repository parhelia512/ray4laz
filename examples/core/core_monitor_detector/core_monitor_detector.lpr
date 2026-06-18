program core_monitor_detector;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_MONITORS = 10;

type
  TMonitorInfo = record
    position: TVector2;
    name: PChar;
    width, height: integer;
    physicalWidth, physicalHeight: integer;
    refreshRate: integer;
  end;

var
  monitors: array[0..MAX_MONITORS - 1] of TMonitorInfo;
  currentMonitorIndex, monitorCount: integer;
  maxWidth, maxHeight, monitorOffsetX: integer;
  i, x, y: integer;
  scale: single;
  drawX, drawY, drawW, drawH: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - monitor detector');

  currentMonitorIndex := GetCurrentMonitor();
  monitorCount := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    maxWidth := 1;
    maxHeight := 1;
    monitorOffsetX := 0;

    monitorCount := GetMonitorCount();
    for i := 0 to monitorCount - 1 do
    begin
      monitors[i].position := GetMonitorPosition(i);
      monitors[i].name := GetMonitorName(i);
      monitors[i].width := GetMonitorWidth(i);
      monitors[i].height := GetMonitorHeight(i);
      monitors[i].physicalWidth := GetMonitorPhysicalWidth(i);
      monitors[i].physicalHeight := GetMonitorPhysicalHeight(i);
      monitors[i].refreshRate := GetMonitorRefreshRate(i);

      if monitors[i].position.x < monitorOffsetX then
        monitorOffsetX := -Trunc(monitors[i].position.x);

      if (Trunc(monitors[i].position.x) + monitors[i].width) > maxWidth then
        maxWidth := Trunc(monitors[i].position.x) + monitors[i].width;
      if (Trunc(monitors[i].position.y) + monitors[i].height) > maxHeight then
        maxHeight := Trunc(monitors[i].position.y) + monitors[i].height;
    end;

    if maxWidth > 1 then
      scale := (screenWidth - 20) / maxWidth
    else
      scale := 1.0;

    currentMonitorIndex := GetCurrentMonitor();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to monitorCount - 1 do
      begin
        drawX := 10 + Trunc((monitors[i].position.x + monitorOffsetX) * scale);
        drawY := 40 + Trunc(monitors[i].position.y * scale);
        drawW := Trunc(monitors[i].width * scale);
        drawH := Trunc(monitors[i].height * scale);

        if i = currentMonitorIndex then
          DrawRectangle(drawX, drawY, drawW, drawH, Fade(LIME, 0.4))
        else
          DrawRectangle(drawX, drawY, drawW, drawH, Fade(LIGHTGRAY, 0.4));

        DrawRectangleLines(drawX, drawY, drawW, drawH, BLACK);

        DrawText(TextFormat('Monitor %d', i), drawX + 5, drawY + 5, 10, BLACK);
        DrawText(TextFormat('%dx%d', monitors[i].width, monitors[i].height), drawX + 5, drawY + 20, 10, DARKGRAY);
      end;

      DrawText(TextFormat('Monitor count: %d', monitorCount), 10, 10, 20, DARKGRAY);
      DrawText(TextFormat('Current monitor: %d', currentMonitorIndex), 10, screenHeight - 30, 20, DARKGRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
