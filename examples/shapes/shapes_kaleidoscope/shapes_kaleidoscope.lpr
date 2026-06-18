program shapes_kaleidoscope;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_DRAW_LINES = 8192;

type
  TLine = record
    start, endPos: TVector2;
  end;

var
  lines: array[0..MAX_DRAW_LINES - 1] of TLine;
  symmetry: integer;
  angle, thickness: single;
  resetButtonRec, backButtonRec, nextButtonRec: TRectangle;
  mousePos, prevMousePos, lineStart, lineEnd, scaleVector, offset: TVector2;
  camera: TCamera2D;
  currentLineCounter, totalLineCounter: integer;
  resetButtonClicked, backButtonClicked, nextButtonClicked: INTEGER;
  s, i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - kaleidoscope');

  symmetry := 6;
  angle := 360.0 / symmetry;
  thickness := 3.0;
  resetButtonRec := RectangleCreate(screenWidth - 55.0, 5.0, 50, 25);
  backButtonRec := RectangleCreate(screenWidth - 55.0, screenHeight - 30.0, 25, 25);
  nextButtonRec := RectangleCreate(screenWidth - 30.0, screenHeight - 30.0, 25, 25);

  mousePos := Vector2Create(0, 0);
  prevMousePos := Vector2Create(0, 0);
  scaleVector := Vector2Create(1.0, -1.0);
  offset := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);

 // camera := TCamera2D.Create();
  camera.target := Vector2Create(0, 0);
  camera.offset := offset;
  camera.rotation := 0.0;
  camera.zoom := 1.0;

  currentLineCounter := 0;
  totalLineCounter := 0;
  resetButtonClicked := 0;
  backButtonClicked := 0;
  nextButtonClicked := 0;

  SetTargetFPS(20);

  while not WindowShouldClose() do
  begin
    prevMousePos := mousePos;
    mousePos := GetMousePosition();

    lineStart := Vector2Subtract(mousePos, offset);
    lineEnd := Vector2Subtract(prevMousePos, offset);

    if IsMouseButtonDown(MOUSE_LEFT_BUTTON) and
       (not CheckCollisionPointRec(mousePos, resetButtonRec)) and
       (not CheckCollisionPointRec(mousePos, backButtonRec)) and
       (not CheckCollisionPointRec(mousePos, nextButtonRec)) then
    begin
      for s := 0 to symmetry - 1 do
      begin
        if totalLineCounter >= MAX_DRAW_LINES - 1 then Break;

        lineStart := Vector2Rotate(lineStart, angle * DEG2RAD);
        lineEnd := Vector2Rotate(lineEnd, angle * DEG2RAD);

        lines[totalLineCounter].start := lineStart;
        lines[totalLineCounter].endPos := lineEnd;

        lines[totalLineCounter + 1].start := Vector2Multiply(lineStart, scaleVector);
        lines[totalLineCounter + 1].endPos := Vector2Multiply(lineEnd, scaleVector);

        totalLineCounter := totalLineCounter + 2;
        currentLineCounter := totalLineCounter;
      end;
    end;

    if resetButtonClicked = 1 then
    begin
      FillChar(lines, SizeOf(TLine) * MAX_DRAW_LINES, 0);
      currentLineCounter := 0;
      totalLineCounter := 0;
    end;

    if (backButtonClicked = 1) and (currentLineCounter > 0) then
      Dec(currentLineCounter);

    if (nextButtonClicked = 1) and (currentLineCounter < MAX_DRAW_LINES) and ((currentLineCounter + 1) <= totalLineCounter) then
      Inc(currentLineCounter);

    BeginDrawing();
      ClearBackground(RAYWHITE);
      BeginMode2D(camera);

      for s := 0 to symmetry - 1 do
      begin
        i := 0;
        while i < currentLineCounter do
        begin
          DrawLineEx(lines[i].start, lines[i].endPos, thickness, BLACK);
          DrawLineEx(lines[i + 1].start, lines[i + 1].endPos, thickness, BLACK);
          i := i + 2;
        end;
      end;

      EndMode2D();

      if (currentLineCounter - 1) < 0 then GuiDisable();
      backButtonClicked := GuiButton(backButtonRec, '<');
      GuiEnable();

      if (currentLineCounter + 1) > totalLineCounter then GuiDisable();
      nextButtonClicked := GuiButton(nextButtonRec, '>');
      GuiEnable();
      resetButtonClicked := GuiButton(resetButtonRec, 'Reset');

      DrawText(PChar(Format('LINES: %d/%d', [currentLineCounter, MAX_DRAW_LINES])), 10, screenHeight - 30, 20, MAROON);
      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
