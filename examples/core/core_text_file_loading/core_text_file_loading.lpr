program core_text_file_loading;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  cam: TCamera2D;
  fileName: PChar;
  text: PChar;
  lines: PPChar;
  lineCount: integer;
  fontSize, textTop, wrapWidth: integer;
  i, j, lastSpace, lastWrapStart: integer;
  textHeight: integer;
  scrollBar: TRectangle;
  scroll, t: single;
  size: TVector2;
  before: AnsiChar;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - text file loading');

  cam := Default(TCamera2D);
  cam.offset := Vector2Create(0, 0);
  cam.target := Vector2Create(0, 0);
  cam.rotation := 0;
  cam.zoom := 1;

  fileName := 'resources/text_file.txt';
  text := LoadFileText(fileName);

  lineCount := 0;
  lines := LoadTextLines(text, @lineCount);

  fontSize := 20;
  textTop := 25 + fontSize;
  wrapWidth := screenWidth - 20;

  for i := 0 to lineCount - 1 do
  begin
    j := 0;
    lastSpace := 0;
    lastWrapStart := 0;

    while j <= Length(lines[i]) do
    begin
      if (lines[i][j] = ' ') or (lines[i][j] = #0) then
      begin

        before := lines[i][j];
        lines[i][j] := #0;

        if MeasureText(PChar(@lines[i][lastWrapStart]), fontSize) > wrapWidth then
        begin
          lines[i][lastSpace] := #10;
          lastWrapStart := lastSpace + 1;
        end;

        if before <> #0 then lines[i][j] := ' ';
        lastSpace := j;
      end;
      Inc(j);
    end;
  end;

  textHeight := 0;
  for i := 0 to lineCount - 1 do
  begin
    size := MeasureTextEx(GetFontDefault(), lines[i], fontSize, 2);
    textHeight := textHeight + Trunc(size.y) + 10;
  end;

  scrollBar := RectangleCreate(screenWidth - 5, 0, 5, screenHeight * 100.0 / (textHeight - screenHeight));

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    scroll := GetMouseWheelMove();
    cam.target.y := cam.target.y - scroll * fontSize * 1.5;

    if cam.target.y < 0 then cam.target.y := 0;
    if cam.target.y > textHeight - screenHeight + textTop then
      cam.target.y := textHeight - screenHeight + textTop;

    scrollBar.y := Lerp(textTop, screenHeight - scrollBar.height, (cam.target.y - textTop) / (textHeight - screenHeight));

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode2D(cam);
        t := textTop;
        for i := 0 to lineCount - 1 do
        begin
          if Length(lines[i]) > 0 then
            size := MeasureTextEx(GetFontDefault(), lines[i], fontSize, 2)
          else
            size := MeasureTextEx(GetFontDefault(), ' ', fontSize, 2);

          DrawText(lines[i], 10, Trunc(t), fontSize, RED);
          t := t + size.y + 10;
        end;
      EndMode2D();

      DrawRectangle(0, 0, screenWidth, textTop - 10, BEIGE);
      DrawText(PChar(Format('File: %s', [fileName])), 10, 10, fontSize, MAROON);
      DrawRectangleRec(scrollBar, MAROON);

    EndDrawing();
  end;

  UnloadTextLines(lines, lineCount);
  UnloadFileText(text);
  CloseWindow();
end.
