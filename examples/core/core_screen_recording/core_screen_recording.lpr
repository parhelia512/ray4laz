program core_screen_recording;

{$mode objfpc}{$H+}

uses cmem, raylib, Math, SysUtils;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_SINEWAVE_POINTS = 256;

var
  gifRecording: Boolean;
  gifFrameCounter: Cardinal;
  circlePosition: TVector2;
  timeCounter: Single;
  sinePoints: array[0..MAX_SINEWAVE_POINTS - 1] of TVector2;
  i: Integer;
  screenshotCounter: Integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - screen recording');

  gifRecording := False;
  gifFrameCounter := 0;
  circlePosition := Vector2Create(0, screenHeight / 2.0);
  timeCounter := 0;
  screenshotCounter := 0;

  for i := 0 to MAX_SINEWAVE_POINTS - 1 do
  begin
    sinePoints[i].x := i * GetScreenWidth / 180.0;
    sinePoints[i].y := screenHeight / 2.0 + 150 * Sin((2 * PI / 1.5) * (1.0 / 60.0) * i);
  end;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    timeCounter := timeCounter + GetFrameTime();
    circlePosition.x := circlePosition.x + GetScreenWidth / 180.0;
    circlePosition.y := screenHeight / 2.0 + 150 * Sin((2 * PI / 1.5) * timeCounter);

    if circlePosition.x > screenWidth then
    begin
      circlePosition.x := 0;
      circlePosition.y := screenHeight / 2.0;
      timeCounter := 0;
    end;

    if IsKeyDown(KEY_LEFT_CONTROL) and IsKeyPressed(KEY_R) then
    begin
      if gifRecording then
      begin
        gifRecording := False;
        TraceLog(LOG_INFO, 'Finish screen recording');
      end
      else
      begin
        gifRecording := True;
        gifFrameCounter := 0;
        screenshotCounter := 0;
        TraceLog(LOG_INFO, 'Start screen recording (saving PNG frames)');
      end;
    end;

    if gifRecording then
    begin
      Inc(gifFrameCounter);
      if gifFrameCounter > 5 then
      begin
        TakeScreenshot(PChar(GetApplicationDirectory + 'frame_' +
          Format('%.4d', [screenshotCounter]) + '.png'));
        Inc(screenshotCounter);
        gifFrameCounter := 0;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to MAX_SINEWAVE_POINTS - 2 do
      begin
        DrawLineV(sinePoints[i], sinePoints[i + 1], MAROON);
        DrawCircleV(sinePoints[i], 3, MAROON);
      end;

      DrawCircleV(circlePosition, 30, RED);

      if gifRecording then
      begin
        if (Trunc(GetTime * 2) mod 2) = 1 then
        begin
          DrawCircle(30, GetScreenHeight - 20, 10, MAROON);
          DrawText('RECORDING', 50, GetScreenHeight - 25, 10, RED);
        end;
      end;

      DrawFPS(10, 10);
    EndDrawing();
  end;

  if gifRecording then
  begin
    TraceLog(LOG_INFO, 'Finish screen recording');
    gifRecording := False;
  end;

  CloseWindow();
end.
