program core_keyboard_testbed;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  KEY_REC_SPACING = 4;

function GetKeyText(key: integer): PChar;
begin
  case key of
    KEY_APOSTROPHE: Result := '''';
    KEY_COMMA: Result := ',';
    KEY_MINUS: Result := '-';
    KEY_PERIOD: Result := '.';
    KEY_SLASH: Result := '/';
    KEY_ZERO: Result := '0';
    KEY_ONE: Result := '1';
    KEY_TWO: Result := '2';
    KEY_THREE: Result := '3';
    KEY_FOUR: Result := '4';
    KEY_FIVE: Result := '5';
    KEY_SIX: Result := '6';
    KEY_SEVEN: Result := '7';
    KEY_EIGHT: Result := '8';
    KEY_NINE: Result := '9';
    KEY_SEMICOLON: Result := ';';
    KEY_EQUAL: Result := '=';
    KEY_A: Result := 'A';
    KEY_B: Result := 'B';
    KEY_C: Result := 'C';
    KEY_D: Result := 'D';
    KEY_E: Result := 'E';
    KEY_F: Result := 'F';
    KEY_G: Result := 'G';
    KEY_H: Result := 'H';
    KEY_I: Result := 'I';
    KEY_J: Result := 'J';
    KEY_K: Result := 'K';
    KEY_L: Result := 'L';
    KEY_M: Result := 'M';
    KEY_N: Result := 'N';
    KEY_O: Result := 'O';
    KEY_P: Result := 'P';
    KEY_Q: Result := 'Q';
    KEY_R: Result := 'R';
    KEY_S: Result := 'S';
    KEY_T: Result := 'T';
    KEY_U: Result := 'U';
    KEY_V: Result := 'V';
    KEY_W: Result := 'W';
    KEY_X: Result := 'X';
    KEY_Y: Result := 'Y';
    KEY_Z: Result := 'Z';
    KEY_LEFT_BRACKET: Result := '[';
    KEY_BACKSLASH: Result := '\';
    KEY_RIGHT_BRACKET: Result := ']';
    KEY_GRAVE: Result := '`';
    KEY_SPACE: Result := 'SPACE';
    KEY_ESCAPE: Result := 'ESC';
    KEY_ENTER: Result := 'ENTER';
    KEY_TAB: Result := 'TAB';
    KEY_BACKSPACE: Result := 'BACK';
    KEY_INSERT: Result := 'INS';
    KEY_DELETE: Result := 'DEL';
    KEY_RIGHT: Result := 'RIGHT';
    KEY_LEFT: Result := 'LEFT';
    KEY_DOWN: Result := 'DOWN';
    KEY_UP: Result := 'UP';
    KEY_PAGE_UP: Result := 'PGUP';
    KEY_PAGE_DOWN: Result := 'PGDOWN';
    KEY_HOME: Result := 'HOME';
    KEY_END: Result := 'END';
    KEY_CAPS_LOCK: Result := 'CAPS';
    KEY_SCROLL_LOCK: Result := 'LOCK';
    KEY_NUM_LOCK: Result := 'NUMLOCK';
    KEY_PRINT_SCREEN: Result := 'PRINTSCR';
    KEY_PAUSE: Result := 'PAUSE';
    KEY_F1: Result := 'F1';
    KEY_F2: Result := 'F2';
    KEY_F3: Result := 'F3';
    KEY_F4: Result := 'F4';
    KEY_F5: Result := 'F5';
    KEY_F6: Result := 'F6';
    KEY_F7: Result := 'F7';
    KEY_F8: Result := 'F8';
    KEY_F9: Result := 'F9';
    KEY_F10: Result := 'F10';
    KEY_F11: Result := 'F11';
    KEY_F12: Result := 'F12';
    KEY_LEFT_SHIFT: Result := 'LSHIFT';
    KEY_LEFT_CONTROL: Result := 'LCTRL';
    KEY_LEFT_ALT: Result := 'LALT';
    KEY_LEFT_SUPER: Result := 'WIN';
    KEY_RIGHT_SHIFT: Result := 'RSHIFT';
    KEY_RIGHT_CONTROL: Result := 'RCTRL';
    KEY_RIGHT_ALT: Result := 'ALTGR';
    KEY_RIGHT_SUPER: Result := 'RSUPER';
    KEY_KB_MENU: Result := 'KBMENU';
  else
    Result := '';
  end;
end;

procedure GuiKeyboardKey(bounds: TRectangle; key: integer);
var
  keyText: PChar;
begin
  if key = KEY_NULL then
    DrawRectangleLinesEx(bounds, 2.0, LIGHTGRAY)
  else
  begin
    keyText := GetKeyText(key);
    if IsKeyDown(key) then
    begin
      DrawRectangleLinesEx(bounds, 2.0, MAROON);
      DrawText(keyText, Trunc(bounds.x) + 4, Trunc(bounds.y) + 4, 10, MAROON);
    end
    else
    begin
      DrawRectangleLinesEx(bounds, 2.0, DARKGRAY);
      DrawText(keyText, Trunc(bounds.x) + 4, Trunc(bounds.y) + 4, 10, DARKGRAY);
    end;
  end;

  if CheckCollisionPointRec(GetMousePosition(), bounds) then
  begin
    DrawRectangleRec(bounds, Fade(RED, 0.2));
    DrawRectangleLinesEx(bounds, 3.0, RED);
  end;
end;

var
  line01Keys, line02Keys, line03Keys, line04Keys, line05Keys, line06Keys: array of integer;
  line01KeyWidths, line02KeyWidths, line03KeyWidths, line04KeyWidths, line05KeyWidths, line06KeyWidths: array of integer;
  keyboardOffset: TVector2;
  recOffsetX: single;
  i: integer;
  key: integer;
  ch: integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - keyboard testbed');
  SetExitKey(KEY_NULL);

  // Initialize line01Keys
  SetLength(line01Keys, 15);
  SetLength(line01KeyWidths, 15);
  line01Keys[0] := KEY_ESCAPE; line01Keys[1] := KEY_F1; line01Keys[2] := KEY_F2;
  line01Keys[3] := KEY_F3; line01Keys[4] := KEY_F4; line01Keys[5] := KEY_F5;
  line01Keys[6] := KEY_F6; line01Keys[7] := KEY_F7; line01Keys[8] := KEY_F8;
  line01Keys[9] := KEY_F9; line01Keys[10] := KEY_F10; line01Keys[11] := KEY_F11;
  line01Keys[12] := KEY_F12; line01Keys[13] := KEY_PRINT_SCREEN; line01Keys[14] := KEY_PAUSE;
  for i := 0 to 14 do line01KeyWidths[i] := 45;
  line01KeyWidths[13] := 62;

  // Initialize line02Keys
  SetLength(line02Keys, 15);
  SetLength(line02KeyWidths, 15);
  line02Keys[0] := KEY_GRAVE; line02Keys[1] := KEY_ONE; line02Keys[2] := KEY_TWO;
  line02Keys[3] := KEY_THREE; line02Keys[4] := KEY_FOUR; line02Keys[5] := KEY_FIVE;
  line02Keys[6] := KEY_SIX; line02Keys[7] := KEY_SEVEN; line02Keys[8] := KEY_EIGHT;
  line02Keys[9] := KEY_NINE; line02Keys[10] := KEY_ZERO; line02Keys[11] := KEY_MINUS;
  line02Keys[12] := KEY_EQUAL; line02Keys[13] := KEY_BACKSPACE; line02Keys[14] := KEY_DELETE;
  for i := 0 to 14 do line02KeyWidths[i] := 45;
  line02KeyWidths[0] := 25;
  line02KeyWidths[13] := 82;

  // Initialize line03Keys
  SetLength(line03Keys, 15);
  SetLength(line03KeyWidths, 15);
  line03Keys[0] := KEY_TAB; line03Keys[1] := KEY_Q; line03Keys[2] := KEY_W;
  line03Keys[3] := KEY_E; line03Keys[4] := KEY_R; line03Keys[5] := KEY_T;
  line03Keys[6] := KEY_Y; line03Keys[7] := KEY_U; line03Keys[8] := KEY_I;
  line03Keys[9] := KEY_O; line03Keys[10] := KEY_P; line03Keys[11] := KEY_LEFT_BRACKET;
  line03Keys[12] := KEY_RIGHT_BRACKET; line03Keys[13] := KEY_BACKSLASH; line03Keys[14] := KEY_INSERT;
  for i := 0 to 14 do line03KeyWidths[i] := 45;
  line03KeyWidths[0] := 50;
  line03KeyWidths[13] := 57;

  // Initialize line04Keys
  SetLength(line04Keys, 14);
  SetLength(line04KeyWidths, 14);
  line04Keys[0] := KEY_CAPS_LOCK; line04Keys[1] := KEY_A; line04Keys[2] := KEY_S;
  line04Keys[3] := KEY_D; line04Keys[4] := KEY_F; line04Keys[5] := KEY_G;
  line04Keys[6] := KEY_H; line04Keys[7] := KEY_J; line04Keys[8] := KEY_K;
  line04Keys[9] := KEY_L; line04Keys[10] := KEY_SEMICOLON; line04Keys[11] := KEY_APOSTROPHE;
  line04Keys[12] := KEY_ENTER; line04Keys[13] := KEY_PAGE_UP;
  for i := 0 to 13 do line04KeyWidths[i] := 45;
  line04KeyWidths[0] := 68;
  line04KeyWidths[12] := 88;

  // Initialize line05Keys
  SetLength(line05Keys, 14);
  SetLength(line05KeyWidths, 14);
  line05Keys[0] := KEY_LEFT_SHIFT; line05Keys[1] := KEY_Z; line05Keys[2] := KEY_X;
  line05Keys[3] := KEY_C; line05Keys[4] := KEY_V; line05Keys[5] := KEY_B;
  line05Keys[6] := KEY_N; line05Keys[7] := KEY_M; line05Keys[8] := KEY_COMMA;
  line05Keys[9] := KEY_PERIOD; line05Keys[10] := KEY_SLASH; line05Keys[11] := KEY_RIGHT_SHIFT;
  line05Keys[12] := KEY_UP; line05Keys[13] := KEY_PAGE_DOWN;
  for i := 0 to 13 do line05KeyWidths[i] := 45;
  line05KeyWidths[0] := 80;
  line05KeyWidths[11] := 76;

  // Initialize line06Keys
  SetLength(line06Keys, 11);
  SetLength(line06KeyWidths, 11);
  line06Keys[0] := KEY_LEFT_CONTROL; line06Keys[1] := KEY_LEFT_SUPER;
  line06Keys[2] := KEY_LEFT_ALT; line06Keys[3] := KEY_SPACE;
  line06Keys[4] := KEY_RIGHT_ALT; line06Keys[5] := KEY_NULL;
  line06Keys[6] := KEY_NULL; line06Keys[7] := KEY_RIGHT_CONTROL;
  line06Keys[8] := KEY_LEFT; line06Keys[9] := KEY_DOWN; line06Keys[10] := KEY_RIGHT;
  for i := 0 to 10 do line06KeyWidths[i] := 45;
  line06KeyWidths[0] := 80;
  line06KeyWidths[3] := 208;
  line06KeyWidths[7] := 60;

  keyboardOffset := Vector2Create(26, 80);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin

    key := GetKeyPressed();
    if key > 0 then TraceLog(LOG_INFO, 'KEYBOARD TESTBED: KEY PRESSED:    %d', key);


    ch := GetCharPressed();
    if ch > 0 then TraceLog(LOG_INFO, 'KEYBOARD TESTBED: CHAR PRESSED:   %c (%d)', ch, ch);

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawText('KEYBOARD LAYOUT: ENG-US', 26, 38, 20, LIGHTGRAY);

      recOffsetX := 0;
      for i := 0 to 14 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y, line01KeyWidths[i], 30.0), line01Keys[i]);
        recOffsetX := recOffsetX + line01KeyWidths[i] + KEY_REC_SPACING;
      end;

      recOffsetX := 0;
      for i := 0 to 14 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y + 30 + KEY_REC_SPACING, line02KeyWidths[i], 38.0), line02Keys[i]);
        recOffsetX := recOffsetX + line02KeyWidths[i] + KEY_REC_SPACING;
      end;

      recOffsetX := 0;
      for i := 0 to 14 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y + 30 + 38 + KEY_REC_SPACING * 2, line03KeyWidths[i], 38.0), line03Keys[i]);
        recOffsetX := recOffsetX + line03KeyWidths[i] + KEY_REC_SPACING;
      end;

      recOffsetX := 0;
      for i := 0 to 13 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y + 30 + 38 * 2 + KEY_REC_SPACING * 3, line04KeyWidths[i], 38.0), line04Keys[i]);
        recOffsetX := recOffsetX + line04KeyWidths[i] + KEY_REC_SPACING;
      end;

      recOffsetX := 0;
      for i := 0 to 13 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y + 30 + 38 * 3 + KEY_REC_SPACING * 4, line05KeyWidths[i], 38.0), line05Keys[i]);
        recOffsetX := recOffsetX + line05KeyWidths[i] + KEY_REC_SPACING;
      end;

      recOffsetX := 0;
      for i := 0 to 10 do
      begin
        GuiKeyboardKey(RectangleCreate(keyboardOffset.x + recOffsetX, keyboardOffset.y + 30 + 38 * 4 + KEY_REC_SPACING * 5, line06KeyWidths[i], 38.0), line06Keys[i]);
        recOffsetX := recOffsetX + line06KeyWidths[i] + KEY_REC_SPACING;
      end;

    EndDrawing();
  end;

  CloseWindow();
end.
