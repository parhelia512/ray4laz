program shapes_easings_ball;

{$mode objfpc}{$H+}

uses cmem, math, raylib, reasings;

const
  screenWidth = 800;
  screenHeight = 450;

var
  ballPositionX: integer;
  ballRadius: integer;
  ballAlpha: single;
  state, framesCounter: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - easings ball');

  ballPositionX := -100;
  ballRadius := 20;
  ballAlpha := 0.0;
  state := 0;
  framesCounter := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if state = 0 then
    begin
      Inc(framesCounter);
      ballPositionX := Round(EaseElasticOut(framesCounter, -100, screenWidth / 2.0 + 100, 120));
      if framesCounter >= 120 then begin framesCounter := 0; state := 1; end;
    end
    else if state = 1 then
    begin
      Inc(framesCounter);
      ballRadius := Round(EaseElasticIn(framesCounter, 20, 500, 200));
      if framesCounter >= 200 then begin framesCounter := 0; state := 2; end;
    end
    else if state = 2 then
    begin
      Inc(framesCounter);
      ballAlpha := EaseCubicOut(framesCounter, 0.0, 1.0, 200);
      if framesCounter >= 200 then begin framesCounter := 0; state := 3; end;
    end
    else if state = 3 then
    begin
      if IsKeyPressed(KEY_ENTER) then
      begin
        ballPositionX := -100;
        ballRadius := 20;
        ballAlpha := 0.0;
        state := 0;
      end;
    end;

    if IsKeyPressed(KEY_R) then framesCounter := 0;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      if state >= 2 then DrawRectangle(0, 0, screenWidth, screenHeight, GREEN);
      DrawCircle(ballPositionX, 200, ballRadius, Fade(RED, 1.0 - ballAlpha));

      if state = 3 then DrawText('PRESS [ENTER] TO PLAY AGAIN!', 240, 200, 20, BLACK);

    EndDrawing();
  end;

  CloseWindow();
end.
