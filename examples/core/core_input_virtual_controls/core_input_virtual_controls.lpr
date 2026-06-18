program core_input_virtual_controls;

{$mode objfpc}{$H+}

uses cmem, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;

type
  TPadButton = (BUTTON_NONE = -1, BUTTON_UP = 0, BUTTON_LEFT, BUTTON_RIGHT, BUTTON_DOWN, BUTTON_MAX);

var
  padPosition: TVector2;
  buttonRadius: single;
  buttonPositions: array[0..3] of TVector2;
  arrowTris: array[0..3] of array[0..2] of TVector2;
  buttonLabelColors: array[0..3] of TColorB;
  pressedButton: integer;
  inputPosition: TVector2;
  playerPosition: TVector2;
  playerSpeed: single;
  i: integer;
  distX, distY: single;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - input virtual controls');

  padPosition := Vector2Create(100, 350);
  buttonRadius := 30;

  buttonPositions[0] := Vector2Create(padPosition.x, padPosition.y - buttonRadius * 1.5);
  buttonPositions[1] := Vector2Create(padPosition.x - buttonRadius * 1.5, padPosition.y);
  buttonPositions[2] := Vector2Create(padPosition.x + buttonRadius * 1.5, padPosition.y);
  buttonPositions[3] := Vector2Create(padPosition.x, padPosition.y + buttonRadius * 1.5);

  arrowTris[0][0] := Vector2Create(buttonPositions[0].x, buttonPositions[0].y - 12);
  arrowTris[0][1] := Vector2Create(buttonPositions[0].x - 9, buttonPositions[0].y + 9);
  arrowTris[0][2] := Vector2Create(buttonPositions[0].x + 9, buttonPositions[0].y + 9);

  arrowTris[1][0] := Vector2Create(buttonPositions[1].x + 9, buttonPositions[1].y - 9);
  arrowTris[1][1] := Vector2Create(buttonPositions[1].x - 12, buttonPositions[1].y);
  arrowTris[1][2] := Vector2Create(buttonPositions[1].x + 9, buttonPositions[1].y + 9);

  arrowTris[2][0] := Vector2Create(buttonPositions[2].x + 12, buttonPositions[2].y);
  arrowTris[2][1] := Vector2Create(buttonPositions[2].x - 9, buttonPositions[2].y - 9);
  arrowTris[2][2] := Vector2Create(buttonPositions[2].x - 9, buttonPositions[2].y + 9);

  arrowTris[3][0] := Vector2Create(buttonPositions[3].x - 9, buttonPositions[3].y - 9);
  arrowTris[3][1] := Vector2Create(buttonPositions[3].x, buttonPositions[3].y + 12);
  arrowTris[3][2] := Vector2Create(buttonPositions[3].x + 9, buttonPositions[3].y - 9);

  buttonLabelColors[0] := YELLOW;
  buttonLabelColors[1] := BLUE;
  buttonLabelColors[2] := RED;
  buttonLabelColors[3] := GREEN;

  pressedButton := -1;
  inputPosition := Vector2Create(0, 0);
  playerPosition := Vector2Create(screenWidth / 2, screenHeight / 2);
  playerSpeed := 75;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if GetTouchPointCount() > 0 then
      inputPosition := GetTouchPosition(0)
    else
      inputPosition := GetMousePosition();

    pressedButton := -1;

    if (GetTouchPointCount() > 0) or ((GetTouchPointCount() = 0) and IsMouseButtonDown(MOUSE_BUTTON_LEFT)) then
    begin
      for i := 0 to 3 do
      begin
        distX := Abs(buttonPositions[i].x - inputPosition.x);
        distY := Abs(buttonPositions[i].y - inputPosition.y);
        if (distX + distY < buttonRadius) then
        begin
          pressedButton := i;
          Break;
        end;
      end;
    end;

    case pressedButton of
      0: playerPosition.y := playerPosition.y - playerSpeed * GetFrameTime();
      1: playerPosition.x := playerPosition.x - playerSpeed * GetFrameTime();
      2: playerPosition.x := playerPosition.x + playerSpeed * GetFrameTime();
      3: playerPosition.y := playerPosition.y + playerSpeed * GetFrameTime();
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawCircleV(playerPosition, 50, MAROON);

      for i := 0 to 3 do
      begin
        if i = pressedButton then
          DrawCircleV(buttonPositions[i], buttonRadius, DARKGRAY)
        else
          DrawCircleV(buttonPositions[i], buttonRadius, BLACK);
        DrawTriangle(arrowTris[i][0], arrowTris[i][1], arrowTris[i][2], buttonLabelColors[i]);
      end;

      DrawText('move the player with D-Pad buttons', 10, 10, 20, DARKGRAY);
    EndDrawing();
  end;

  CloseWindow();
end.
