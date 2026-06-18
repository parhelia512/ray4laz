program shapes_rounded_rectangle_drawing;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui;

const
  screenWidth = 800;
  screenHeight = 450;

var
  roundness, width, height, segments, lineThick: single;
  drawRect, drawRoundedRect, drawRoundedLines: boolean;
  rec: TRectangle;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - rounded rectangle drawing');

  roundness := 0.2;
  width := 200.0;
  height := 100.0;
  segments := 0.0;
  lineThick := 1.0;
  drawRect := False;
  drawRoundedRect := True;
  drawRoundedLines := False;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    rec := RectangleCreate((GetScreenWidth() - width - 250) / 2, (GetScreenHeight() - height) / 2.0, width, height);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawLine(560, 0, 560, GetScreenHeight(), Fade(LIGHTGRAY, 0.6));
      DrawRectangle(560, 0, GetScreenWidth() - 500, GetScreenHeight(), Fade(LIGHTGRAY, 0.3));

      if drawRect then DrawRectangleRec(rec, Fade(GOLD, 0.6));
      if drawRoundedRect then DrawRectangleRounded(rec, roundness, Trunc(segments), Fade(MAROON, 0.2));
      if drawRoundedLines then DrawRectangleRoundedLinesEx(rec, roundness, Trunc(segments), lineThick, Fade(MAROON, 0.4));

      GuiSliderBar(RectangleCreate(640, 40, 105, 20), 'Width', PChar(Format('%.2f', [width])), @width, 0, GetScreenWidth() - 300);
      GuiSliderBar(RectangleCreate(640, 70, 105, 20), 'Height', PChar(Format('%.2f', [height])), @height, 0, GetScreenHeight() - 50);
      GuiSliderBar(RectangleCreate(640, 140, 105, 20), 'Roundness', PChar(Format('%.2f', [roundness])), @roundness, 0.0, 1.0);
      GuiSliderBar(RectangleCreate(640, 170, 105, 20), 'Thickness', PChar(Format('%.2f', [lineThick])), @lineThick, 0, 20);
      GuiSliderBar(RectangleCreate(640, 240, 105, 20), 'Segments', PChar(Format('%.2f', [segments])), @segments, 0, 60);
      GuiCheckBox(RectangleCreate(640, 320, 20, 20), 'DrawRoundedRect', @drawRoundedRect);
      GuiCheckBox(RectangleCreate(640, 350, 20, 20), 'DrawRoundedLines', @drawRoundedLines);
      GuiCheckBox(RectangleCreate(640, 380, 20, 20), 'DrawRect', @drawRect);

      if segments >= 4 then
        DrawText('MODE: MANUAL', 640, 280, 10, MAROON)
      else
        DrawText('MODE: AUTO', 640, 280, 10, DARKGRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
