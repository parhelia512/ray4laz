program shapes_pie_chart;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui, math;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_PIE_SLICES = 10;

var
  sliceCount: integer;
  donutInnerRadius: single;
  values: array[0..MAX_PIE_SLICES - 1] of single;
  showValues, showPercentages, showDonut: boolean;
  hoveredSlice: integer;
  panelWidth, panelMargin: integer;
  panelPos: TVector2;
  panelRect, canvas: TRectangle;
  center: TVector2;
  radius: single;
  totalValue: single;
  i: integer;
  mousePos: TVector2;
  dx, dy, distance, angle, sweepAngle, midAngle, currentAngle, labelRadius: single;
  color: TColorB;
  currentRadius: single;
  labelText: string;
  textSize: TVector2;
  labelPos: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - pie chart');

  sliceCount := 7;
  donutInnerRadius := 25.0;
  values[0] := 300.0; values[1] := 100.0; values[2] := 450.0; values[3] := 350.0;
  values[4] := 600.0; values[5] := 380.0; values[6] := 750.0;

  showValues := True;
  showPercentages := False;
  showDonut := False;
  hoveredSlice := -1;

  panelWidth := 270;
  panelMargin := 5;
  panelPos := Vector2Create(screenWidth - panelMargin - panelWidth, panelMargin);
  panelRect := RectangleCreate(panelPos.x, panelPos.y, panelWidth, screenHeight - 2.0 * panelMargin);
  canvas := RectangleCreate(0, 0, panelPos.x, screenHeight);
  center := Vector2Create(canvas.width / 2.0, canvas.height / 2.0);
  radius := 205.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    totalValue := 0.0;
    for i := 0 to sliceCount - 1 do
      totalValue := totalValue + values[i];

    hoveredSlice := -1;
    mousePos := GetMousePosition();
    if CheckCollisionPointRec(mousePos, canvas) then
    begin
      dx := mousePos.x - center.x;
      dy := mousePos.y - center.y;
      distance := Sqrt(dx * dx + dy * dy);
      if distance <= radius then
      begin
        angle := ArcTan2(dy, dx) * RAD2DEG;
        if angle < 0 then angle := angle + 360;
        currentAngle := 0.0;
        for i := 0 to sliceCount - 1 do
        begin
          if totalValue > 0 then
            sweepAngle := (values[i] / totalValue) * 360.0
          else
            sweepAngle := 0.0;
          if (angle >= currentAngle) and (angle < (currentAngle + sweepAngle)) then
          begin
            hoveredSlice := i;
            Break;
          end;
          currentAngle := currentAngle + sweepAngle;
        end;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      currentAngle := 0.0;
      for i := 0 to sliceCount - 1 do
      begin
        if totalValue > 0 then
          sweepAngle := (values[i] / totalValue) * 360.0
        else
          sweepAngle := 0.0;
        midAngle := currentAngle + sweepAngle / 2.0;
        color := ColorFromHSV(i / sliceCount * 360.0, 0.75, 0.9);
        currentRadius := radius;
        if i = hoveredSlice then currentRadius := currentRadius + 20.0;

        DrawCircleSector(center, currentRadius, currentAngle, currentAngle + sweepAngle, Trunc(sweepAngle), color);

        if values[i] > 0 then
        begin
          labelText := '';
          if showValues and showPercentages then
            labelText := Format('%.1f (%.0f%%)', [values[i], values[i] / totalValue * 100.0])
          else if showValues then
            labelText := Format('%.1f', [values[i]])
          else if showPercentages then
            labelText := Format('%.0f%%', [values[i] / totalValue * 100.0]);

          labelRadius := radius * 0.7;
          textSize := MeasureTextEx(GetFontDefault(), PChar(labelText), 20, 1);
          labelPos := Vector2Create(
            center.x + Cos(midAngle * DEG2RAD) * labelRadius - textSize.x / 2.0,
            center.y + Sin(midAngle * DEG2RAD) * labelRadius - textSize.y / 2.0
          );
          DrawText(PChar(labelText), Trunc(labelPos.x), Trunc(labelPos.y), 20, WHITE);
        end;

        if showDonut then DrawCircleV(center, donutInnerRadius, RAYWHITE);
        currentAngle := currentAngle + sweepAngle;
      end;

      DrawRectangleRec(panelRect, Fade(LIGHTGRAY, 0.5));
      DrawRectangleLinesEx(panelRect, 1, GRAY);

      GuiSpinner(RectangleCreate(panelPos.x + 95, panelPos.y + 12, 125, 25), 'Slices ', @sliceCount, 1, MAX_PIE_SLICES, False);
      GuiCheckBox(RectangleCreate(panelPos.x + 20, panelPos.y + 52, 20, 20), 'Show Values', @showValues);
      GuiCheckBox(RectangleCreate(panelPos.x + 20, panelPos.y + 82, 20, 20), 'Show Percentages', @showPercentages);
      GuiCheckBox(RectangleCreate(panelPos.x + 20, panelPos.y + 112, 20, 20), 'Make Donut', @showDonut);

      if not showDonut then
        GuiSliderBar(RectangleCreate(panelPos.x + 80, panelPos.y + 142, panelRect.width - 100, 30),
          'Inner Radius', nil, @donutInnerRadius, 5.0, radius - 10.0);

      DrawText(PChar(Format('Total: %.0f', [totalValue])), trunc(panelPos.x + 10), trunc(panelPos.y + 180), 10, DARKGRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
