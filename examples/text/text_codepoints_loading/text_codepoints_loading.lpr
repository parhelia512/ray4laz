program text_codepoints_loading;

{$mode objfpc}{$H+}

uses cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  textStr: String;
  codepointCount: Integer;
  codepoints: PInteger;
  codepointsNoDupsCount: Integer;
  codepointsNoDups: PInteger;
  font: TFont;
  showFontAtlas: Boolean;
  codepointSize: Integer;
  ptr: PChar;
  i, j, k: Integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - codepoints loading');

//  textStr := #$3044#$308D#$306F#$306B#$307B#$3078#$3068#$3061#$308A#$306C#$308B#$3092#$308F#$304B#$3088#$305F#$308C#$305D#$3064#$306D#$3089#$3080;
//  textStr := textStr + #10;
//  textStr := textStr + #$3046#$3044#$306E#$304F#$3084#$307E#$3051#$3075#$3053#$3048#$3066#$3042#$3055#$304D#$3086#$3081#$307F#$3057#$3091#$3072#$3082#$305B#$3059;
  textStr := 'いろはにほへと ちりぬるを' + #10 + 'わかよたれそ つねならむ'+ #10 +'うゐのおくやま けふこえて' + #10 +
  'あさきゆめみし ゑひもせす';
  codepointCount := 0;
  codepoints := LoadCodepoints(PChar(textStr), @codepointCount);

  codepointsNoDupsCount := codepointCount;
  codepointsNoDups := PInteger(AllocMem(codepointCount * SizeOf(Integer)));
  Move(codepoints^, codepointsNoDups^, codepointCount * SizeOf(Integer));

  for i := 0 to codepointsNoDupsCount - 1 do
  begin
    j := i + 1;
    while j < codepointsNoDupsCount do
    begin
      if codepointsNoDups[i] = codepointsNoDups[j] then
      begin
        for k := j to codepointsNoDupsCount - 2 do
          codepointsNoDups[k] := codepointsNoDups[k + 1];
        Dec(codepointsNoDupsCount);
      end
      else
        Inc(j);
    end;
  end;

  UnloadCodepoints(codepoints);

  font := LoadFontEx(PChar(GetApplicationDirectory + 'resources/DotGothic16-Regular.ttf'),
    36, codepointsNoDups, codepointsNoDupsCount);

  SetTextureFilter(font.texture, TEXTURE_FILTER_BILINEAR);
  SetTextLineSpacing(20);

  FreeMem(codepointsNoDups);

  showFontAtlas := False;
  codepointSize := 0;
  ptr := PChar(textStr);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_SPACE) then showFontAtlas := not showFontAtlas;

    if IsKeyPressed(KEY_RIGHT) then
    begin
      GetCodepointNext(ptr, @codepointSize);
      Inc(ptr, codepointSize);
    end
    else if IsKeyPressed(KEY_LEFT) then
    begin
      GetCodepointPrevious(ptr, @codepointSize);
      Dec(ptr, codepointSize);
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawRectangle(0, 0, GetScreenWidth, 70, BLACK);
      DrawText(PChar(Format('Total codepoints contained in provided text: %d', [codepointCount])), 10, 10, 20, GREEN);
      DrawText(PChar(Format('Total codepoints required for font atlas (duplicates excluded): %d', [codepointsNoDupsCount])), 10, 40, 20, GREEN);

      if showFontAtlas then
      begin
        DrawTexture(font.texture, 150, 100, BLACK);
        DrawRectangleLines(150, 100, font.texture.width, font.texture.height, BLACK);
      end
      else
        DrawTextEx(font, PChar(textStr), Vector2Create(160, 110), 48, 5, BLACK);

      DrawText('Press SPACE to toggle font atlas view!', 10, GetScreenHeight - 30, 20, GRAY);

    EndDrawing();
  end;

  UnloadFont(font);
  CloseWindow();
end.
