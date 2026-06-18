program core_random_sequence;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils, math;

const
  screenWidth = 800;
  screenHeight = 450;

type
  PColorRect = ^TColorRect;
  TColorRect = record
    color: TColorB;
    rect: TRectangle;
  end;

// Generate random color
function GenerateRandomColor: TColorB;
begin
  Result := ColorCreate(
    GetRandomValue(0, 255),
    GetRandomValue(0, 255),
    GetRandomValue(0, 255),
    255
  );
end;

// Generate random color rect sequence
function GenerateRandomColorRectSequence(rectCount: integer; rectWidth, screenWidth, screenHeight: Single): PColorRect;
var
  seq: PInteger;
  rectangles: PColorRect;
  rectSeqWidth, startX: Single;
  x, rectHeight: integer;
begin
  seq := LoadRandomSequence(rectCount, 0, rectCount - 1);
  rectangles := GetMem(rectCount * SizeOf(TColorRect));

  rectSeqWidth := rectCount * rectWidth;
  startX := (screenWidth - rectSeqWidth) * 0.5;

  for x := 0 to rectCount - 1 do
  begin
    rectHeight := Round(seq[x] * (screenHeight / (rectCount - 1)));
    rectangles[x].color := GenerateRandomColor();
    rectangles[x].rect := RectangleCreate(
      startX + x * rectWidth,
      screenHeight - rectHeight,
      rectWidth,
      rectHeight
    );
  end;

  UnloadRandomSequence(seq);
  Result := rectangles;
end;

// Shuffle color rect sequence
procedure ShuffleColorRectSequence(rectangles: PColorRect; rectCount: integer);
var
  seq: PInteger;
  i1: integer;
  r1, r2: PColorRect;
  tmp: TColorRect;
begin
  seq := LoadRandomSequence(rectCount, 0, rectCount - 1);

  for i1 := 0 to rectCount - 1 do
  begin
    r1 := @rectangles[i1];
    r2 := @rectangles[seq[i1]];

    // Swap only the color and height
    tmp := r1^;
    r1^.color := r2^.color;
    r1^.rect.height := r2^.rect.height;
    r1^.rect.y := r2^.rect.y;
    r2^.color := tmp.color;
    r2^.rect.height := tmp.rect.height;
    r2^.rect.y := tmp.rect.y;
  end;

  UnloadRandomSequence(seq);
end;

// Draw centered key help text
procedure DrawTextCenterKeyHelp(key, text: PChar; posX, posY, fontSize: integer; color: TColorB);
var
  spaceSize, pressSize, keySize, textSize, totalSize, textSizeCurrent: integer;
begin
  spaceSize := MeasureText(' ', fontSize);
  pressSize := MeasureText('Press', fontSize);
  keySize := MeasureText(key, fontSize);
  textSize := MeasureText(text, fontSize);
  totalSize := pressSize + 2 * spaceSize + keySize + 2 * spaceSize + textSize;
  textSizeCurrent := 0;

  DrawText('Press', posX, posY, fontSize, color);
  textSizeCurrent := textSizeCurrent + pressSize + 2 * spaceSize;
  DrawText(key, posX + textSizeCurrent, posY, fontSize, RED);
  DrawRectangle(posX + textSizeCurrent, posY + fontSize, keySize, 3, RED);
  textSizeCurrent := textSizeCurrent + keySize + 2 * spaceSize;
  DrawText(text, posX + textSizeCurrent, posY, fontSize, color);
end;

var
  rectCount, fontSize, x, rectCountTextSize: integer;
  rectSize: single;
  rectangles: PColorRect;
  rectCountText: PChar;

begin
  // Initialization
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - random sequence');

  rectCount := 20;
  rectSize := screenWidth / rectCount;
  rectangles := GenerateRandomColorRectSequence(rectCount, rectSize, screenWidth, 0.75 * screenHeight);

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    if IsKeyPressed(KEY_SPACE) then
      ShuffleColorRectSequence(rectangles, rectCount);

    if IsKeyPressed(KEY_UP) then
    begin
      Inc(rectCount);
      rectSize := screenWidth / rectCount;
      FreeMem(rectangles);
      rectangles := GenerateRandomColorRectSequence(rectCount, rectSize, screenWidth, 0.75 * screenHeight);
    end;

    if IsKeyPressed(KEY_DOWN) then
    begin
      if rectCount >= 4 then
      begin
        Dec(rectCount);
        rectSize := screenWidth / rectCount;
        FreeMem(rectangles);
        rectangles := GenerateRandomColorRectSequence(rectCount, rectSize, screenWidth, 0.75 * screenHeight);
      end;
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      for x := 0 to rectCount - 1 do
        DrawRectangleRec(rectangles[x].rect, rectangles[x].color);

      DrawTextCenterKeyHelp('SPACE', 'to shuffle the sequence.', 10, screenHeight - 96, 20, BLACK);
      DrawTextCenterKeyHelp('UP', 'to add a rectangle and generate a new sequence.', 10, screenHeight - 64, 20, BLACK);
      DrawTextCenterKeyHelp('DOWN', 'to remove a rectangle and generate a new sequence.', 10, screenHeight - 32, 20, BLACK);

      rectCountText := PChar(Format('%d rectangles', [rectCount]));
      rectCountTextSize := MeasureText(rectCountText, 20);
      DrawText(rectCountText, screenWidth - rectCountTextSize - 10, 10, 20, MAROON);

      DrawFPS(10, 10);

    EndDrawing();
  end;

  // De-Initialization
  FreeMem(rectangles);
  CloseWindow();
end.
