program shapes_math_angle_rotation;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 720;
  screenHeight = 400;

var
  center: TVector2;
  lineLength: single;
  angles: array[0..3] of integer;
  numAngles: integer;
  totalAngle: single;
  i: integer;
  rad, animRad: single;
  endPos, textPos, animEnd: TVector2;
  col, animCol: TColorB;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - math angle rotation');
  SetTargetFPS(60);

  center := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);
  lineLength := 150.0;

  angles[0] := 0;
  angles[1] := 30;
  angles[2] := 60;
  angles[3] := 90;
  numAngles := 4;

  totalAngle := 0.0;

  while not WindowShouldClose() do
  begin
    totalAngle := totalAngle + 1.0;
    if totalAngle >= 360.0 then totalAngle := totalAngle - 360.0;

    BeginDrawing();
      ClearBackground(WHITE);

      DrawText('Fixed angles + rotating line', 10, 10, 20, LIGHTGRAY);

      for i := 0 to numAngles - 1 do
      begin
        rad := angles[i] * DEG2RAD;
        endPos := Vector2Create(center.x + Cos(rad) * lineLength,
                                center.y + Sin(rad) * lineLength);

        case i of
          0: col := GREEN;
          1: col := ORANGE;
          2: col := BLUE;
          3: col := MAGENTA;
        else
          col := WHITE;
        end;

        DrawLineEx(center, endPos, 5.0, col);

        textPos := Vector2Create(center.x + Cos(rad) * (lineLength + 20),
                                 center.y + Sin(rad) * (lineLength + 20));
        DrawText(PChar(IntToStr(angles[i]) + '°'), Trunc(textPos.x), Trunc(textPos.y), 20, col);
      end;

      animRad := totalAngle * DEG2RAD;
      animEnd := Vector2Create(center.x + Cos(animRad) * lineLength,
                               center.y + Sin(animRad) * lineLength);

      // Используем целочисленное значение для HSV
      animCol := ColorFromHSV(Trunc(totalAngle) mod 360, 0.8, 0.9);
      DrawLineEx(center, animEnd, 5.0, animCol);

    EndDrawing();
  end;

  CloseWindow();
end.
