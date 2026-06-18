program text_strings_management;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_TEXT_LENGTH = 100;
  MAX_TEXT_PARTICLES = 100;
  FONT_SIZE = 30;

type
  PTextParticle = ^TTextParticle;
  TTextParticle = record
    text: array[0..MAX_TEXT_LENGTH - 1] of Char;
    rect: TRectangle;
    vel: TVector2;
    ppos: TVector2;
    padding: Single;
    borderWidth: Single;
    friction: Single;
    elasticity: Single;
    color: TColorB;
    grabbed: Boolean;
  end;

var
  textParticles: array[0..MAX_TEXT_PARTICLES - 1] of TTextParticle;
  particleCount: Integer;
  grabbedTextParticle: Integer;
  pressOffset: TVector2;

// Prepare first text particle (resets everything)
procedure PrepareFirstTextParticle(const txt: PChar);
var
  tp: ^TTextParticle;
begin
  tp := @textParticles[0];
  StrLCopy(tp^.text, txt, MAX_TEXT_LENGTH - 1);
  tp^.rect := RectangleCreate(GetScreenWidth / 2.0, GetScreenHeight / 2.0, 30, 30);
  tp^.vel := Vector2Create(GetRandomValue(-200, 200), GetRandomValue(-200, 200));
  tp^.ppos := Vector2Create(0, 0);
  tp^.padding := 5.0;
  tp^.borderWidth := 5.0;
  tp^.friction := 0.99;
  tp^.elasticity := 0.9;
  tp^.color := RAYWHITE;
  tp^.grabbed := False;
  tp^.rect.width := MeasureText(tp^.text, FONT_SIZE) + tp^.padding * 2;
  tp^.rect.height := FONT_SIZE + tp^.padding * 2;
  particleCount := 1;
  grabbedTextParticle := -1;
end;

// Create a new text particle from a string
function CreateTextParticle(const txt: PChar; x, y: Single; color: TColorB): TTextParticle;
var
  tp: TTextParticle;
begin
  FillChar(tp, SizeOf(tp), 0);
  StrLCopy(tp.text, txt, MAX_TEXT_LENGTH - 1);
  tp.rect := RectangleCreate(x, y, 30, 30);
  tp.vel := Vector2Create(GetRandomValue(-200, 200), GetRandomValue(-200, 200));
  tp.ppos := Vector2Create(0, 0);
  tp.padding := 5.0;
  tp.borderWidth := 5.0;
  tp.friction := 0.99;
  tp.elasticity := 0.9;
  tp.color := color;
  tp.grabbed := False;
  tp.rect.width := MeasureText(tp.text, FONT_SIZE) + tp.padding * 2;
  tp.rect.height := FONT_SIZE + tp.padding * 2;
  Result := tp;
end;

// Slice a text particle
procedure SliceTextParticle(tpIndex: Integer; sliceLength: Integer);
var
  tp: ^TTextParticle;
  len, i, cnt: Integer;
  subText: array[0..MAX_TEXT_LENGTH - 1] of Char;
  newTp: TTextParticle;
begin
  tp := @textParticles[tpIndex];
  len := TextLength(tp^.text);

  if (len > 1) and ((particleCount + len) < MAX_TEXT_PARTICLES) then
  begin
    i := 0;
    while i < len do
    begin
      if sliceLength = 1 then
      begin
        subText[0] := tp^.text[i];
        subText[1] := #0;
      end
      else
      begin
        StrLCopy(subText, PChar(TextSubtext(tp^.text, i, sliceLength)), MAX_TEXT_LENGTH - 1);
      end;

      cnt := particleCount;
      newTp := CreateTextParticle(subText,
        tp^.rect.x + i * tp^.rect.width / len,
        tp^.rect.y,
        ColorCreate(GetRandomValue(0, 255), GetRandomValue(0, 255), GetRandomValue(0, 255), 255)
      );
      textParticles[cnt] := newTp;
      Inc(particleCount);
      Inc(i, sliceLength);
    end;

    // Remove the original particle
    for i := tpIndex to particleCount - 2 do
      textParticles[i] := textParticles[i + 1];
    Dec(particleCount);
  end;
end;

// Slice text particle by character
procedure SliceTextParticleByChar(tpIndex: Integer; charToSlice: Char);
var
  tp: ^TTextParticle;
  tokenCount, i, j, textLen: Integer;
  tokens: array[0..MAX_TEXT_PARTICLES - 1] of PChar;
  token: PChar;
  newTp: TTextParticle;
begin
  tp := @textParticles[tpIndex];
  tokenCount := 0;

  // Split string by character
  // Simple implementation - in real code would use TextSplit
  textLen := TextLength(tp^.text);

  // First, slice the character itself
  for i := 0 to textLen - 1 do
  begin
    if tp^.text[i] = charToSlice then
    begin
      newTp := CreateTextParticle(PChar(String(charToSlice)),
        tp^.rect.x, tp^.rect.y,
        ColorCreate(GetRandomValue(0, 255), GetRandomValue(0, 255), GetRandomValue(0, 255), 255)
      );
      textParticles[particleCount] := newTp;
      Inc(particleCount);
    end;
  end;

  // Now split by the character and create particles for each segment
  i := 0;
  j := 0;
  while i < textLen do
  begin
    if tp^.text[i] = charToSlice then
    begin
      // Skip the delimiter
      Inc(i);
      if i >= textLen then Break;
    end;

    // Find next delimiter or end
    j := i;
    while (j < textLen) and (tp^.text[j] <> charToSlice) do
      Inc(j);

    if j > i then
    begin
      // Extract substring
      token := TextSubtext(tp^.text, i, j - i);
      newTp := CreateTextParticle(token,
        tp^.rect.x, tp^.rect.y,
        ColorCreate(GetRandomValue(0, 255), GetRandomValue(0, 255), GetRandomValue(0, 255), 255)
      );
      textParticles[particleCount] := newTp;
      Inc(particleCount);
      i := j;
    end
    else
      Break;
  end;

  // Remove the original particle
  for i := tpIndex to particleCount - 2 do
    textParticles[i] := textParticles[i + 1];
  Dec(particleCount);
end;

// Shatter a text particle (slice into individual characters)
procedure ShatterTextParticle(tpIndex: Integer);
begin
  SliceTextParticle(tpIndex, 1);
end;

// Glue two text particles together
procedure GlueTextParticles(grabIdx, targetIdx: Integer);
var
  i, newIdx, p1, p2: Integer;
  combined: array[0..MAX_TEXT_LENGTH * 2 - 1] of Char;
  newTp: TTextParticle;
begin
  if (grabIdx < 0) or (targetIdx < 0) or (grabIdx >= particleCount) or (targetIdx >= particleCount) then
    Exit;

  StrLCopy(combined, textParticles[grabIdx].text, MAX_TEXT_LENGTH * 2 - 1);
  StrLCat(combined, textParticles[targetIdx].text, MAX_TEXT_LENGTH * 2 - 1);

  newIdx := particleCount;
  newTp := CreateTextParticle(combined,
    textParticles[grabIdx].rect.x,
    textParticles[grabIdx].rect.y,
    RAYWHITE
  );
  newTp.grabbed := True;
  textParticles[newIdx] := newTp;
  Inc(particleCount);

  textParticles[grabIdx].grabbed := False;
  grabbedTextParticle := particleCount - 1;

  // Remove the two original particles (in reverse order to maintain indices)
  if grabIdx < targetIdx then
  begin
    p1 := grabIdx;
    p2 := targetIdx;
  end
  else
  begin
    p1 := targetIdx;
    p2 := grabIdx;
  end;

  // Remove p2 first (higher index)
  for i := p2 to particleCount - 2 do
    textParticles[i] := textParticles[i + 1];
  Dec(particleCount);

  // Then remove p1
  for i := p1 to particleCount - 2 do
    textParticles[i] := textParticles[i + 1];
  Dec(particleCount);
end;

var
  delta: Single;
  mousePos: TVector2;
  i, j: Integer;
  tp: ^TTextParticle;
  charPressed: Char;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - strings management');

  particleCount := 0;
  grabbedTextParticle := -1;
  pressOffset := Vector2Create(0, 0);

  PrepareFirstTextParticle('raylib => fun videogames programming!');

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    delta := GetFrameTime();
    mousePos := GetMousePosition();

    // Check if a text particle was grabbed (left button)
    if IsMouseButtonPressed(MOUSE_LEFT_BUTTON) then
    begin
      for i := particleCount - 1 downto 0 do
      begin
        tp := @textParticles[i];
        pressOffset.x := mousePos.x - tp^.rect.x;
        pressOffset.y := mousePos.y - tp^.rect.y;
        if CheckCollisionPointRec(mousePos, tp^.rect) then
        begin
          tp^.grabbed := True;
          grabbedTextParticle := i;
          Break;
        end;
      end;
    end;

    // Release any grabbed text particle (left button)
    if IsMouseButtonReleased(MOUSE_LEFT_BUTTON) then
    begin
      if grabbedTextParticle >= 0 then
      begin
        textParticles[grabbedTextParticle].grabbed := False;
        grabbedTextParticle := -1;
      end;
    end;

    // Slice or shatter a text particle (right button)
    if IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) then
    begin
      for i := particleCount - 1 downto 0 do
      begin
        tp := @textParticles[i];
        if CheckCollisionPointRec(mousePos, tp^.rect) then
        begin
          if IsKeyDown(KEY_LEFT_SHIFT) then
            ShatterTextParticle(i)
          else
            SliceTextParticle(i, TextLength(tp^.text) div 2);
          Break;
        end;
      end;
    end;

    // Shake text particles (middle button)
    if IsMouseButtonPressed(MOUSE_MIDDLE_BUTTON) then
    begin
      for i := 0 to particleCount - 1 do
      begin
        if not textParticles[i].grabbed then
          textParticles[i].vel := Vector2Create(GetRandomValue(-2000, 2000), GetRandomValue(-2000, 2000));
      end;
    end;

    // Reset using TextTo* functions
    if IsKeyPressed(KEY_ONE) then PrepareFirstTextParticle('raylib => fun videogames programming!');
    if IsKeyPressed(KEY_TWO) then PrepareFirstTextParticle(TextToUpper('raylib => fun videogames programming!'));
    if IsKeyPressed(KEY_THREE) then PrepareFirstTextParticle(TextToLower('raylib => fun videogames programming!'));
    if IsKeyPressed(KEY_FOUR) then PrepareFirstTextParticle(TextToPascal('raylib_fun_videogames_programming'));
    if IsKeyPressed(KEY_FIVE) then PrepareFirstTextParticle(TextToSnake('RaylibFunVideogamesProgramming'));
    if IsKeyPressed(KEY_SIX) then PrepareFirstTextParticle(TextToCamel('raylib_fun_videogames_programming'));

    // Slice by char pressed only when we have one text particle
    charPressed := Char(GetCharPressed());
    if (charPressed >= 'A') and (charPressed <= 'z') and (particleCount = 1) then
    begin
      SliceTextParticleByChar(0, charPressed);
    end;

    // Update each text particle state
    for i := 0 to particleCount - 1 do
    begin
      tp := @textParticles[i];

      if not tp^.grabbed then
      begin
        // Text particle repositioning using velocity
        tp^.rect.x := tp^.rect.x + tp^.vel.x * delta;
        tp^.rect.y := tp^.rect.y + tp^.vel.y * delta;

        // Hit screen right boundary?
        if (tp^.rect.x + tp^.rect.width) >= screenWidth then
        begin
          tp^.rect.x := screenWidth - tp^.rect.width;
          tp^.vel.x := -tp^.vel.x * tp^.elasticity;
        end
        // Hit screen left boundary?
        else if tp^.rect.x <= 0 then
        begin
          tp^.rect.x := 0;
          tp^.vel.x := -tp^.vel.x * tp^.elasticity;
        end;

        // Same for Y axis
        if (tp^.rect.y + tp^.rect.height) >= screenHeight then
        begin
          tp^.rect.y := screenHeight - tp^.rect.height;
          tp^.vel.y := -tp^.vel.y * tp^.elasticity;
        end
        else if tp^.rect.y <= 0 then
        begin
          tp^.rect.y := 0;
          tp^.vel.y := -tp^.vel.y * tp^.elasticity;
        end;

        // Apply friction
        tp^.vel.x := tp^.vel.x * tp^.friction;
        tp^.vel.y := tp^.vel.y * tp^.friction;
      end
      else
      begin
        // Text particle follows mouse
        tp^.rect.x := mousePos.x - pressOffset.x;
        tp^.rect.y := mousePos.y - pressOffset.y;

        // Calculate velocity from position change
        tp^.vel.x := (tp^.rect.x - tp^.ppos.x) / delta;
        tp^.vel.y := (tp^.rect.y - tp^.ppos.y) / delta;
        tp^.ppos.x := tp^.rect.x;
        tp^.ppos.y := tp^.rect.y;

        // Glue text particles when dragging and pressing left control
        if IsKeyDown(KEY_LEFT_CONTROL) then
        begin
          for j := 0 to particleCount - 1 do
          begin
            if (j <> grabbedTextParticle) and textParticles[grabbedTextParticle].grabbed then
            begin
              if CheckCollisionRecs(textParticles[grabbedTextParticle].rect, textParticles[j].rect) then
              begin
                GlueTextParticles(grabbedTextParticle, j);
                Break;
              end;
            end;
          end;
        end;
      end;
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to particleCount - 1 do
      begin
        tp := @textParticles[i];
        DrawRectangleRec(RectangleCreate(
          tp^.rect.x - tp^.borderWidth,
          tp^.rect.y - tp^.borderWidth,
          tp^.rect.width + tp^.borderWidth * 2,
          tp^.rect.height + tp^.borderWidth * 2), BLACK);
        DrawRectangleRec(tp^.rect, tp^.color);
        DrawText(tp^.text, Round(tp^.rect.x + tp^.padding), Round(tp^.rect.y + tp^.padding), FONT_SIZE, BLACK);
      end;

      DrawText('grab a text particle by pressing with the mouse and throw it by releasing', 10, 10, 10, DARKGRAY);
      DrawText('slice a text particle by pressing it with the mouse right button', 10, 30, 10, DARKGRAY);
      DrawText('shatter a text particle keeping left shift pressed and pressing it with the mouse right button', 10, 50, 10, DARKGRAY);
      DrawText('glue text particles by grabbing than and keeping left control pressed', 10, 70, 10, DARKGRAY);
      DrawText('1 to 6 to reset', 10, 90, 10, DARKGRAY);
      DrawText('when you have only one text particle, you can slice it by pressing a char', 10, 110, 10, DARKGRAY);
      DrawText(PChar(Format('TEXT PARTICLE COUNT: %d', [particleCount])), 10, GetScreenHeight - 30, 20, BLACK);

    EndDrawing();
  end;

  CloseWindow();
end.
