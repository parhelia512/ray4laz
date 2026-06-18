program text_inline_styling;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

procedure DrawTextStyled(font: TFont; text: PChar; position: TVector2; fontSize, spacing: single; color: TColorB);
var
  textLen: integer;
  colFront, colBack: TColorB;
  backRecPadding: integer;
  textOffsetY, textOffsetX, textLineSpacing, scaleFactor: single;
  i, codepointByteCount, codepoint: integer;
  colHexText: array[0..8] of AnsiChar;
  textPtr: PAnsiChar;
  colHexCount: integer;
  colHexValue: cardinal;
  index: integer;
  increaseX: single;

begin
  if font.texture.id = 0 then font := GetFontDefault();
  textLen := Length(text);
  colFront := color;
  colBack := BLANK;
  backRecPadding := 4;
  textOffsetY := 0.0;
  textOffsetX := 0.0;
  textLineSpacing := 0.0;
  scaleFactor := fontSize / font.baseSize;

  i := 0;
  while i < textLen do
  begin
    codepointByteCount := 0;
    codepoint := GetCodepointNext(@text[i], @codepointByteCount);

    if codepoint = Ord(#10) then
    begin
      textOffsetY := textOffsetY + (fontSize + textLineSpacing);
      textOffsetX := 0.0;
    end
    else
    begin
      if codepoint = Ord('[') then
      begin
        if ((i + 2) < textLen) and (text[i + 1] = 'r') and (text[i + 2] = ']') then
        begin
          colFront := color;
          colBack := BLANK;
          Inc(i, 3);
          Continue;
        end
        else if ((i + 1) < textLen) and ((text[i + 1] = 'c') or (text[i + 1] = 'b')) then
        begin
          Inc(i, 2);
          FillChar(colHexText, SizeOf(colHexText), 0);
          textPtr := @text[i];
          colHexCount := 0;
          while (textPtr <> nil) and (textPtr[colHexCount] <> #0) and (textPtr[colHexCount] <> ']') do
          begin
            if ((textPtr[colHexCount] >= '0') and (textPtr[colHexCount] <= '9')) or
               ((textPtr[colHexCount] >= 'A') and (textPtr[colHexCount] <= 'F')) or
               ((textPtr[colHexCount] >= 'a') and (textPtr[colHexCount] <= 'f')) then
            begin
              colHexText[colHexCount] := textPtr[colHexCount];
              Inc(colHexCount);
            end
            else Break;
          end;

          colHexValue := StrToInt('$' + StrPas(@colHexText));
          if text[i - 1] = 'c' then
            colFront := GetColor(colHexValue)
          else if text[i - 1] = 'b' then
            colBack := GetColor(colHexValue);

          Inc(i, colHexCount + 1);
          Continue;
        end;
      end;

      index := GetGlyphIndex(font, codepoint);
      increaseX := 0.0;

      if font.glyphs[index].advanceX = 0 then
        increaseX := font.recs[index].width * scaleFactor + spacing
      else
        increaseX := font.glyphs[index].advanceX * scaleFactor + spacing;

      if colBack.a > 0 then
        DrawRectangleRec(RectangleCreate(
          position.x + textOffsetX, position.y + textOffsetY - backRecPadding,
          increaseX, fontSize + 2 * backRecPadding), colBack);

      if (codepoint <> Ord(' ')) and (codepoint <> Ord(#9)) then
        DrawTextCodepoint(font, codepoint, Vector2Create(position.x + textOffsetX, position.y + textOffsetY), fontSize, colFront);

      textOffsetX := textOffsetX + increaseX;
    end;

    Inc(i, codepointByteCount);
  end;
end;

function MeasureTextStyled(font: TFont; text: PChar; fontSize, spacing: single): TVector2;
var
  textLen: integer;
  textWidth, textHeight, scaleFactor: single;
  codepoint, index, validCodepointCounter, i, codepointByteCount: integer;
  colHexCount: integer;
  textPtr: PAnsiChar;

begin
  Result := Vector2Create(0, 0);
  if (font.texture.id = 0) or (text = nil) or (text[0] = #0) then Exit;

  textLen := Length(text);
  textWidth := 0.0;
  textHeight := fontSize;
  scaleFactor := fontSize / font.baseSize;
  validCodepointCounter := 0;

  i := 0;
  while i < textLen do
  begin
    codepointByteCount := 0;
    codepoint := GetCodepointNext(@text[i], @codepointByteCount);

    if codepoint = Ord('[') then
    begin
      if ((i + 2) < textLen) and (text[i + 1] = 'r') and (text[i + 2] = ']') then
      begin
        Inc(i, 3);
        Continue;
      end
      else if ((i + 1) < textLen) and ((text[i + 1] = 'c') or (text[i + 1] = 'b')) then
      begin
        Inc(i, 2);
        textPtr := @text[i];
        colHexCount := 0;
        while (textPtr <> nil) and (textPtr[colHexCount] <> #0) and (textPtr[colHexCount] <> ']') do
        begin
          if ((textPtr[colHexCount] >= '0') and (textPtr[colHexCount] <= '9')) or
             ((textPtr[colHexCount] >= 'A') and (textPtr[colHexCount] <= 'F')) or
             ((textPtr[colHexCount] >= 'a') and (textPtr[colHexCount] <= 'f')) then
            Inc(colHexCount)
          else Break;
        end;
        Inc(i, colHexCount + 1);
        Continue;
      end;
    end
    else if codepoint <> Ord(#10) then
    begin
      index := GetGlyphIndex(font, codepoint);
      if font.glyphs[index].advanceX > 0 then
        textWidth := textWidth + font.glyphs[index].advanceX
      else
        textWidth := textWidth + (font.recs[index].width + font.glyphs[index].offsetX);
      Inc(validCodepointCounter);
    end;

    Inc(i, codepointByteCount);
  end;

  Result.x := textWidth * scaleFactor + (validCodepointCounter - 1) * spacing;
  Result.y := textHeight;
end;

var
  textSize: TVector2;
  colRandom: TColorB;
  frameCounter: integer;
  text: string;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - inline styling');

  textSize := Vector2Create(0, 0);
  colRandom := RED;
  frameCounter := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    Inc(frameCounter);

    if (frameCounter mod 20) = 0 then
    begin
      colRandom.r := GetRandomValue(0, 255);
      colRandom.g := GetRandomValue(0, 255);
      colRandom.b := GetRandomValue(0, 255);
      colRandom.a := 255;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawTextStyled(GetFontDefault(), 'This changes the [cFF0000FF]foreground color[r] of provided text!!!',
        Vector2Create(100, 80), 20.0, 2.0, BLACK);

      DrawTextStyled(GetFontDefault(), 'This changes the [bFF00FFFF]background color[r] of provided text!!!',
        Vector2Create(100, 120), 20.0, 2.0, BLACK);

      DrawTextStyled(GetFontDefault(), 'This changes the [c00ff00ff][bff0000ff]foreground and background colors[r]!!!',
        Vector2Create(100, 160), 20.0, 2.0, BLACK);

      DrawTextStyled(GetFontDefault(), 'This changes the [c00ff00ff]alpha[r] relative [cffffffff][b000000ff]from source[r] [cff000088]color[r]!!!',
        Vector2Create(100, 200), 20.0, 2.0, ColorCreate(0, 0, 0, 100));

      text := Format('Let''s be [c%02x%02xFF]CREATIVE[r] !!!', [colRandom.r, colRandom.g, colRandom.b]);
      DrawTextStyled(GetFontDefault(), PChar(text), Vector2Create(100, 240), 40.0, 2.0, BLACK);

      textSize := MeasureTextStyled(GetFontDefault(), PChar(text), 40.0, 2.0);
      DrawRectangleLines(100, 240, Trunc(textSize.x), Trunc(textSize.y), GREEN);

    EndDrawing();
  end;

  CloseWindow();
end.
