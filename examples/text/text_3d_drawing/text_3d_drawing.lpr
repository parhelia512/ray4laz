program text_3d_drawing;

{$mode objfpc}{$H+}

uses
  cmem, math, raylib, raymath, rlgl, sysUtils;

const
  GLSL_VERSION = 330;
  LETTER_BOUNDRY_SIZE = 0.25;
  TEXT_MAX_LAYERS = 32;
  LETTER_BOUNDRY_COLOR: TColorB = (r: 238; g: 130; b: 238; a: 255); // VIOLET

var
  SHOW_LETTER_BOUNDRY: boolean = false;
  SHOW_TEXT_BOUNDRY: boolean = false;
  ray: TRay;
  Collision: TRayCollision;


type
  // Configuration structure for waving the text
  PWaveTextConfig = ^TWaveTextConfig;
  TWaveTextConfig = record
    waveRange: TVector3;
    waveSpeed: TVector3;
    waveOffset: TVector3;
  end;

//--------------------------------------------------------------------------------------
// Module Functions Declaration
//--------------------------------------------------------------------------------------

// Draw a codepoint in 3D space
procedure DrawTextCodepoint3D(font: TFont; codepoint: integer; position: TVector3; fontSize: single; backface: boolean; tint: TColorB);
var
  index: integer;
  scale: single;
  srcRec: TRectangle;
  width, height: single;
  x, y, z: single;
  tx, ty, tw, th: single;
begin
  index := GetGlyphIndex(font, codepoint);
  scale := fontSize / font.baseSize;

  position.x := position.x + (font.glyphs[index].offsetX - font.glyphPadding) * scale;
  position.z := position.z + (font.glyphs[index].offsetY - font.glyphPadding) * scale;

  srcRec.x := font.recs[index].x - font.glyphPadding;
  srcRec.y := font.recs[index].y - font.glyphPadding;
  srcRec.width := font.recs[index].width + 2 * font.glyphPadding;
  srcRec.height := font.recs[index].height + 2 * font.glyphPadding;

  width := (font.recs[index].width + 2 * font.glyphPadding) * scale;
  height := (font.recs[index].height + 2 * font.glyphPadding) * scale;

  if font.texture.id > 0 then
  begin
    x := 0.0;
    y := 0.0;
    z := 0.0;

    tx := srcRec.x / font.texture.width;
    ty := srcRec.y / font.texture.height;
    tw := (srcRec.x + srcRec.width) / font.texture.width;
    th := (srcRec.y + srcRec.height) / font.texture.height;

    if SHOW_LETTER_BOUNDRY then
      DrawCubeWiresV(Vector3Create(position.x + width/2, position.y, position.z + height/2),
                     Vector3Create(width, LETTER_BOUNDRY_SIZE, height),
                     LETTER_BOUNDRY_COLOR);

    rlCheckRenderBatchLimit(4 + 4 * Ord(backface));
    rlSetTexture(font.texture.id);

    rlPushMatrix;
      rlTranslatef(position.x, position.y, position.z);

      rlBegin(RL_QUADS);
        rlColor4ub(tint.r, tint.g, tint.b, tint.a);

        // Front Face
        rlNormal3f(0.0, 1.0, 0.0);
        rlTexCoord2f(tx, ty); rlVertex3f(x,      y, z);
        rlTexCoord2f(tx, th); rlVertex3f(x,      y, z + height);
        rlTexCoord2f(tw, th); rlVertex3f(x + width, y, z + height);
        rlTexCoord2f(tw, ty); rlVertex3f(x + width, y, z);

        if backface then
        begin
          // Back Face
          rlNormal3f(0.0, -1.0, 0.0);
          rlTexCoord2f(tx, ty); rlVertex3f(x,      y, z);
          rlTexCoord2f(tw, ty); rlVertex3f(x + width, y, z);
          rlTexCoord2f(tw, th); rlVertex3f(x + width, y, z + height);
          rlTexCoord2f(tx, th); rlVertex3f(x,      y, z + height);
        end;
      rlEnd;
    rlPopMatrix;

    rlSetTexture(0);
  end;
end;

// Draw a 2D text in 3D space
procedure DrawText3D(font: TFont; text: PChar; position: TVector3; fontSize, fontSpacing, lineSpacing: single; backface: boolean; tint: TColorB);
var
  length, i: integer;
  textOffsetY, textOffsetX: single;
  scale: single;
  codepointByteCount: integer;
  codepoint: integer;
  index: integer;
begin
  length := TextLength(text);
  textOffsetY := 0.0;
  textOffsetX := 0.0;
  scale := fontSize / font.baseSize;

  i := 0;
  while i < length do
  begin
    codepointByteCount := 0;
    codepoint := GetCodepoint(@text[i], @codepointByteCount);
    index := GetGlyphIndex(font, codepoint);

    if codepoint = $3F then codepointByteCount := 1;

    if codepoint = 10 then // '\n'
    begin
      textOffsetY := textOffsetY + fontSize + lineSpacing;
      textOffsetX := 0.0;
    end
    else
    begin
      if (codepoint <> 32) and (codepoint <> 9) then // ' ' and '\t'
      begin
        DrawTextCodepoint3D(font, codepoint,
          Vector3Create(position.x + textOffsetX, position.y, position.z + textOffsetY),
          fontSize, backface, tint);
      end;

      if font.glyphs[index].advanceX = 0 then
        textOffsetX := textOffsetX + font.recs[index].width * scale + fontSpacing
      else
        textOffsetX := textOffsetX + font.glyphs[index].advanceX * scale + fontSpacing;
    end;

    i := i + codepointByteCount;
  end;
end;

// Draw a 2D text in 3D space and wave the parts that start with '~~' and end with '~~'
procedure DrawTextWave3D(font: TFont; text: PChar; position: TVector3; fontSize, fontSpacing, lineSpacing: single; backface: boolean; config: PWaveTextConfig; time: single; tint: TColorB);
var
  length, i, k: integer;
  textOffsetY, textOffsetX: single;
  scale: single;
  codepointByteCount: integer;
  codepoint: integer;
  index: integer;
  wave: boolean;
  pos: TVector3;
begin
  length := TextLength(text);
  textOffsetY := 0.0;
  textOffsetX := 0.0;
  scale := fontSize / font.baseSize;
  wave := false;

  i := 0;
  k := 0;
  while i < length do
  begin
    codepointByteCount := 0;
    codepoint := GetCodepoint(@text[i], @codepointByteCount);
    index := GetGlyphIndex(font, codepoint);

    if codepoint = $3F then codepointByteCount := 1;

    if codepoint = 10 then // '\n'
    begin
      textOffsetY := textOffsetY + fontSize + lineSpacing;
      textOffsetX := 0.0;
      k := 0;
    end
    else if codepoint = 126 then // '~'
    begin
      if GetCodepoint(@text[i+1], @codepointByteCount) = 126 then
      begin
        codepointByteCount := codepointByteCount + 1;
        wave := not wave;
      end;
    end
    else
    begin
      if (codepoint <> 32) and (codepoint <> 9) then // ' ' and '\t'
      begin
        pos := position;
        if wave then
        begin
          pos.x := pos.x + sin(time * config^.waveSpeed.x - k * config^.waveOffset.x) * config^.waveRange.x;
          pos.y := pos.y + sin(time * config^.waveSpeed.y - k * config^.waveOffset.y) * config^.waveRange.y;
          pos.z := pos.z + sin(time * config^.waveSpeed.z - k * config^.waveOffset.z) * config^.waveRange.z;
        end;

        DrawTextCodepoint3D(font, codepoint,
          Vector3Create(pos.x + textOffsetX, pos.y, pos.z + textOffsetY),
          fontSize, backface, tint);
      end;

      if font.glyphs[index].advanceX = 0 then
        textOffsetX := textOffsetX + font.recs[index].width * scale + fontSpacing
      else
        textOffsetX := textOffsetX + font.glyphs[index].advanceX * scale + fontSpacing;
    end;

    i := i + codepointByteCount;
    k := k + 1;
  end;
end;

// Measure a text in 3D ignoring the '~~' chars
function MeasureTextWave3D(font: TFont; text: PChar; fontSize, fontSpacing, lineSpacing: single): TVector3;
var
  len, tempLen, lenCounter, i, next, index: integer;
  letter: integer;
  tempTextWidth, textWidth, textHeight: single;
  scale: single;
  vec: TVector3;
begin
  len := TextLength(text);
  tempLen := 0;
  lenCounter := 0;
  tempTextWidth := 0.0;
  textWidth := 0.0;
  scale := fontSize / font.baseSize;
  textHeight := scale;

  i := 0;
  while i < len do
  begin
    next := 0;
    letter := GetCodepoint(@text[i], @next);
    index := GetGlyphIndex(font, letter);

    if letter = $3F then next := 1;
    i := i + next - 1;

    if letter <> 10 then // '\n'
    begin
      if (letter = 126) and (GetCodepoint(@text[i+1], @next) = 126) then // '~~'
      begin
        i := i + 1;
      end
      else
      begin
        lenCounter := lenCounter + 1;
        if font.glyphs[index].advanceX <> 0 then
          textWidth := textWidth + font.glyphs[index].advanceX * scale
        else
          textWidth := textWidth + (font.recs[index].width + font.glyphs[index].offsetX) * scale;
      end;
    end
    else
    begin
      if tempTextWidth < textWidth then tempTextWidth := textWidth;
      lenCounter := 0;
      textWidth := 0.0;
      textHeight := textHeight + fontSize + lineSpacing;
    end;

    if tempLen < lenCounter then tempLen := lenCounter;
    i := i + 1;
  end;

  if tempTextWidth < textWidth then tempTextWidth := textWidth;

  vec.x := tempTextWidth + (tempLen - 1) * fontSpacing;
  vec.y := 0.25;
  vec.z := textHeight;
  Result := vec;
end;

// Generates a nice color with a random hue
function GenerateRandomColor(s, v: single): TColorB;
const
  Phi = 0.618033988749895;
var
  h: single;
begin
  h := GetRandomValue(0, 360);
  h := FMod(h + h * Phi, 360.0);
  Result := ColorFromHSV(h, s, v);
end;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
var
  spin: boolean = true;
  multicolor: boolean = false;
  camera: TCamera3D;
  camera_mode: integer;
  cubePosition, cubeSize: TVector3;
  font: TFont;
  fontSize, fontSpacing, lineSpacing: single;
  text: array[0..63] of char;
  tbox: TVector3;
  layers, quads: integer;
  layerDistance: single;
  wcfg: TWaveTextConfig;
  time: single;
  light, dark: TColorB;
  alphaDiscard: TShader;
  multi: array[0..TEXT_MAX_LAYERS-1] of TColorB;
  ch: integer;
  len: integer;
  droppedFiles: TFilePathList;
  i: integer;
  opt: PChar;
  m: TVector2;
  pos: TVector3;
  width: integer;
  tmp: PChar;
  slb: boolean;

begin
  // Initialization
  SetConfigFlags(FLAG_MSAA_4X_HINT or FLAG_VSYNC_HINT);
  InitWindow(800, 450, 'raylib [text] example - 3d drawing');

  spin := true;
  multicolor := false;

  // Camera setup
  camera.position := Vector3Create(-10.0, 15.0, -10.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  camera_mode := CAMERA_ORBITAL;

  cubePosition := Vector3Create(0.0, 1.0, 0.0);
  cubeSize := Vector3Create(2.0, 2.0, 2.0);

  // Use the default font
  font := GetFontDefault();
  fontSize := 0.8;
  fontSpacing := 0.05;
  lineSpacing := -0.1;

  // Set the text
  StrPCopy(text, 'Hello ~~World~~ in 3D!');
  tbox := Vector3Create(0, 0, 0);
  layers := 1;
  quads := 0;
  layerDistance := 0.01;

  wcfg.waveSpeed := Vector3Create(3.0, 3.0, 0.5);
  wcfg.waveOffset := Vector3Create(0.35, 0.35, 0.35);
  wcfg.waveRange := Vector3Create(0.45, 0.45, 0.45);

  time := 0.0;

  // Setup a light and dark color
  light := MAROON;
  dark := RED;

  // Load the alpha discard shader
  alphaDiscard := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/alpha_discard.fs', GLSL_VERSION)));

  // Fill color array
  for i := 0 to TEXT_MAX_LAYERS - 1 do
  begin
    multi[i] := GenerateRandomColor(0.5, 0.8);
    multi[i].a := GetRandomValue(0, 255);
  end;

  DisableCursor;
  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    UpdateCamera(@camera, camera_mode);

    // Handle font files dropped
    if IsFileDropped() then
    begin
      droppedFiles := LoadDroppedFiles();

      if droppedFiles.count > 0 then
      begin
        if IsFileExtension(droppedFiles.paths[0], '.ttf') then
        begin
          UnloadFont(font);
          font := LoadFontEx(droppedFiles.paths[0], Trunc(fontSize), nil, 0);
        end
        else if IsFileExtension(droppedFiles.paths[0], '.fnt') then
        begin
          UnloadFont(font);
          font := LoadFont(droppedFiles.paths[0]);
          fontSize := font.baseSize;
        end;
      end;

      UnloadDroppedFiles(droppedFiles);
    end;

    // Handle Events
    if IsKeyPressed(KEY_F1) then SHOW_LETTER_BOUNDRY := not SHOW_LETTER_BOUNDRY;
    if IsKeyPressed(KEY_F2) then SHOW_TEXT_BOUNDRY := not SHOW_TEXT_BOUNDRY;
    if IsKeyPressed(KEY_F3) then
    begin
      spin := not spin;
      camera := Default(TCamera3D);
      camera.target := Vector3Create(0.0, 0.0, 0.0);
      camera.up := Vector3Create(0.0, 1.0, 0.0);
      camera.fovy := 45.0;
      camera.projection := CAMERA_PERSPECTIVE;

      if spin then
      begin
        camera.position := Vector3Create(-10.0, 15.0, -10.0);
        camera_mode := CAMERA_ORBITAL;
      end
      else
      begin
        camera.position := Vector3Create(10.0, 10.0, -10.0);
        camera_mode := CAMERA_FREE;
      end;
    end;

    // Handle clicking the cube
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
      ray := GetScreenToWorldRay(GetMousePosition(), camera);
      collision := GetRayCollisionBox(ray,
        BoundingBoxCreate(
          Vector3Create(cubePosition.x - cubeSize.x/2, cubePosition.y - cubeSize.y/2, cubePosition.z - cubeSize.z/2),
          Vector3Create(cubePosition.x + cubeSize.x/2, cubePosition.y + cubeSize.y/2, cubePosition.z + cubeSize.z/2)
        )
      );
      if collision.hit then
      begin
        light := GenerateRandomColor(0.5, 0.78);
        dark := GenerateRandomColor(0.4, 0.58);
      end;
    end;

    // Handle text layers changes
    if IsKeyPressed(KEY_HOME) then
    begin
      if layers > 1 then Dec(layers);
    end
    else if IsKeyPressed(KEY_END) then
    begin
      if layers < TEXT_MAX_LAYERS then Inc(layers);
    end;

    // Handle text changes
    if IsKeyPressed(KEY_LEFT) then fontSize := fontSize - 0.5
    else if IsKeyPressed(KEY_RIGHT) then fontSize := fontSize + 0.5
    else if IsKeyPressed(KEY_UP) then fontSpacing := fontSpacing - 0.1
    else if IsKeyPressed(KEY_DOWN) then fontSpacing := fontSpacing + 0.1
    else if IsKeyPressed(KEY_PAGE_UP) then lineSpacing := lineSpacing - 0.1
    else if IsKeyPressed(KEY_PAGE_DOWN) then lineSpacing := lineSpacing + 0.1
    else if IsKeyDown(KEY_INSERT) then layerDistance := layerDistance - 0.001
    else if IsKeyDown(KEY_DELETE) then layerDistance := layerDistance + 0.001
    else if IsKeyPressed(KEY_TAB) then
    begin
      multicolor := not multicolor;
      if multicolor then
      begin
        for i := 0 to TEXT_MAX_LAYERS - 1 do
        begin
          multi[i] := GenerateRandomColor(0.5, 0.8);
          multi[i].a := GetRandomValue(0, 255);
        end;
      end;
    end;

    // Handle text input
    ch := GetCharPressed();
    if IsKeyPressed(KEY_BACKSPACE) then
    begin
      len := TextLength(text);
      if len > 0 then text[len - 1] := #0;
    end
    else if IsKeyPressed(KEY_ENTER) then
    begin
      len := TextLength(text);
      if len < SizeOf(text) - 1 then
      begin
        text[len] := #10;
        text[len+1] := #0;
      end;
    end
    else
    begin
      len := TextLength(text);
      if (len < SizeOf(text) - 1) and (ch >= 32) then
      begin
        text[len] := Char(ch);
        text[len+1] := #0;
      end;
    end;

    // Measure 3D text so we can center it
    tbox := MeasureTextWave3D(font, text, fontSize, fontSpacing, lineSpacing);

    quads := 0;
    time := time + GetFrameTime();

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawCubeV(cubePosition, cubeSize, dark);
        DrawCubeWires(cubePosition, 2.1, 2.1, 2.1, light);

        DrawGrid(10, 2.0);

        BeginShaderMode(alphaDiscard);
          // Draw the 3D text above the red cube
          rlPushMatrix;
            rlRotatef(90.0, 1.0, 0.0, 0.0);
            rlRotatef(90.0, 0.0, 0.0, -1.0);

            for i := 0 to layers - 1 do
            begin
              if multicolor then
                DrawTextWave3D(font, text,
                  Vector3Create(-tbox.x/2.0, layerDistance * i, -4.5),
                  fontSize, fontSpacing, lineSpacing, true, @wcfg, time, multi[i])
              else
                DrawTextWave3D(font, text,
                  Vector3Create(-tbox.x/2.0, layerDistance * i, -4.5),
                  fontSize, fontSpacing, lineSpacing, true, @wcfg, time, light);
            end;

            // Draw the text boundry if set
            if SHOW_TEXT_BOUNDRY then
              DrawCubeWiresV(Vector3Create(0.0, 0.0, -4.5 + tbox.z/2), tbox, dark);
          rlPopMatrix;

          // Don't draw the letter boundries for the 3D text below
          slb := SHOW_LETTER_BOUNDRY;
          SHOW_LETTER_BOUNDRY := false;

          // Draw 3D options (use default font)
          rlPushMatrix;
            rlRotatef(180.0, 0.0, 1.0, 0.0);
            opt := PChar(Format('< SIZE: %2.1f >', [fontSize]));
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos := Vector3Create(-m.x/2.0, 0.01, 2.0);
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, BLUE);
            pos.z := pos.z + 0.5 + m.y;

            opt := PChar(Format('< SPACING: %2.1f >', [fontSpacing]));
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos.x := -m.x/2.0;
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, BLUE);
            pos.z := pos.z + 0.5 + m.y;

            opt := PChar(Format('< LINE: %2.1f >', [lineSpacing]));
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos.x := -m.x/2.0;
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, BLUE);
            pos.z := pos.z + 0.5 + m.y;

            if slb then
              opt := '< LBOX: ON >'
            else
              opt := '< LBOX: OFF >';
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos.x := -m.x/2.0;
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, RED);
            pos.z := pos.z + 0.5 + m.y;

            if SHOW_TEXT_BOUNDRY then
              opt := '< TBOX: ON >'
            else
              opt := '< TBOX: OFF >';
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos.x := -m.x/2.0;
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, RED);
            pos.z := pos.z + 0.5 + m.y;

            opt := PChar(Format('< LAYER DISTANCE: %.3f >', [layerDistance]));
            quads := quads + TextLength(opt);
            m := MeasureTextEx(GetFontDefault(), opt, 0.8, 0.1);
            pos.x := -m.x/2.0;
            DrawText3D(GetFontDefault(), opt, pos, 0.8, 0.1, 0.0, false, DARKPURPLE);
          rlPopMatrix;

          // Draw 3D info text (use default font)
          opt := 'All the text displayed here is in 3D';
          quads := quads + 36;
          m := MeasureTextEx(GetFontDefault(), opt, 1.0, 0.05);
          pos := Vector3Create(-m.x/2.0, 0.01, 2.0);
          DrawText3D(GetFontDefault(), opt, pos, 1.0, 0.05, 0.0, false, DARKBLUE);
          pos.z := pos.z + 1.5 + m.y;

          opt := 'press [Left]/[Right] to change the font size';
          quads := quads + 44;
          m := MeasureTextEx(GetFontDefault(), opt, 0.6, 0.05);
          pos.x := -m.x/2.0;
          DrawText3D(GetFontDefault(), opt, pos, 0.6, 0.05, 0.0, false, DARKBLUE);
          pos.z := pos.z + 0.5 + m.y;

          opt := 'press [Up]/[Down] to change the font spacing';
          quads := quads + 44;
          m := MeasureTextEx(GetFontDefault(), opt, 0.6, 0.05);
          pos.x := -m.x/2.0;
          DrawText3D(GetFontDefault(), opt, pos, 0.6, 0.05, 0.0, false, DARKBLUE);
          pos.z := pos.z + 0.5 + m.y;

          opt := 'press [PgUp]/[PgDown] to change the line spacing';
          quads := quads + 48;
          m := MeasureTextEx(GetFontDefault(), opt, 0.6, 0.05);
          pos.x := -m.x/2.0;
          DrawText3D(GetFontDefault(), opt, pos, 0.6, 0.05, 0.0, false, DARKBLUE);
          pos.z := pos.z + 0.5 + m.y;

          opt := 'press [F1] to toggle the letter boundry';
          quads := quads + 39;
          m := MeasureTextEx(GetFontDefault(), opt, 0.6, 0.05);
          pos.x := -m.x/2.0;
          DrawText3D(GetFontDefault(), opt, pos, 0.6, 0.05, 0.0, false, DARKBLUE);
          pos.z := pos.z + 0.5 + m.y;

          opt := 'press [F2] to toggle the text boundry';
          quads := quads + 37;
          m := MeasureTextEx(GetFontDefault(), opt, 0.6, 0.05);
          pos.x := -m.x/2.0;
          DrawText3D(GetFontDefault(), opt, pos, 0.6, 0.05, 0.0, false, DARKBLUE);

          SHOW_LETTER_BOUNDRY := slb;
        EndShaderMode;

      EndMode3D;

      // Draw 2D info text & stats
      DrawText('Drag & drop a font file to change the font!'#10 +
               'Type something, see what happens!'#10#10 +
               'Press [F3] to toggle the camera', 10, 35, 10, BLACK);

      quads := quads + TextLength(text) * 2 * layers;
      if spin then
        tmp := PChar(Format('%2i layer(s) | ORBITAL camera | %4i quads (%4i verts)', [layers, quads, quads*4]))
      else
        tmp := PChar(Format('%2i layer(s) | FREE camera | %4i quads (%4i verts)', [layers, quads, quads*4]));
      width := MeasureText(tmp, 10);
      DrawText(tmp, GetScreenWidth - 20 - width, 10, 10, DARKGREEN);

      tmp := '[Home]/[End] to add/remove 3D text layers';
      width := MeasureText(tmp, 10);
      DrawText(tmp, GetScreenWidth - 20 - width, 25, 10, DARKGRAY);

      tmp := '[Insert]/[Delete] to increase/decrease distance between layers';
      width := MeasureText(tmp, 10);
      DrawText(tmp, GetScreenWidth - 20 - width, 40, 10, DARKGRAY);

      tmp := 'click the [CUBE] for a random color';
      width := MeasureText(tmp, 10);
      DrawText(tmp, GetScreenWidth - 20 - width, 55, 10, DARKGRAY);

      tmp := '[Tab] to toggle multicolor mode';
      width := MeasureText(tmp, 10);
      DrawText(tmp, GetScreenWidth - 20 - width, 70, 10, DARKGRAY);

      DrawFPS(10, 10);

    EndDrawing();
  end;

  // De-Initialization
  UnloadFont(font);
  CloseWindow;
end.
