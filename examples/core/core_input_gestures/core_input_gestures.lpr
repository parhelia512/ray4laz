program core_input_gestures;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_GESTURE_STRINGS = 20;

var
  touchPosition: TVector2;
  touchArea: TRectangle;
  gesturesCount: integer;
  gestureStrings: array[0..MAX_GESTURE_STRINGS - 1] of string;//[32];
  currentGesture, lastGesture: integer;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - input gestures');

  touchPosition := Vector2Create(0, 0);
  touchArea := RectangleCreate(220, 10, screenWidth - 230.0, screenHeight - 20.0);
  gesturesCount := 0;

  for i := 0 to MAX_GESTURE_STRINGS - 1 do
    gestureStrings[i] := '';

  currentGesture := GESTURE_NONE;
  lastGesture := GESTURE_NONE;

  // SetGesturesEnabled(0b0000000000001001); // Включить только некоторые жесты

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Обновление
    lastGesture := currentGesture;
    currentGesture := GetGestureDetected();
    touchPosition := GetTouchPosition(0);

    if CheckCollisionPointRec(touchPosition, touchArea) and (currentGesture <> GESTURE_NONE) then
    begin
      if currentGesture <> lastGesture then
      begin
        // Сохраняем строку жеста
        case currentGesture of
          GESTURE_TAP: gestureStrings[gesturesCount] := 'GESTURE TAP';
          GESTURE_DOUBLETAP: gestureStrings[gesturesCount] := 'GESTURE DOUBLETAP';
          GESTURE_HOLD: gestureStrings[gesturesCount] := 'GESTURE HOLD';
          GESTURE_DRAG: gestureStrings[gesturesCount] := 'GESTURE DRAG';
          GESTURE_SWIPE_RIGHT: gestureStrings[gesturesCount] := 'GESTURE SWIPE RIGHT';
          GESTURE_SWIPE_LEFT: gestureStrings[gesturesCount] := 'GESTURE SWIPE LEFT';
          GESTURE_SWIPE_UP: gestureStrings[gesturesCount] := 'GESTURE SWIPE UP';
          GESTURE_SWIPE_DOWN: gestureStrings[gesturesCount] := 'GESTURE SWIPE DOWN';
          GESTURE_PINCH_IN: gestureStrings[gesturesCount] := 'GESTURE PINCH IN';
          GESTURE_PINCH_OUT: gestureStrings[gesturesCount] := 'GESTURE PINCH OUT';
        end;

        Inc(gesturesCount);

        // Сброс строк жестов
        if gesturesCount >= MAX_GESTURE_STRINGS then
        begin
          for i := 0 to MAX_GESTURE_STRINGS - 1 do
            gestureStrings[i] := '';
          gesturesCount := 0;
        end;
      end;
    end;

    // Отрисовка
    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawRectangleRec(touchArea, GRAY);
      DrawRectangle(225, 15, screenWidth - 240, screenHeight - 30, RAYWHITE);

      DrawText('GESTURES TEST AREA', screenWidth - 270, screenHeight - 40, 20, Fade(GRAY, 0.5));

      for i := 0 to gesturesCount - 1 do
      begin
        if i mod 2 = 0 then
          DrawRectangle(10, 30 + 20 * i, 200, 20, Fade(LIGHTGRAY, 0.5))
        else
          DrawRectangle(10, 30 + 20 * i, 200, 20, Fade(LIGHTGRAY, 0.3));

        if i < gesturesCount - 1 then
          DrawText(PChar(gestureStrings[i]), 35, 36 + 20 * i, 10, DARKGRAY)
        else
          DrawText(PChar(gestureStrings[i]), 35, 36 + 20 * i, 10, MAROON);
      end;

      DrawRectangleLines(10, 29, 200, screenHeight - 50, GRAY);
      DrawText('DETECTED GESTURES', 50, 15, 10, GRAY);

      if currentGesture <> GESTURE_NONE then
        DrawCircleV(touchPosition, 30, MAROON);

    EndDrawing();
  end;

  CloseWindow();
end.
