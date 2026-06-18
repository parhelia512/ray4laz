program text_words_alignment;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

type
  TTextAlignment = (TEXT_ALIGN_LEFT = 0, TEXT_ALIGN_CENTRE = 1, TEXT_ALIGN_RIGHT = 2);

var
  textContainerRect: TRectangle;
  textAlignNameH: array[0..2] of string = ('Left', 'Centre', 'Right');
  textAlignNameV: array[0..2] of string = ('Top', 'Middle', 'Bottom');
  words: PPChar;
  wordCount: integer;
  wordIndex: integer;
  fontSize: integer;
  font: TFont;
  hAlign, vAlign: integer;
  textSize: TVector2;
  textPos: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - words alignment');

  textContainerRect := RectangleCreate(
    screenWidth / 2.0 - screenWidth / 4.0,
    screenHeight / 2.0 - screenHeight / 3.0,
    screenWidth / 2.0,
    screenHeight * 2.0 / 3.0
  );

  wordIndex := 0;
  wordCount := 0;
  words := TextSplit('raylib is a simple and easy-to-use library to enjoy videogames programming', ' ', @wordCount);

  fontSize := 40;
  font := GetFontDefault();
  hAlign := 1; // CENTRE
  vAlign := 1; // MIDDLE

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_LEFT) then
      if hAlign > 0 then Dec(hAlign);

    if IsKeyPressed(KEY_RIGHT) then
    begin
      Inc(hAlign);
      if hAlign > 2 then hAlign := 2;
    end;

    if IsKeyPressed(KEY_UP) then
      if vAlign > 0 then Dec(vAlign);

    if IsKeyPressed(KEY_DOWN) then
    begin
      Inc(vAlign);
      if vAlign > 2 then vAlign := 2;
    end;

    if wordCount > 0 then
      wordIndex := Round(GetTime()) mod wordCount
    else
      wordIndex := 0;

    BeginDrawing();
      ClearBackground(DARKBLUE);

      DrawText('Use Arrow Keys to change the text alignment', 20, 20, 20, LIGHTGRAY);
      DrawText(PChar('Alignment: Horizontal = ' + textAlignNameH[hAlign] + ', Vertical = ' + textAlignNameV[vAlign]), 20, 40, 20, LIGHTGRAY);

      DrawRectangleRec(textContainerRect, BLUE);

      textSize := MeasureTextEx(font, words[wordIndex], fontSize, fontSize * 0.1);

      textPos := Vector2Create(
        textContainerRect.x + Lerp(0.0, textContainerRect.width - textSize.x, hAlign * 0.5),
        textContainerRect.y + Lerp(0.0, textContainerRect.height - textSize.y, vAlign * 0.5)
      );

      DrawTextEx(font, words[wordIndex], textPos, fontSize, fontSize * 0.1, RAYWHITE);

    EndDrawing();
  end;

  CloseWindow();
end.
