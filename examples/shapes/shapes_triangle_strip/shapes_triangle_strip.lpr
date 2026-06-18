program shapes_triangle_strip;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui, math;

const
  screenWidth = 800;
  screenHeight = 450;

var
  points: array[0..121] of TVector2;
  center: TVector2;
  segments, insideRadius, outsideRadius: single;
  outline: boolean;
  pointCount, i, i2: integer;
  angleStep, angle1, angle2: single;
  a, b, c, d: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - triangle strip');

  center := Vector2Create(screenWidth / 2.0 - 125.0, screenHeight / 2.0);
  segments := 6.0;
  insideRadius := 100.0;
  outsideRadius := 150.0;
  outline := True;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    pointCount := Trunc(segments);
    angleStep := (360.0 / pointCount) * DEG2RAD;

    i2 := 0;
    for i := 0 to pointCount - 1 do
    begin
      angle1 := i * angleStep;
      points[i2] := Vector2Create(center.x + Cos(angle1) * insideRadius, center.y + Sin(angle1) * insideRadius);
      angle2 := angle1 + angleStep / 2.0;
      points[i2 + 1] := Vector2Create(center.x + Cos(angle2) * outsideRadius, center.y + Sin(angle2) * outsideRadius);
      i2 := i2 + 2;
    end;

    points[pointCount * 2] := points[0];
    points[pointCount * 2 + 1] := points[1];

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to pointCount - 1 do
      begin
        a := points[i * 2];
        b := points[i * 2 + 1];
        c := points[i * 2 + 2];
        d := points[i * 2 + 3];

        angle1 := i * angleStep;
        DrawTriangle(c, b, a, ColorFromHSV(angle1 * RAD2DEG, 1.0, 1.0));
        DrawTriangle(d, b, c, ColorFromHSV((angle1 + angleStep / 2) * RAD2DEG, 1.0, 1.0));

        if outline then
        begin
          DrawTriangleLines(a, b, c, BLACK);
          DrawTriangleLines(c, b, d, BLACK);
        end;
      end;

      DrawLine(580, 0, 580, GetScreenHeight(), ColorCreate(218, 218, 218, 255));
      DrawRectangle(580, 0, GetScreenWidth(), GetScreenHeight(), ColorCreate(232, 232, 232, 255));

      GuiSliderBar(RectangleCreate(640, 40, 120, 20), 'Segments', PChar(Format('%.0f', [segments])), @segments, 6.0, 60.0);
      GuiCheckBox(RectangleCreate(640, 70, 20, 20), 'Outline', @outline);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
