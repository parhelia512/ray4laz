program shapes_rlgl_color_wheel;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, rlgl, raymath, raygui;

const
  screenWidth = 800;
  screenHeight = 450;
  pointsMin = 3;
  pointsMax = 256;

var
  triangleCount: cardinal;
  pointScale: single;
  value: single;
  center, circlePosition: TVector2;
  color: TColorB;
  sliderClicked, settingColor: boolean;
  renderType: integer;
  i: cardinal;
  sliderRectangle: TRectangle;
  mousePosition: TVector2;
  sliderHover: boolean;
  angleOffset, angle, angleOffsetCalculated: single;
  position, position2, offset, offset2, scale: TVector2;
  angleNonRadian, angleNonRadianOffset: single;
  currentColor, offsetColor, handleColor: TColorB;
  distance, angleVal: single;
  angle360: single;
  valueActual: single;
begin
  triangleCount := 64;
  pointScale := 150.0;
  value := 1.0;
  center := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);
  circlePosition := center;
  color := WHITE;
  sliderClicked := False;
  settingColor := False;
  renderType := RL_TRIANGLES;

  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - rlgl color wheel');
  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    triangleCount := triangleCount + Cardinal(Round(GetMouseWheelMove()));
    if triangleCount < pointsMin then triangleCount := pointsMin;
    if triangleCount > pointsMax then triangleCount := pointsMax;

    sliderRectangle := RectangleCreate(42.0, 16.0 + 64.0 + 45.0, 64.0, 16.0);
    mousePosition := GetMousePosition;

    sliderHover := (mousePosition.x >= sliderRectangle.x) and (mousePosition.y >= sliderRectangle.y) and
                   (mousePosition.x < sliderRectangle.x + sliderRectangle.width) and
                   (mousePosition.y < sliderRectangle.y + sliderRectangle.height);

    if IsKeyDown(KEY_UP) then
    begin
      pointScale := pointScale * 1.025;
      if pointScale > screenHeight / 2.0 then
        pointScale := screenHeight / 2.0
      else
        circlePosition := Vector2Add(Vector2Multiply(Vector2Subtract(circlePosition, center), Vector2Create(1.025, 1.025)), center);
    end;

    if IsKeyDown(KEY_DOWN) then
    begin
      pointScale := pointScale * 0.975;
      if pointScale < 32.0 then
        pointScale := 32.0
      else
      begin
        circlePosition := Vector2Add(Vector2Multiply(Vector2Subtract(circlePosition, center), Vector2Create(0.975, 0.975)), center);
        distance := Vector2Distance(center, circlePosition) / pointScale;
        angleVal := ((Vector2Angle(Vector2Create(0.0, -pointScale), Vector2Subtract(center, circlePosition)) / PI + 1.0) / 2.0);
        if distance > 1.0 then
          circlePosition := Vector2Add(Vector2Create(Sin(angleVal * PI * 2.0) * pointScale, -Cos(angleVal * PI * 2.0) * pointScale), center);
      end;
    end;

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and (Vector2Distance(GetMousePosition, center) <= pointScale + 10.0) then
      settingColor := True;

    if IsMouseButtonReleased(MOUSE_BUTTON_LEFT) then settingColor := False;

    if sliderHover and IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then sliderClicked := True;
    if sliderClicked and IsMouseButtonReleased(MOUSE_BUTTON_LEFT) then sliderClicked := False;

    if IsKeyPressed(KEY_SPACE) then renderType := RL_LINES;
    if IsKeyReleased(KEY_SPACE) then renderType := RL_TRIANGLES;

    if settingColor or sliderClicked then
    begin
      if settingColor then circlePosition := GetMousePosition;

      distance := Vector2Distance(center, circlePosition) / pointScale;
      angleVal := ((Vector2Angle(Vector2Create(0.0, -pointScale), Vector2Subtract(center, circlePosition)) / PI + 1.0) / 2.0);

      if settingColor and (distance > 1.0) then
        circlePosition := Vector2Add(Vector2Create(Sin(angleVal * PI * 2.0) * pointScale, -Cos(angleVal * PI * 2.0) * pointScale), center);


      angle360 := angleVal * 360.0;

      valueActual := Clamp(distance, 0.0, 1.0);
      color := ColorLerp(ColorCreate(Trunc(value * 255), Trunc(value * 255), Trunc(value * 255), 255),
        ColorFromHSV(angle360, Clamp(distance, 0.0, 1.0), 1.0), valueActual);
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      rlBegin(renderType);
      for i := 0 to triangleCount - 1 do
      begin
        angleOffset := (PI * 2.0) / triangleCount;
        angle := angleOffset * i;
        angleOffsetCalculated := (i + 1) * angleOffset;
        scale := Vector2Create(pointScale, pointScale);

        offset := Vector2Multiply(Vector2Create(Sin(angle), -Cos(angle)), scale);
        offset2 := Vector2Multiply(Vector2Create(Sin(angleOffsetCalculated), -Cos(angleOffsetCalculated)), scale);

        position := Vector2Add(center, offset);
        position2 := Vector2Add(center, offset2);

        angleNonRadian := (angle / (2.0 * PI)) * 360.0;
        angleNonRadianOffset := (angleOffset / (2.0 * PI)) * 360.0;

        currentColor := ColorFromHSV(angleNonRadian, 1.0, 1.0);
        offsetColor := ColorFromHSV(angleNonRadian + angleNonRadianOffset, 1.0, 1.0);

        if renderType = RL_TRIANGLES then
        begin
          rlColor4ub(currentColor.r, currentColor.g, currentColor.b, currentColor.a);
          rlVertex2f(position.x, position.y);
          rlColor4f(value, value, value, 1.0);
          rlVertex2f(center.x, center.y);
          rlColor4ub(offsetColor.r, offsetColor.g, offsetColor.b, offsetColor.a);
          rlVertex2f(position2.x, position2.y);
        end
        else if renderType = RL_LINES then
        begin
          rlColor4ub(currentColor.r, currentColor.g, currentColor.b, currentColor.a);
          rlVertex2f(position.x, position.y);
          rlColor4ub(255, 255, 255, 255);
          rlVertex2f(center.x, center.y);

          rlVertex2f(center.x, center.y);
          rlColor4ub(offsetColor.r, offsetColor.g, offsetColor.b, offsetColor.a);
          rlVertex2f(position2.x, position2.y);

          rlVertex2f(position2.x, position2.y);
          rlColor4ub(currentColor.r, currentColor.g, currentColor.b, currentColor.a);
          rlVertex2f(position.x, position.y);
        end;
      end;
      rlEnd();

      handleColor := BLACK;
      if (Vector2Distance(center, circlePosition) / pointScale <= 0.5) and (value <= 0.5) then
        handleColor := DARKGRAY;

      DrawCircleLinesV(circlePosition, 4.0, handleColor);

      DrawRectangleV(Vector2Create(8.0, 8.0), Vector2Create(64.0, 64.0), color);
      DrawRectangleLinesEx(RectangleCreate(8.0, 8.0, 64.0, 64.0), 2.0, ColorLerp(color, BLACK, 0.5));

      DrawText(PChar(Format('#%02X%02X%02X' + #10 + '(%d, %d, %d)', [color.r, color.g, color.b, color.r, color.g, color.b])), 8, 80, 20, DARKGRAY);

      DrawText(PChar(Format('triangle count: %d', [triangleCount])), 8, 395, 20, DARKGRAY);

      GuiSliderBar(sliderRectangle, 'value: ', '', @value, 0.0, 1.0);

      DrawFPS(90, 8);
    EndDrawing();
  end;

  CloseWindow();
end.
