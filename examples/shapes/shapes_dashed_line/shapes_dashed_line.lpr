program shapes_dashed_line;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  lineStartPosition, lineEndPosition: TVector2;
  dashLength, blankLength: single;
  lineColors: array[0..7] of TColorB;
  colorIndex: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - dashed line');

  lineStartPosition := Vector2Create(20.0, 50.0);
  lineEndPosition := Vector2Create(780.0, 400.0);
  dashLength := 25.0;
  blankLength := 15.0;

  lineColors[0] := RED;
  lineColors[1] := ORANGE;
  lineColors[2] := GOLD;
  lineColors[3] := GREEN;
  lineColors[4] := BLUE;
  lineColors[5] := VIOLET;
  lineColors[6] := PINK;
  lineColors[7] := BLACK;

  colorIndex := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    lineEndPosition := GetMousePosition();

    if IsKeyDown(KEY_UP) then dashLength := dashLength + 1.0;
    if IsKeyDown(KEY_DOWN) and (dashLength > 1.0) then dashLength := dashLength - 1.0;
    if IsKeyDown(KEY_RIGHT) then blankLength := blankLength + 1.0;
    if IsKeyDown(KEY_LEFT) and (blankLength > 1.0) then blankLength := blankLength - 1.0;

    if IsKeyPressed(KEY_C) then colorIndex := (colorIndex + 1) mod 8;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawLineDashed(lineStartPosition, lineEndPosition, Trunc(dashLength), Trunc(blankLength), lineColors[colorIndex]);

      DrawRectangle(5, 5, 265, 95, Fade(SKYBLUE, 0.5));
      DrawRectangleLines(5, 5, 265, 95, BLUE);

      DrawText('CONTROLS:', 15, 15, 10, BLACK);
      DrawText('UP/DOWN: Change Dash Length', 15, 35, 10, BLACK);
      DrawText('LEFT/RIGHT: Change Space Length', 15, 55, 10, BLACK);
      DrawText('C: Cycle Color', 15, 75, 10, BLACK);

      DrawText(PChar(Format('Dash: %.0f | Space: %.0f', [dashLength, blankLength])), 15, 115, 10, DARKGRAY);

      DrawFPS(screenWidth - 80, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
