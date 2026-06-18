program shapes_ring_drawing;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui, math;

const
  screenWidth = 800;
  screenHeight = 450;

var
  center: TVector2;
  innerRadius, outerRadius: single;
  startAngle, endAngle, segments: single;
  drawRingB, drawRingLinesB, drawCircleLinesB: boolean;
  minSegments: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - ring drawing');

  center := Vector2Create((GetScreenWidth() - 300) / 2.0, GetScreenHeight() / 2.0);
  innerRadius := 80.0;
  outerRadius := 190.0;
  startAngle := 0.0;
  endAngle := 360.0;
  segments := 0.0;
  drawRingb := True;
  drawRingLinesB := False;
  drawCircleLinesB := False;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawLine(500, 0, 500, GetScreenHeight(), Fade(LIGHTGRAY, 0.6));
      DrawRectangle(500, 0, GetScreenWidth() - 500, GetScreenHeight(), Fade(LIGHTGRAY, 0.3));

      if drawRingb then DrawRing(center, innerRadius, outerRadius, startAngle, endAngle, Trunc(segments), Fade(MAROON, 0.3));
      if drawRingLinesB then DrawRingLines(center, innerRadius, outerRadius, startAngle, endAngle, Trunc(segments), Fade(BLACK, 0.4));
      if drawCircleLinesB then DrawCircleSectorLines(center, outerRadius, startAngle, endAngle, Trunc(segments), Fade(BLACK, 0.4));

      GuiSliderBar(RectangleCreate(600, 40, 120, 20), 'StartAngle', PChar(Format('%.2f', [startAngle])), @startAngle, -450, 450);
      GuiSliderBar(RectangleCreate(600, 70, 120, 20), 'EndAngle', PChar(Format('%.2f', [endAngle])), @endAngle, -450, 450);
      GuiSliderBar(RectangleCreate(600, 140, 120, 20), 'InnerRadius', PChar(Format('%.2f', [innerRadius])), @innerRadius, 0, 100);
      GuiSliderBar(RectangleCreate(600, 170, 120, 20), 'OuterRadius', PChar(Format('%.2f', [outerRadius])), @outerRadius, 0, 200);
      GuiSliderBar(RectangleCreate(600, 240, 120, 20), 'Segments', PChar(Format('%.2f', [segments])), @segments, 0, 100);
      GuiCheckBox(RectangleCreate(600, 320, 20, 20), 'Draw Ring', @drawRingB);
      GuiCheckBox(RectangleCreate(600, 350, 20, 20), 'Draw RingLines', @drawRingLinesB);
      GuiCheckBox(RectangleCreate(600, 380, 20, 20), 'Draw CircleLines', @drawCircleLinesB);

      minSegments := Ceil((endAngle - startAngle) / 90);
      if segments >= minSegments then
        DrawText('MODE: MANUAL', 600, 270, 10, MAROON)
      else
        DrawText('MODE: AUTO', 600, 270, 10, DARKGRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
