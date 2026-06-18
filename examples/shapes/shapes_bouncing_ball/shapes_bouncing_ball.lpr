program shapes_bouncing_ball;

{$mode objfpc}{$H+}

uses
cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
var
  BallPosition, BallSpeed: TVector2;
  BallRadius: Integer;
  gravity: single;
  useGravity, Pause: Boolean;
  FramesCounter: Integer;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - bouncing ball');

  BallPosition := Vector2Create(GetScreenWidth() / 2.0, GetScreenHeight() / 2.0);
  BallSpeed := Vector2Create(5.0, 4.0);
  BallRadius := 20;
  gravity := 0.2;
  useGravity := True;

  Pause := False;
  FramesCounter := 0;

  SetTargetFPS(60);
  while not WindowShouldClose() do
    begin
      if IsKeyPressed(KEY_G) then useGravity := not useGravity;
      if IsKeyPressed(KEY_SPACE) then Pause := not Pause;

      if not Pause then
      begin
          BallPosition.X := BallPosition.X + BallSpeed.X;
          BallPosition.Y := BallPosition.Y + BallSpeed.Y;

          if useGravity then
            BallSpeed.Y := BallSpeed.Y + gravity;

          if ((BallPosition.X >= (GetScreenWidth() - BallRadius)) or (BallPosition.X <= BallRadius)) then
            BallSpeed.X := -BallSpeed.X * 1.0;
          if ((BallPosition.Y >= (GetScreenHeight() - BallRadius)) or (BallPosition.Y <= BallRadius)) then
            BallSpeed.Y := -BallSpeed.Y * 0.95;
      end else
        Inc(FramesCounter);

      BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawCircleV(BallPosition, BallRadius, MAROON);
      DrawText('PRESS SPACE to PAUSE BALL MOVEMENT', 10, GetScreenHeight() - 25, 20, LIGHTGRAY);

      if useGravity then
        DrawText('GRAVITY: ON (Press G to disable)', 10, GetScreenHeight() - 50, 20, DARKGREEN)
      else
        DrawText('GRAVITY: OFF (Press G to enable)', 10, GetScreenHeight() - 50, 20, RED);

      if Pause and (((FramesCounter div 30) mod 2) <> 0) then
        DrawText('PAUSED', 350, 200, 30, GRAY);

      DrawFPS(10, 10);
      EndDrawing();
    end;
  CloseWindow();
end.
