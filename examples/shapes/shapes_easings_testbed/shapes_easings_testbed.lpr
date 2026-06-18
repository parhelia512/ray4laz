program shapes_easings_testbed;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, reasings, math;

const
  FONT_SIZE = 20;
  D_STEP = 20.0;
  D_STEP_FINE = 2.0;
  D_MIN = 1.0;
  D_MAX = 10000.0;

type
  TEasingType = (
    EASE_LINEAR_NONE = 0,
    EASE_LINEAR_IN, EASE_LINEAR_OUT, EASE_LINEAR_IN_OUT,
    EASE_SINE_IN, EASE_SINE_OUT, EASE_SINE_IN_OUT,
    EASE_CIRC_IN, EASE_CIRC_OUT, EASE_CIRC_IN_OUT,
    EASE_CUBIC_IN, EASE_CUBIC_OUT, EASE_CUBIC_IN_OUT,
    EASE_QUAD_IN, EASE_QUAD_OUT, EASE_QUAD_IN_OUT,
    EASE_EXPO_IN, EASE_EXPO_OUT, EASE_EXPO_IN_OUT,
    EASE_BACK_IN, EASE_BACK_OUT, EASE_BACK_IN_OUT,
    EASE_BOUNCE_OUT, EASE_BOUNCE_IN, EASE_BOUNCE_IN_OUT,
    EASE_ELASTIC_IN, EASE_ELASTIC_OUT, EASE_ELASTIC_IN_OUT,
    NUM_EASING_TYPES,
    EASING_NONE = NUM_EASING_TYPES
  );

  TEasingFunc = function(t, b, c, d: single): single;

  TEasingFuncs = record
    name: PChar;
    func: TEasingFunc;
  end;

var
  easings: array[0..Ord(EASING_NONE)] of TEasingFuncs;
  easingX, easingY: integer;
  ballPosition: TVector2;
  t, d: single;
  paused, boundedT: boolean;

// NoEase function, used when "no easing" is selected for any axis
function NoEase(t, b, c, d: single): single;
begin
  // Hack to avoid compiler warning (about unused variables)
  // Just return b (starting position)
  Result := b;
end;

begin
  // Initialize easing functions - exactly as in C code
  easings[Ord(EASE_LINEAR_NONE)].name := 'EaseLinearNone';
  easings[Ord(EASE_LINEAR_NONE)].func := @EaseLinearNone;
  easings[Ord(EASE_LINEAR_IN)].name := 'EaseLinearIn';
  easings[Ord(EASE_LINEAR_IN)].func := @EaseLinearIn;
  easings[Ord(EASE_LINEAR_OUT)].name := 'EaseLinearOut';
  easings[Ord(EASE_LINEAR_OUT)].func := @EaseLinearOut;
  easings[Ord(EASE_LINEAR_IN_OUT)].name := 'EaseLinearInOut';
  easings[Ord(EASE_LINEAR_IN_OUT)].func := @EaseLinearInOut;
  easings[Ord(EASE_SINE_IN)].name := 'EaseSineIn';
  easings[Ord(EASE_SINE_IN)].func := @EaseSineIn;
  easings[Ord(EASE_SINE_OUT)].name := 'EaseSineOut';
  easings[Ord(EASE_SINE_OUT)].func := @EaseSineOut;
  easings[Ord(EASE_SINE_IN_OUT)].name := 'EaseSineInOut';
  easings[Ord(EASE_SINE_IN_OUT)].func := @EaseSineInOut;
  easings[Ord(EASE_CIRC_IN)].name := 'EaseCircIn';
  easings[Ord(EASE_CIRC_IN)].func := @EaseCircIn;
  easings[Ord(EASE_CIRC_OUT)].name := 'EaseCircOut';
  easings[Ord(EASE_CIRC_OUT)].func := @EaseCircOut;
  easings[Ord(EASE_CIRC_IN_OUT)].name := 'EaseCircInOut';
  easings[Ord(EASE_CIRC_IN_OUT)].func := @EaseCircInOut;
  easings[Ord(EASE_CUBIC_IN)].name := 'EaseCubicIn';
  easings[Ord(EASE_CUBIC_IN)].func := @EaseCubicIn;
  easings[Ord(EASE_CUBIC_OUT)].name := 'EaseCubicOut';
  easings[Ord(EASE_CUBIC_OUT)].func := @EaseCubicOut;
  easings[Ord(EASE_CUBIC_IN_OUT)].name := 'EaseCubicInOut';
  easings[Ord(EASE_CUBIC_IN_OUT)].func := @EaseCubicInOut;
  easings[Ord(EASE_QUAD_IN)].name := 'EaseQuadIn';
  easings[Ord(EASE_QUAD_IN)].func := @EaseQuadIn;
  easings[Ord(EASE_QUAD_OUT)].name := 'EaseQuadOut';
  easings[Ord(EASE_QUAD_OUT)].func := @EaseQuadOut;
  easings[Ord(EASE_QUAD_IN_OUT)].name := 'EaseQuadInOut';
  easings[Ord(EASE_QUAD_IN_OUT)].func := @EaseQuadInOut;
  easings[Ord(EASE_EXPO_IN)].name := 'EaseExpoIn';
  easings[Ord(EASE_EXPO_IN)].func := @EaseExpoIn;
  easings[Ord(EASE_EXPO_OUT)].name := 'EaseExpoOut';
  easings[Ord(EASE_EXPO_OUT)].func := @EaseExpoOut;
  easings[Ord(EASE_EXPO_IN_OUT)].name := 'EaseExpoInOut';
  easings[Ord(EASE_EXPO_IN_OUT)].func := @EaseExpoInOut;
  easings[Ord(EASE_BACK_IN)].name := 'EaseBackIn';
  easings[Ord(EASE_BACK_IN)].func := @EaseBackIn;
  easings[Ord(EASE_BACK_OUT)].name := 'EaseBackOut';
  easings[Ord(EASE_BACK_OUT)].func := @EaseBackOut;
  easings[Ord(EASE_BACK_IN_OUT)].name := 'EaseBackInOut';
  easings[Ord(EASE_BACK_IN_OUT)].func := @EaseBackInOut;
  easings[Ord(EASE_BOUNCE_OUT)].name := 'EaseBounceOut';
  easings[Ord(EASE_BOUNCE_OUT)].func := @EaseBounceOut;
  easings[Ord(EASE_BOUNCE_IN)].name := 'EaseBounceIn';
  easings[Ord(EASE_BOUNCE_IN)].func := @EaseBounceIn;
  easings[Ord(EASE_BOUNCE_IN_OUT)].name := 'EaseBounceInOut';
  easings[Ord(EASE_BOUNCE_IN_OUT)].func := @EaseBounceInOut;
  easings[Ord(EASE_ELASTIC_IN)].name := 'EaseElasticIn';
  easings[Ord(EASE_ELASTIC_IN)].func := @EaseElasticIn;
  easings[Ord(EASE_ELASTIC_OUT)].name := 'EaseElasticOut';
  easings[Ord(EASE_ELASTIC_OUT)].func := @EaseElasticOut;
  easings[Ord(EASE_ELASTIC_IN_OUT)].name := 'EaseElasticInOut';
  easings[Ord(EASE_ELASTIC_IN_OUT)].func := @EaseElasticInOut;
  easings[Ord(EASING_NONE)].name := 'None';
  easings[Ord(EASING_NONE)].func := @NoEase;

  InitWindow(800, 450, 'raylib [shapes] example - easings testbed');

  // Initialize variables - exactly as in C code
  ballPosition := Vector2Create(100.0, 100.0);
  t := 0.0;
  d := 300.0;
  paused := True;
  boundedT := True;
  easingX := Ord(EASING_NONE);
  easingY := Ord(EASING_NONE);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update - exactly as in C code
    if IsKeyPressed(KEY_T) then boundedT := not boundedT;

    // Choose easing for the X axis
    if IsKeyPressed(KEY_RIGHT) then
    begin
      Inc(easingX);
      if easingX > Ord(EASING_NONE) then easingX := 0;
    end
    else if IsKeyPressed(KEY_LEFT) then
    begin
      if easingX = 0 then easingX := Ord(EASING_NONE)
      else Dec(easingX);
    end;

    // Choose easing for the Y axis
    if IsKeyPressed(KEY_DOWN) then
    begin
      Inc(easingY);
      if easingY > Ord(EASING_NONE) then easingY := 0;
    end
    else if IsKeyPressed(KEY_UP) then
    begin
      if easingY = 0 then easingY := Ord(EASING_NONE)
      else Dec(easingY);
    end;

    // Change d (duration) value
    if IsKeyPressed(KEY_W) and (d < D_MAX - D_STEP) then d := d + D_STEP
    else if IsKeyPressed(KEY_Q) and (d > D_MIN + D_STEP) then d := d - D_STEP;

    if IsKeyDown(KEY_S) and (d < D_MAX - D_STEP_FINE) then d := d + D_STEP_FINE
    else if IsKeyDown(KEY_A) and (d > D_MIN + D_STEP_FINE) then d := d - D_STEP_FINE;

    // Play, pause and restart controls
    if IsKeyPressed(KEY_SPACE) or IsKeyPressed(KEY_T) or
       IsKeyPressed(KEY_RIGHT) or IsKeyPressed(KEY_LEFT) or
       IsKeyPressed(KEY_DOWN) or IsKeyPressed(KEY_UP) or
       IsKeyPressed(KEY_W) or IsKeyPressed(KEY_Q) or
       IsKeyDown(KEY_S) or IsKeyDown(KEY_A) or
       (IsKeyPressed(KEY_ENTER) and boundedT and (t >= d)) then
    begin
      t := 0.0;
      ballPosition.x := 100.0;
      ballPosition.y := 100.0;
      paused := True;
    end;

    if IsKeyPressed(KEY_ENTER) then paused := not paused;

    // Movement computation
    if not paused and ((boundedT and (t < d)) or not boundedT) then
    begin
      ballPosition.x := easings[easingX].func(t, 100.0, 700.0 - 170.0, d);
      ballPosition.y := easings[easingY].func(t, 100.0, 400.0 - 170.0, d);
      t := t + 1.0;
    end;

    // Draw - exactly as in C code
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw information text
      DrawText(PChar(Format('Easing x: %s', [easings[easingX].name])),
        20, FONT_SIZE, FONT_SIZE, LIGHTGRAY);
      DrawText(PChar(Format('Easing y: %s', [easings[easingY].name])),
        20, FONT_SIZE * 2, FONT_SIZE, LIGHTGRAY);

      if boundedT then
        DrawText(PChar(Format('t (b) = %.2f d = %.2f', [t, d])),
          20, FONT_SIZE * 3, FONT_SIZE, LIGHTGRAY)
      else
        DrawText(PChar(Format('t (u) = %.2f d = %.2f', [t, d])),
          20, FONT_SIZE * 3, FONT_SIZE, LIGHTGRAY);

      // Draw instructions text
      DrawText('Use ENTER to play or pause movement, use SPACE to restart',
        20, GetScreenHeight() - FONT_SIZE * 2, FONT_SIZE, LIGHTGRAY);
      DrawText('Use Q and W or A and S keys to change duration',
        20, GetScreenHeight() - FONT_SIZE * 3, FONT_SIZE, LIGHTGRAY);
      DrawText('Use LEFT or RIGHT keys to choose easing for the x axis',
        20, GetScreenHeight() - FONT_SIZE * 4, FONT_SIZE, LIGHTGRAY);
      DrawText('Use UP or DOWN keys to choose easing for the y axis',
        20, GetScreenHeight() - FONT_SIZE * 5, FONT_SIZE, LIGHTGRAY);

      // Draw ball
      DrawCircleV(ballPosition, 16.0, MAROON);

    EndDrawing();
  end;

  CloseWindow();
end.
