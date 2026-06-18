program core_input_gestures_testbed;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  GESTURE_LOG_SIZE = 20;
  MAX_TOUCH_COUNT = 32;

var
  messagePosition, lastGesturePosition, gestureLogPosition, protractorPosition: TVector2;
  lastGesture, gestureLogIndex, previousGesture, logMode: integer;
  gestureLog: array[0..GESTURE_LOG_SIZE - 1] of string;
  gestureColor: TColorB;
  logButton1, logButton2: TRectangle;
  angleLength, currentAngleDegrees: single;
  finalVector: TVector2;
  i, ii, currentGesture, fillLog, touchCount: integer;
  currentDragDegrees, currentPitchDegrees: single;
  currentAngleRadians: single;
  touchPosition: array[0..MAX_TOUCH_COUNT - 1] of TVector2;
  mousePosition: TVector2;
  logButton1Color, logButton2Color: TColorB;
  angleString: string;
  angleStringDot: integer;
  angleStringTrim: string;

function GetGestureName(gesture: integer): PChar;
begin
  case gesture of
    0: Result := 'None';
    1: Result := 'Tap';
    2: Result := 'Double Tap';
    4: Result := 'Hold';
    8: Result := 'Drag';
    16: Result := 'Swipe Right';
    32: Result := 'Swipe Left';
    64: Result := 'Swipe Up';
    128: Result := 'Swipe Down';
    256: Result := 'Pinch In';
    512: Result := 'Pinch Out';
  else
    Result := 'Unknown';
  end;
end;

function GetGestureColor(gesture: integer): TColorB;
begin
  case gesture of
    0: Result := BLACK;
    1: Result := BLUE;
    2: Result := SKYBLUE;
    4: Result := BLACK;
    8: Result := LIME;
    16, 32, 64, 128: Result := RED;
    256: Result := VIOLET;
    512: Result := ORANGE;
  else
    Result := BLACK;
  end;
end;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - input gestures testbed');

  messagePosition := Vector2Create(160, 7);
  lastGesturePosition := Vector2Create(165, 130);
  gestureLogPosition := Vector2Create(10, 10);
  protractorPosition := Vector2Create(266.0, 315.0);

  lastGesture := 0;
  gestureLogIndex := GESTURE_LOG_SIZE;
  previousGesture := 0;
  logMode := 1;
  gestureColor := ColorCreate(0, 0, 0, 255);
  logButton1 := RectangleCreate(53, 7, 48, 26);
  logButton2 := RectangleCreate(108, 7, 36, 26);

  angleLength := 90.0;
  currentAngleDegrees := 0.0;
  finalVector := Vector2Create(0.0, 0.0);

  for i := 0 to GESTURE_LOG_SIZE - 1 do
    gestureLog[i] := '';

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    currentGesture := GetGestureDetected();
    currentDragDegrees := GetGestureDragAngle();
    currentPitchDegrees := GetGesturePinchAngle();
    touchCount := GetTouchPointCount();

    // Filter last gesture
    if (currentGesture <> 0) and (currentGesture <> 4) and (currentGesture <> previousGesture) then
      lastGesture := currentGesture;

    // Handle log buttons
    if IsMouseButtonReleased(MOUSE_BUTTON_LEFT) then
    begin
      if CheckCollisionPointRec(GetMousePosition(), logButton1) then
      begin
        case logMode of
          3: logMode := 2;
          2: logMode := 3;
          1: logMode := 0;
        else
          logMode := 1;
        end;
      end
      else if CheckCollisionPointRec(GetMousePosition(), logButton2) then
      begin
        case logMode of
          3: logMode := 1;
          2: logMode := 0;
          1: logMode := 3;
        else
          logMode := 2;
        end;
      end;
    end;

    // Handle gesture log
    fillLog := 0;
    if currentGesture <> 0 then
    begin
      case logMode of
        3: if ((currentGesture <> 4) and (currentGesture <> previousGesture)) or (currentGesture < 3) then fillLog := 1;
        2: if currentGesture <> 4 then fillLog := 1;
        1: if currentGesture <> previousGesture then fillLog := 1;
      else
        fillLog := 1;
      end;
    end;

    if fillLog = 1 then
    begin
      previousGesture := currentGesture;
      gestureColor := GetGestureColor(currentGesture);
      if gestureLogIndex <= 0 then gestureLogIndex := GESTURE_LOG_SIZE;
      Dec(gestureLogIndex);
      gestureLog[gestureLogIndex] := GetGestureName(currentGesture);
    end;

    // Handle protractor angle
    if currentGesture > 255 then
      currentAngleDegrees := currentPitchDegrees
    else if currentGesture > 15 then
      currentAngleDegrees := currentDragDegrees
    else if currentGesture > 0 then
      currentAngleDegrees := 0.0;

    currentAngleRadians := (currentAngleDegrees + 90.0) * PI / 180;
    finalVector := Vector2Create(
      angleLength * Sin(currentAngleRadians) + protractorPosition.x,
      angleLength * Cos(currentAngleRadians) + protractorPosition.y
    );

    // Get touch/mouse positions
    if currentGesture <> GESTURE_NONE then
    begin
      if touchCount <> 0 then
      begin
        for i := 0 to touchCount - 1 do
          touchPosition[i] := GetTouchPosition(i);
      end
      else
        mousePosition := GetMousePosition();
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Message
      DrawText('*', Trunc(messagePosition.x) + 5, Trunc(messagePosition.y) + 5, 10, BLACK);
      DrawText('Example optimized for Web/HTML5'#10'on Smartphones with Touch Screen.',
        Trunc(messagePosition.x) + 15, Trunc(messagePosition.y) + 5, 10, BLACK);
      DrawText('*', Trunc(messagePosition.x) + 5, Trunc(messagePosition.y) + 35, 10, BLACK);
      DrawText('While running on Desktop Web Browsers,'#10'inspect and turn on Touch Emulation.',
        Trunc(messagePosition.x) + 15, Trunc(messagePosition.y) + 35, 10, BLACK);

      // Last gesture display
      DrawText('Last gesture', Trunc(lastGesturePosition.x) + 33, Trunc(lastGesturePosition.y) - 47, 20, BLACK);
      DrawText('Swipe         Tap       Pinch  Touch',
        Trunc(lastGesturePosition.x) + 17, Trunc(lastGesturePosition.y) - 18, 10, BLACK);

      // Swipe indicators
      if lastGesture = GESTURE_SWIPE_UP then
        DrawRectangle(Trunc(lastGesturePosition.x) + 20, Trunc(lastGesturePosition.y), 20, 20, RED)
      else
        DrawRectangle(Trunc(lastGesturePosition.x) + 20, Trunc(lastGesturePosition.y), 20, 20, LIGHTGRAY);

      if lastGesture = GESTURE_SWIPE_LEFT then
        DrawRectangle(Trunc(lastGesturePosition.x), Trunc(lastGesturePosition.y) + 20, 20, 20, RED)
      else
        DrawRectangle(Trunc(lastGesturePosition.x), Trunc(lastGesturePosition.y) + 20, 20, 20, LIGHTGRAY);

      if lastGesture = GESTURE_SWIPE_RIGHT then
        DrawRectangle(Trunc(lastGesturePosition.x) + 40, Trunc(lastGesturePosition.y) + 20, 20, 20, RED)
      else
        DrawRectangle(Trunc(lastGesturePosition.x) + 40, Trunc(lastGesturePosition.y) + 20, 20, 20, LIGHTGRAY);

      if lastGesture = GESTURE_SWIPE_DOWN then
        DrawRectangle(Trunc(lastGesturePosition.x) + 20, Trunc(lastGesturePosition.y) + 40, 20, 20, RED)
      else
        DrawRectangle(Trunc(lastGesturePosition.x) + 20, Trunc(lastGesturePosition.y) + 40, 20, 20, LIGHTGRAY);

      // Tap indicator
      if lastGesture = GESTURE_TAP then
        DrawCircle(Trunc(lastGesturePosition.x) + 80, Trunc(lastGesturePosition.y) + 16, 10, BLUE)
      else
        DrawCircle(Trunc(lastGesturePosition.x) + 80, Trunc(lastGesturePosition.y) + 16, 10, LIGHTGRAY);

      // Drag indicator
      if lastGesture = GESTURE_DRAG then
        DrawRing(Vector2Create(lastGesturePosition.x + 103, lastGesturePosition.y + 16), 6.0, 11.0, 0.0, 360.0, 0, LIME)
      else
        DrawRing(Vector2Create(lastGesturePosition.x + 103, lastGesturePosition.y + 16), 6.0, 11.0, 0.0, 360.0, 0, LIGHTGRAY);

      // Double tap indicator
      if lastGesture = GESTURE_DOUBLETAP then
      begin
        DrawCircle(Trunc(lastGesturePosition.x) + 80, Trunc(lastGesturePosition.y) + 43, 10, SKYBLUE);
        DrawCircle(Trunc(lastGesturePosition.x) + 103, Trunc(lastGesturePosition.y) + 43, 10, SKYBLUE);
      end
      else
      begin
        DrawCircle(Trunc(lastGesturePosition.x) + 80, Trunc(lastGesturePosition.y) + 43, 10, LIGHTGRAY);
        DrawCircle(Trunc(lastGesturePosition.x) + 103, Trunc(lastGesturePosition.y) + 43, 10, LIGHTGRAY);
      end;

      // Pinch indicators
      if lastGesture = GESTURE_PINCH_OUT then
      begin
        DrawTriangle(Vector2Create(lastGesturePosition.x + 122, lastGesturePosition.y + 16),
          Vector2Create(lastGesturePosition.x + 137, lastGesturePosition.y + 26),
          Vector2Create(lastGesturePosition.x + 137, lastGesturePosition.y + 6), ORANGE);
        DrawTriangle(Vector2Create(lastGesturePosition.x + 147, lastGesturePosition.y + 6),
          Vector2Create(lastGesturePosition.x + 147, lastGesturePosition.y + 26),
          Vector2Create(lastGesturePosition.x + 162, lastGesturePosition.y + 16), ORANGE);
      end
      else
      begin
        DrawTriangle(Vector2Create(lastGesturePosition.x + 122, lastGesturePosition.y + 16),
          Vector2Create(lastGesturePosition.x + 137, lastGesturePosition.y + 26),
          Vector2Create(lastGesturePosition.x + 137, lastGesturePosition.y + 6), LIGHTGRAY);
        DrawTriangle(Vector2Create(lastGesturePosition.x + 147, lastGesturePosition.y + 6),
          Vector2Create(lastGesturePosition.x + 147, lastGesturePosition.y + 26),
          Vector2Create(lastGesturePosition.x + 162, lastGesturePosition.y + 16), LIGHTGRAY);
      end;

      if lastGesture = GESTURE_PINCH_IN then
      begin
        DrawTriangle(Vector2Create(lastGesturePosition.x + 125, lastGesturePosition.y + 33),
          Vector2Create(lastGesturePosition.x + 125, lastGesturePosition.y + 53),
          Vector2Create(lastGesturePosition.x + 140, lastGesturePosition.y + 43), VIOLET);
        DrawTriangle(Vector2Create(lastGesturePosition.x + 144, lastGesturePosition.y + 43),
          Vector2Create(lastGesturePosition.x + 159, lastGesturePosition.y + 53),
          Vector2Create(lastGesturePosition.x + 159, lastGesturePosition.y + 33), VIOLET);
      end
      else
      begin
        DrawTriangle(Vector2Create(lastGesturePosition.x + 125, lastGesturePosition.y + 33),
          Vector2Create(lastGesturePosition.x + 125, lastGesturePosition.y + 53),
          Vector2Create(lastGesturePosition.x + 140, lastGesturePosition.y + 43), LIGHTGRAY);
        DrawTriangle(Vector2Create(lastGesturePosition.x + 144, lastGesturePosition.y + 43),
          Vector2Create(lastGesturePosition.x + 159, lastGesturePosition.y + 53),
          Vector2Create(lastGesturePosition.x + 159, lastGesturePosition.y + 33), LIGHTGRAY);
      end;

      // Touch count indicator
      for i := 0 to 3 do
      begin
        if touchCount > i then
          DrawCircle(Trunc(lastGesturePosition.x) + 180, Trunc(lastGesturePosition.y) + 7 + i * 15, 5, gestureColor)
        else
          DrawCircle(Trunc(lastGesturePosition.x) + 180, Trunc(lastGesturePosition.y) + 7 + i * 15, 5, LIGHTGRAY);
      end;

      // Gesture log
      DrawText('Log', Trunc(gestureLogPosition.x), Trunc(gestureLogPosition.y), 20, BLACK);

      ii := gestureLogIndex;
      for i := 0 to GESTURE_LOG_SIZE - 1 do
      begin
        if i = 0 then
          DrawText(PChar(gestureLog[ii]), Trunc(gestureLogPosition.x),
            Trunc(gestureLogPosition.y) + 410 - i * 20, 20, gestureColor)
        else
          DrawText(PChar(gestureLog[ii]), Trunc(gestureLogPosition.x),
            Trunc(gestureLogPosition.y) + 410 - i * 20, 20, LIGHTGRAY);
        ii := (ii + 1) mod GESTURE_LOG_SIZE;
      end;

      // Log mode buttons
      case logMode of
        3: begin logButton1Color := MAROON; logButton2Color := MAROON; end;
        2: begin logButton1Color := GRAY; logButton2Color := MAROON; end;
        1: begin logButton1Color := MAROON; logButton2Color := GRAY; end;
      else
        begin logButton1Color := GRAY; logButton2Color := GRAY; end;
      end;

      DrawRectangleRec(logButton1, logButton1Color);
      DrawText('Hide', Trunc(logButton1.x) + 7, Trunc(logButton1.y) + 3, 10, WHITE);
      DrawText('Repeat', Trunc(logButton1.x) + 7, Trunc(logButton1.y) + 13, 10, WHITE);
      DrawRectangleRec(logButton2, logButton2Color);
      DrawText('Hide', Trunc(logButton1.x) + 62, Trunc(logButton1.y) + 3, 10, WHITE);
      DrawText('Hold', Trunc(logButton1.x) + 62, Trunc(logButton1.y) + 13, 10, WHITE);

      // Protractor
      DrawText('Angle', Trunc(protractorPosition.x) + 55, Trunc(protractorPosition.y) + 76, 10, BLACK);
      angleString := Format('%.2f', [currentAngleDegrees]);
      DrawText(PChar(angleString), Trunc(protractorPosition.x) + 55, Trunc(protractorPosition.y) + 92, 20, gestureColor);

      DrawCircleV(protractorPosition, 80.0, WHITE);
      DrawLineEx(Vector2Create(protractorPosition.x - 90, protractorPosition.y),
        Vector2Create(protractorPosition.x + 90, protractorPosition.y), 3.0, LIGHTGRAY);
      DrawLineEx(Vector2Create(protractorPosition.x, protractorPosition.y - 90),
        Vector2Create(protractorPosition.x, protractorPosition.y + 90), 3.0, LIGHTGRAY);
      DrawLineEx(Vector2Create(protractorPosition.x - 80, protractorPosition.y - 45),
        Vector2Create(protractorPosition.x + 80, protractorPosition.y + 45), 3.0, GREEN);
      DrawLineEx(Vector2Create(protractorPosition.x - 80, protractorPosition.y + 45),
        Vector2Create(protractorPosition.x + 80, protractorPosition.y - 45), 3.0, GREEN);

      DrawText('0', Trunc(protractorPosition.x) + 96, Trunc(protractorPosition.y) - 9, 20, BLACK);
      DrawText('30', Trunc(protractorPosition.x) + 74, Trunc(protractorPosition.y) - 68, 20, BLACK);
      DrawText('90', Trunc(protractorPosition.x) - 11, Trunc(protractorPosition.y) - 110, 20, BLACK);
      DrawText('150', Trunc(protractorPosition.x) - 100, Trunc(protractorPosition.y) - 68, 20, BLACK);
      DrawText('180', Trunc(protractorPosition.x) - 124, Trunc(protractorPosition.y) - 9, 20, BLACK);
      DrawText('210', Trunc(protractorPosition.x) - 100, Trunc(protractorPosition.y) + 50, 20, BLACK);
      DrawText('270', Trunc(protractorPosition.x) - 18, Trunc(protractorPosition.y) + 92, 20, BLACK);
      DrawText('330', Trunc(protractorPosition.x) + 72, Trunc(protractorPosition.y) + 50, 20, BLACK);

      if currentAngleDegrees <> 0.0 then
        DrawLineEx(protractorPosition, finalVector, 3.0, gestureColor);

      // Touch/Mouse position indicators
      if currentGesture <> GESTURE_NONE then
      begin
        if touchCount <> 0 then
        begin
          for i := 0 to touchCount - 1 do
          begin
            DrawCircleV(touchPosition[i], 50.0, Fade(gestureColor, 0.5));
            DrawCircleV(touchPosition[i], 5.0, gestureColor);
          end;
          if touchCount = 2 then
          begin
            if currentGesture = 512 then
              DrawLineEx(touchPosition[0], touchPosition[1], 8.0, gestureColor)
            else
              DrawLineEx(touchPosition[0], touchPosition[1], 12.0, gestureColor);
          end;
        end
        else
        begin
          DrawCircleV(mousePosition, 35.0, Fade(gestureColor, 0.5));
          DrawCircleV(mousePosition, 5.0, gestureColor);
        end;
      end;

    EndDrawing();
  end;

  CloseWindow();
end.
