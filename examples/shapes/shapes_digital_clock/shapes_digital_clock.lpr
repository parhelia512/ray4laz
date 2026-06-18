program shapes_digital_clock;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, raymath, math;

const
  CLOCK_ANALOG = 0;
  CLOCK_DIGITAL = 1;

  screenWidth = 800;
  screenHeight = 450;

type
  // Clock hand type
  TClockHand = record
    value: integer;       // Time value
    angle: single;        // Hand angle
    length: integer;      // Hand length
    thickness: integer;   // Hand thickness
    color: TColorB;       // Hand color
  end;

  // Clock hands
  TClock = record
    second: TClockHand;   // Clock hand for seconds
    minute: TClockHand;   // Clock hand for minutes
    hour: TClockHand;     // Clock hand for hours
  end;


// Update clock time
procedure UpdateClock(var clock: TClock);
var
  currentTime: TDateTime;
  hour, minute, second, ms: word;
begin
  currentTime := Now;
  DecodeTime(currentTime, hour, minute, second, ms);

  // Updating time data
  clock.second.value := second;
  clock.minute.value := minute;
  clock.hour.value := hour;

  clock.hour.angle := (hour mod 12) * 180.0 / 6.0;
  clock.hour.angle := clock.hour.angle + (minute mod 60) * 30.0 / 60.0;
  clock.hour.angle := clock.hour.angle - 90;

  clock.minute.angle := (minute mod 60) * 6.0;
  clock.minute.angle := clock.minute.angle + (second mod 60) * 6.0 / 60.0;
  clock.minute.angle := clock.minute.angle - 90;

  clock.second.angle := (second mod 60) * 6.0;
  clock.second.angle := clock.second.angle - 90;
end;

// Draw analog clock
// Parameter: position, refers to center position
procedure DrawClockAnalog(clock: TClock; position: TVector2);
var
  i: integer;
  angle: single;
  p1, p2: TVector2;
  thickness: single;
begin
  // Draw clock base
  DrawCircleV(position, clock.second.length + 40.0, LIGHTGRAY);
  DrawCircleV(position, 12.0, GRAY);

  // Draw clock minutes/seconds lines
  for i := 0 to 59 do
  begin
    angle := (6.0 * i - 90.0) * DEG2RAD;

    if i mod 5 = 0 then
    begin
      p1 := Vector2Create(
        position.x + (clock.second.length + 6) * cos(angle),
        position.y + (clock.second.length + 6) * sin(angle)
      );
      p2 := Vector2Create(
        position.x + (clock.second.length + 20) * cos(angle),
        position.y + (clock.second.length + 20) * sin(angle)
      );
      thickness := 3.0;
    end
    else
    begin
      p1 := Vector2Create(
        position.x + (clock.second.length + 10) * cos(angle),
        position.y + (clock.second.length + 10) * sin(angle)
      );
      p2 := Vector2Create(
        position.x + (clock.second.length + 20) * cos(angle),
        position.y + (clock.second.length + 20) * sin(angle)
      );
      thickness := 1.0;
    end;

    DrawLineEx(p1, p2, thickness, DARKGRAY);
  end;

  // Draw hand seconds
  DrawRectanglePro(
    RectangleCreate(position.x, position.y, clock.second.length, clock.second.thickness),
    Vector2Create(0.0, clock.second.thickness / 2.0),
    clock.second.angle,
    clock.second.color
  );

  // Draw hand minutes
  DrawRectanglePro(
    RectangleCreate(position.x, position.y, clock.minute.length, clock.minute.thickness),
    Vector2Create(0.0, clock.minute.thickness / 2.0),
    clock.minute.angle,
    clock.minute.color
  );

  // Draw hand hours
  DrawRectanglePro(
    RectangleCreate(position.x, position.y, clock.hour.length, clock.hour.thickness),
    Vector2Create(0.0, clock.hour.thickness / 2.0),
    clock.hour.angle,
    clock.hour.color
  );
end;

// Draw one 7-segment display segment, horizontal or vertical
procedure DrawDisplaySegment(center: TVector2; length, thick: integer; vertical: boolean; color: TColorB);
var
  segmentPoints: array[0..5] of TVector2;
begin
  if not vertical then
  begin
    // Horizontal segment points
    segmentPoints[0] := Vector2Create(center.x - length/2.0 - thick/2.0, center.y);
    segmentPoints[1] := Vector2Create(center.x - length/2.0, center.y + thick/2.0);
    segmentPoints[2] := Vector2Create(center.x - length/2.0, center.y - thick/2.0);
    segmentPoints[3] := Vector2Create(center.x + length/2.0, center.y + thick/2.0);
    segmentPoints[4] := Vector2Create(center.x + length/2.0, center.y - thick/2.0);
    segmentPoints[5] := Vector2Create(center.x + length/2.0 + thick/2.0, center.y);
  end
  else
  begin
    // Vertical segment points
    segmentPoints[0] := Vector2Create(center.x, center.y - length/2.0 - thick/2.0);
    segmentPoints[1] := Vector2Create(center.x - thick/2.0, center.y - length/2.0);
    segmentPoints[2] := Vector2Create(center.x + thick/2.0, center.y - length/2.0);
    segmentPoints[3] := Vector2Create(center.x - thick/2.0, center.y + length/2.0);
    segmentPoints[4] := Vector2Create(center.x + thick/2.0, center.y + length/2.0);
    segmentPoints[5] := Vector2Create(center.x, center.y + length/2.0 + thick/2.0);
  end;

  DrawTriangleStrip(segmentPoints, 6, color);
end;

// Draw seven segments display
// Parameter: position, refers to top-left corner of display
// Parameter: segments, defines in binary the segments to be activated
procedure Draw7SDisplay(position: TVector2; segments: byte; colorOn, colorOff: TColorB);
var
  segmentLen, segmentThick: integer;
  offsetYAdjust: single;
  currentColor: TColorB;
begin
  segmentLen := 60;
  segmentThick := 20;
  offsetYAdjust := segmentThick * 0.3; // HACK: Adjust gap space between segment limits

  // Segment A
  if (segments and $01) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick + segmentLen/2.0, position.y + segmentThick),
    segmentLen, segmentThick, false, currentColor);

  // Segment B
  if (segments and $02) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick + segmentLen + segmentThick/2.0, position.y + 2*segmentThick + segmentLen/2.0 - offsetYAdjust),
    segmentLen, segmentThick, true, currentColor);

  // Segment C
  if (segments and $04) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick + segmentLen + segmentThick/2.0, position.y + 4*segmentThick + segmentLen + segmentLen/2.0 - 3*offsetYAdjust),
    segmentLen, segmentThick, true, currentColor);

  // Segment D
  if (segments and $08) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick + segmentLen/2.0, position.y + 5*segmentThick + 2*segmentLen - 4*offsetYAdjust),
    segmentLen, segmentThick, false, currentColor);

  // Segment E
  if (segments and $10) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick/2.0, position.y + 4*segmentThick + segmentLen + segmentLen/2.0 - 3*offsetYAdjust),
    segmentLen, segmentThick, true, currentColor);

  // Segment F
  if (segments and $20) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick/2.0, position.y + 2*segmentThick + segmentLen/2.0 - offsetYAdjust),
    segmentLen, segmentThick, true, currentColor);

  // Segment G
  if (segments and $40) <> 0 then currentColor := colorOn else currentColor := colorOff;
  DrawDisplaySegment(
    Vector2Create(position.x + segmentThick + segmentLen/2.0, position.y + 3*segmentThick + segmentLen - 2*offsetYAdjust),
    segmentLen, segmentThick, false, currentColor);
end;

// Draw 7-segment display with value
procedure DrawDisplayValue(position: TVector2; value: integer; colorOn, colorOff: TColorB);
begin
  case value of
    0: Draw7SDisplay(position, $3F, colorOn, colorOff); // 0b00111111
    1: Draw7SDisplay(position, $06, colorOn, colorOff); // 0b00000110
    2: Draw7SDisplay(position, $5B, colorOn, colorOff); // 0b01011011
    3: Draw7SDisplay(position, $4F, colorOn, colorOff); // 0b01001111
    4: Draw7SDisplay(position, $66, colorOn, colorOff); // 0b01100110
    5: Draw7SDisplay(position, $6D, colorOn, colorOff); // 0b01101101
    6: Draw7SDisplay(position, $7D, colorOn, colorOff); // 0b01111101
    7: Draw7SDisplay(position, $07, colorOn, colorOff); // 0b00000111
    8: Draw7SDisplay(position, $7F, colorOn, colorOff); // 0b01111111
    9: Draw7SDisplay(position, $6F, colorOn, colorOff); // 0b01101111
  end;
end;

// Draw digital clock
// PARAM: position, refers to top-left corner
procedure DrawClockDigital(clock: TClock; position: TVector2);
var
  colorOff: TColorB;
begin
  colorOff := ColorAlpha(LIGHTGRAY, 0.3);

  // Draw clock using custom 7-segments display (made of shapes)
  DrawDisplayValue(Vector2Create(position.x, position.y), clock.hour.value div 10, RED, colorOff);
  DrawDisplayValue(Vector2Create(position.x + 120, position.y), clock.hour.value mod 10, RED, colorOff);

  if clock.second.value mod 2 = 1 then
  begin
    DrawCircle(Trunc(position.x + 240), Trunc(position.y + 70), 12, RED);
    DrawCircle(Trunc(position.x + 240), Trunc(position.y + 150), 12, RED);
  end
  else
  begin
    DrawCircle(Trunc(position.x + 240), Trunc(position.y + 70), 12, colorOff);
    DrawCircle(Trunc(position.x + 240), Trunc(position.y + 150), 12, colorOff);
  end;

  DrawDisplayValue(Vector2Create(position.x + 260, position.y), clock.minute.value div 10, RED, colorOff);
  DrawDisplayValue(Vector2Create(position.x + 380, position.y), clock.minute.value mod 10, RED, colorOff);

  if clock.second.value mod 2 = 1 then
  begin
    DrawCircle(Trunc(position.x + 500), Trunc(position.y + 70), 12, RED);
    DrawCircle(Trunc(position.x + 500), Trunc(position.y + 150), 12, RED);
  end
  else
  begin
    DrawCircle(Trunc(position.x + 500), Trunc(position.y + 70), 12, colorOff);
    DrawCircle(Trunc(position.x + 500), Trunc(position.y + 150), 12, colorOff);
  end;

  DrawDisplayValue(Vector2Create(position.x + 520, position.y), clock.second.value div 10, RED, colorOff);
  DrawDisplayValue(Vector2Create(position.x + 640, position.y), clock.second.value mod 10, RED, colorOff);
end;

var
  clockMode: integer;
  clock: TClock;
  clockTime: string;

begin
  // Initialization
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - digital clock');

  clockMode := CLOCK_DIGITAL;

  // Initialize clock
  // NOTE: Includes visual info for analog clock
  clock.second.angle := 45;
  clock.second.length := 140;
  clock.second.thickness := 3;
  clock.second.color := MAROON;

  clock.minute.angle := 10;
  clock.minute.length := 130;
  clock.minute.thickness := 7;
  clock.minute.color := DARKGRAY;

  clock.hour.angle := 0;
  clock.hour.length := 100;
  clock.hour.thickness := 7;
  clock.hour.color := BLACK;

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    if IsKeyPressed(KEY_SPACE) then
    begin
      // Toggle clock mode
      if clockMode = CLOCK_DIGITAL then
        clockMode := CLOCK_ANALOG
      else if clockMode = CLOCK_ANALOG then
        clockMode := CLOCK_DIGITAL;
    end;

    UpdateClock(clock); // Update clock required data: value and angle

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw clock in selected mode
      if clockMode = CLOCK_ANALOG then
        DrawClockAnalog(clock, Vector2Create(400, 240))
      else if clockMode = CLOCK_DIGITAL then
      begin
        DrawClockDigital(clock, Vector2Create(30, 60));

        // Draw clock using default raylib font
        clockTime := Format('%.2d:%.2d:%.2d', [clock.hour.value, clock.minute.value, clock.second.value]);
        DrawText(PChar(clockTime),
          GetScreenWidth() div 2 - MeasureText(PChar(clockTime), 150) div 2,
          300, 150, BLACK);
      end;

      if clockMode = CLOCK_DIGITAL then
        DrawText('Press [SPACE] to switch clock mode: DIGITAL CLOCK', 10, 10, 20, DARKGRAY)
      else
        DrawText('Press [SPACE] to switch clock mode: ANALOGUE CLOCK', 10, 10, 20, DARKGRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
