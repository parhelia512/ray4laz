program shapes_clock_of_clocks;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  clockFaceSize = 24;
  clockFaceSpacing = 8.0;
  sectionSpacing = 16.0;
  handsMoveDuration = 0.5;

type
  TVec2Arr = array[0..23] of TVector2;

const
  TL: TVector2 = (x: 0.0; y: 90.0);
  TR: TVector2 = (x: 90.0; y: 180.0);
  BR: TVector2 = (x: 180.0; y: 270.0);
  BL: TVector2 = (x: 0.0; y: 270.0);
  HH: TVector2 = (x: 0.0; y: 180.0);
  VV: TVector2 = (x: 90.0; y: 270.0);
  ZZ: TVector2 = (x: 135.0; y: 135.0);

var
  digitAngles: array[0..9] of TVec2Arr;
  prevSeconds, gestureLogIndex, previousGesture, logMode: integer;
  gestureLog: array[0..19] of string[12];
  gestureColor: TColorB;
  logButton1, logButton2: TRectangle;
  gestureLogPosition, protractorPosition: TVector2;
  angleLength, currentAngleDegrees: single;
  finalVector: TVector2;
  currentAngles: array[0..5] of TVec2Arr;
  srcAngles, dstAngles: array[0..5] of TVec2Arr;
  handsMoveTimer: single;
  hourMode: integer;
  hour, minute, second, milliSecond: word;
  clockDigits: string;
  digit, cell, row, col, i: integer;
  t, xOffset: single;
  centre: TVector2;

  // Helper procedure to initialize digit angles
  procedure InitDigitAngles;
  var
    d, i: integer;
  begin
    // Digit 0
    digitAngles[0][0] := TL; digitAngles[0][1] := HH; digitAngles[0][2] := HH; digitAngles[0][3] := TR;
    digitAngles[0][4] := VV; digitAngles[0][5] := TL; digitAngles[0][6] := TR; digitAngles[0][7] := VV;
    digitAngles[0][8] := VV; digitAngles[0][9] := VV; digitAngles[0][10] := VV; digitAngles[0][11] := VV;
    digitAngles[0][12] := VV; digitAngles[0][13] := VV; digitAngles[0][14] := VV; digitAngles[0][15] := VV;
    digitAngles[0][16] := VV; digitAngles[0][17] := BL; digitAngles[0][18] := BR; digitAngles[0][19] := VV;
    digitAngles[0][20] := BL; digitAngles[0][21] := HH; digitAngles[0][22] := HH; digitAngles[0][23] := BR;

    // Digit 1
    digitAngles[1][0] := TL; digitAngles[1][1] := HH; digitAngles[1][2] := TR; digitAngles[1][3] := ZZ;
    digitAngles[1][4] := BL; digitAngles[1][5] := TR; digitAngles[1][6] := VV; digitAngles[1][7] := ZZ;
    digitAngles[1][8] := ZZ; digitAngles[1][9] := VV; digitAngles[1][10] := VV; digitAngles[1][11] := ZZ;
    digitAngles[1][12] := ZZ; digitAngles[1][13] := VV; digitAngles[1][14] := VV; digitAngles[1][15] := ZZ;
    digitAngles[1][16] := TL; digitAngles[1][17] := BR; digitAngles[1][18] := BL; digitAngles[1][19] := TR;
    digitAngles[1][20] := BL; digitAngles[1][21] := HH; digitAngles[1][22] := HH; digitAngles[1][23] := BR;

    // Digit 2
    digitAngles[2][0] := TL; digitAngles[2][1] := HH; digitAngles[2][2] := HH; digitAngles[2][3] := TR;
    digitAngles[2][4] := BL; digitAngles[2][5] := HH; digitAngles[2][6] := TR; digitAngles[2][7] := VV;
    digitAngles[2][8] := TL; digitAngles[2][9] := HH; digitAngles[2][10] := BR; digitAngles[2][11] := VV;
    digitAngles[2][12] := VV; digitAngles[2][13] := TL; digitAngles[2][14] := HH; digitAngles[2][15] := BR;
    digitAngles[2][16] := VV; digitAngles[2][17] := BL; digitAngles[2][18] := HH; digitAngles[2][19] := TR;
    digitAngles[2][20] := BL; digitAngles[2][21] := HH; digitAngles[2][22] := HH; digitAngles[2][23] := BR;

    // Digit 3
    digitAngles[3][0] := TL; digitAngles[3][1] := HH; digitAngles[3][2] := HH; digitAngles[3][3] := TR;
    digitAngles[3][4] := BL; digitAngles[3][5] := HH; digitAngles[3][6] := TR; digitAngles[3][7] := VV;
    digitAngles[3][8] := TL; digitAngles[3][9] := HH; digitAngles[3][10] := BR; digitAngles[3][11] := VV;
    digitAngles[3][12] := BL; digitAngles[3][13] := HH; digitAngles[3][14] := TR; digitAngles[3][15] := VV;
    digitAngles[3][16] := TL; digitAngles[3][17] := HH; digitAngles[3][18] := BR; digitAngles[3][19] := VV;
    digitAngles[3][20] := BL; digitAngles[3][21] := HH; digitAngles[3][22] := HH; digitAngles[3][23] := BR;

    // Digit 4
    digitAngles[4][0] := TL; digitAngles[4][1] := TR; digitAngles[4][2] := TL; digitAngles[4][3] := TR;
    digitAngles[4][4] := VV; digitAngles[4][5] := VV; digitAngles[4][6] := VV; digitAngles[4][7] := VV;
    digitAngles[4][8] := VV; digitAngles[4][9] := BL; digitAngles[4][10] := BR; digitAngles[4][11] := VV;
    digitAngles[4][12] := BL; digitAngles[4][13] := HH; digitAngles[4][14] := TR; digitAngles[4][15] := VV;
    digitAngles[4][16] := ZZ; digitAngles[4][17] := ZZ; digitAngles[4][18] := VV; digitAngles[4][19] := VV;
    digitAngles[4][20] := ZZ; digitAngles[4][21] := ZZ; digitAngles[4][22] := BL; digitAngles[4][23] := BR;

    // Digit 5
    digitAngles[5][0] := TL; digitAngles[5][1] := HH; digitAngles[5][2] := HH; digitAngles[5][3] := TR;
    digitAngles[5][4] := VV; digitAngles[5][5] := TL; digitAngles[5][6] := HH; digitAngles[5][7] := BR;
    digitAngles[5][8] := VV; digitAngles[5][9] := BL; digitAngles[5][10] := HH; digitAngles[5][11] := TR;
    digitAngles[5][12] := BL; digitAngles[5][13] := HH; digitAngles[5][14] := TR; digitAngles[5][15] := VV;
    digitAngles[5][16] := TL; digitAngles[5][17] := HH; digitAngles[5][18] := BR; digitAngles[5][19] := VV;
    digitAngles[5][20] := BL; digitAngles[5][21] := HH; digitAngles[5][22] := HH; digitAngles[5][23] := BR;

    // Digit 6
    digitAngles[6][0] := TL; digitAngles[6][1] := HH; digitAngles[6][2] := HH; digitAngles[6][3] := TR;
    digitAngles[6][4] := VV; digitAngles[6][5] := TL; digitAngles[6][6] := HH; digitAngles[6][7] := BR;
    digitAngles[6][8] := VV; digitAngles[6][9] := BL; digitAngles[6][10] := HH; digitAngles[6][11] := TR;
    digitAngles[6][12] := VV; digitAngles[6][13] := TL; digitAngles[6][14] := TR; digitAngles[6][15] := VV;
    digitAngles[6][16] := VV; digitAngles[6][17] := BL; digitAngles[6][18] := BR; digitAngles[6][19] := VV;
    digitAngles[6][20] := BL; digitAngles[6][21] := HH; digitAngles[6][22] := HH; digitAngles[6][23] := BR;

    // Digit 7
    digitAngles[7][0] := TL; digitAngles[7][1] := HH; digitAngles[7][2] := HH; digitAngles[7][3] := TR;
    digitAngles[7][4] := BL; digitAngles[7][5] := HH; digitAngles[7][6] := TR; digitAngles[7][7] := VV;
    digitAngles[7][8] := ZZ; digitAngles[7][9] := ZZ; digitAngles[7][10] := VV; digitAngles[7][11] := VV;
    digitAngles[7][12] := ZZ; digitAngles[7][13] := ZZ; digitAngles[7][14] := VV; digitAngles[7][15] := VV;
    digitAngles[7][16] := ZZ; digitAngles[7][17] := ZZ; digitAngles[7][18] := VV; digitAngles[7][19] := VV;
    digitAngles[7][20] := ZZ; digitAngles[7][21] := ZZ; digitAngles[7][22] := BL; digitAngles[7][23] := BR;

    // Digit 8
    digitAngles[8][0] := TL; digitAngles[8][1] := HH; digitAngles[8][2] := HH; digitAngles[8][3] := TR;
    digitAngles[8][4] := VV; digitAngles[8][5] := TL; digitAngles[8][6] := TR; digitAngles[8][7] := VV;
    digitAngles[8][8] := VV; digitAngles[8][9] := BL; digitAngles[8][10] := BR; digitAngles[8][11] := VV;
    digitAngles[8][12] := VV; digitAngles[8][13] := TL; digitAngles[8][14] := TR; digitAngles[8][15] := VV;
    digitAngles[8][16] := VV; digitAngles[8][17] := BL; digitAngles[8][18] := BR; digitAngles[8][19] := VV;
    digitAngles[8][20] := BL; digitAngles[8][21] := HH; digitAngles[8][22] := HH; digitAngles[8][23] := BR;

    // Digit 9
    digitAngles[9][0] := TL; digitAngles[9][1] := HH; digitAngles[9][2] := HH; digitAngles[9][3] := TR;
    digitAngles[9][4] := VV; digitAngles[9][5] := TL; digitAngles[9][6] := TR; digitAngles[9][7] := VV;
    digitAngles[9][8] := VV; digitAngles[9][9] := BL; digitAngles[9][10] := BR; digitAngles[9][11] := VV;
    digitAngles[9][12] := BL; digitAngles[9][13] := HH; digitAngles[9][14] := TR; digitAngles[9][15] := VV;
    digitAngles[9][16] := TL; digitAngles[9][17] := HH; digitAngles[9][18] := BR; digitAngles[9][19] := VV;
    digitAngles[9][20] := BL; digitAngles[9][21] := HH; digitAngles[9][22] := HH; digitAngles[9][23] := BR;
  end;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - clock of clocks');

  // Initialize digit angles
  InitDigitAngles;

  prevSeconds := -1;
  handsMoveTimer := 0.0;
  hourMode := 24;
  FillChar(currentAngles, SizeOf(currentAngles), 0);
  FillChar(srcAngles, SizeOf(srcAngles), 0);
  FillChar(dstAngles, SizeOf(dstAngles), 0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    DecodeTime(Now, hour, minute, second, milliSecond);

    if second <> prevSeconds then
    begin
      prevSeconds := second;
      clockDigits := Format('%.2d%.2d%.2d', [hour mod hourMode, minute, second]);

      for digit := 0 to 5 do
        for cell := 0 to 23 do
        begin
          srcAngles[digit][cell] := currentAngles[digit][cell];
          dstAngles[digit][cell] := digitAngles[Ord(clockDigits[digit + 1]) - Ord('0')][cell];
          if (digit = 0) and (hourMode = 12) and (clockDigits[1] = '0') then
            dstAngles[digit][cell] := ZZ;
          if srcAngles[digit][cell].x > dstAngles[digit][cell].x then
            srcAngles[digit][cell].x := srcAngles[digit][cell].x - 360.0;
          if srcAngles[digit][cell].y > dstAngles[digit][cell].y then
            srcAngles[digit][cell].y := srcAngles[digit][cell].y - 360.0;
        end;

      handsMoveTimer := -GetFrameTime();
    end;

    if handsMoveTimer < handsMoveDuration then
    begin
      handsMoveTimer := Clamp(handsMoveTimer + GetFrameTime(), 0, handsMoveDuration);
      t := handsMoveTimer / handsMoveDuration;
      t := t * t * (3.0 - 2.0 * t);

      for digit := 0 to 5 do
        for cell := 0 to 23 do
        begin
          currentAngles[digit][cell].x := Lerp(srcAngles[digit][cell].x, dstAngles[digit][cell].x, t);
          currentAngles[digit][cell].y := Lerp(srcAngles[digit][cell].y, dstAngles[digit][cell].y, t);
        end;
    end;

    if IsKeyPressed(KEY_SPACE) then hourMode := 36 - hourMode;

    BeginDrawing();
      ClearBackground(ColorLerp(DARKBLUE, BLACK, 0.75));
      DrawText(PChar(Format('%d-h mode, space to change', [hourMode])), 10, 30, 20, RAYWHITE);

      xOffset := 4.0;
      for digit := 0 to 5 do
      begin
        for row := 0 to 5 do
          for col := 0 to 3 do
          begin
            centre := Vector2Create(
              xOffset + col * (clockFaceSize + clockFaceSpacing) + clockFaceSize * 0.5,
              100 + row * (clockFaceSize + clockFaceSpacing) + clockFaceSize * 0.5
            );
            DrawRing(centre, clockFaceSize * 0.5 - 2.0, clockFaceSize * 0.5, 0, 360, 24, DARKGRAY);
            DrawRectanglePro(
              RectangleCreate(centre.x, centre.y, clockFaceSize * 0.5 + 4.0, 4.0),
              Vector2Create(2.0, 2.0),
              currentAngles[digit][row * 4 + col].x,
              ColorLerp(YELLOW, RAYWHITE, 0.25)
            );
            DrawRectanglePro(
              RectangleCreate(centre.x, centre.y, clockFaceSize * 0.5 + 2.0, 4.0),
              Vector2Create(2.0, 2.0),
              currentAngles[digit][row * 4 + col].y,
              ColorLerp(YELLOW, RAYWHITE, 0.25)
            );
          end;
        xOffset := xOffset + (clockFaceSize + clockFaceSpacing) * 4;
        if digit mod 2 = 1 then
        begin
          DrawRing(Vector2Create(xOffset + 4.0, 160.0), 6.0, 8.0, 0.0, 360.0, 24, ColorLerp(YELLOW, RAYWHITE, 0.25));
          DrawRing(Vector2Create(xOffset + 4.0, 225.0), 6.0, 8.0, 0.0, 360.0, 24, ColorLerp(YELLOW, RAYWHITE, 0.25));
          xOffset := xOffset + sectionSpacing;
        end;
      end;
      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
