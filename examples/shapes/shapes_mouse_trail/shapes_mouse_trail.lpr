program shapes_mouse_trail;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_TRAIL_LENGTH = 30;

var
  trailPositions: array[0..MAX_TRAIL_LENGTH - 1] of TVector2;
  mousePosition: TVector2;
  i: integer;
  ratio: single;
  trailColor: TColorB;
  trailRadius: single;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - mouse trail');

  for i := 0 to MAX_TRAIL_LENGTH - 1 do
    trailPositions[i] := Vector2Create(0, 0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    mousePosition := GetMousePosition();

    for i := MAX_TRAIL_LENGTH - 1 downto 1 do
      trailPositions[i] := trailPositions[i - 1];

    trailPositions[0] := mousePosition;

    BeginDrawing();
      ClearBackground(BLACK);

      for i := 0 to MAX_TRAIL_LENGTH - 1 do
      begin
        if (trailPositions[i].x <> 0.0) or (trailPositions[i].y <> 0.0) then
        begin
          ratio := (MAX_TRAIL_LENGTH - i) / MAX_TRAIL_LENGTH;
          trailColor := Fade(SKYBLUE, ratio * 0.5 + 0.5);
          trailRadius := 15.0 * ratio;
          DrawCircleV(trailPositions[i], trailRadius, trailColor);
        end;
      end;

      DrawCircleV(mousePosition, 15.0, WHITE);
      DrawText('Move the mouse to see the trail effect!', 10, screenHeight - 30, 20, LIGHTGRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
