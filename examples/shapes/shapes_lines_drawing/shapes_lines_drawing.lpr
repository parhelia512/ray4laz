program shapes_lines_drawing;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  startText: boolean;
  mousePositionPrevious: TVector2;
  canvas: TRenderTexture2D;
  lineThickness, lineHue: single;
  leftButtonDown, rightButtonDown: boolean;
  drawColor: TColorB;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - lines drawing');

  startText := True;
  mousePositionPrevious := GetMousePosition();
  canvas := LoadRenderTexture(screenWidth, screenHeight);
  lineThickness := 8.0;
  lineHue := 0.0;

  BeginTextureMode(canvas);
    ClearBackground(RAYWHITE);
  EndTextureMode();

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and startText then
      startText := False;

    if IsMouseButtonPressed(MOUSE_BUTTON_MIDDLE) then
    begin
      BeginTextureMode(canvas);
        ClearBackground(RAYWHITE);
      EndTextureMode();
    end;

    leftButtonDown := IsMouseButtonDown(MOUSE_BUTTON_LEFT);
    rightButtonDown := IsMouseButtonDown(MOUSE_BUTTON_RIGHT);

    if leftButtonDown or rightButtonDown then
    begin
      drawColor := WHITE;

      if leftButtonDown then
      begin
        lineHue := lineHue + Vector2Distance(mousePositionPrevious, GetMousePosition()) / 3.0;
        while lineHue >= 360.0 do
          lineHue := lineHue - 360.0;
        drawColor := ColorFromHSV(lineHue, 1.0, 1.0);
      end
      else if rightButtonDown then
        drawColor := RAYWHITE;

      BeginTextureMode(canvas);
        DrawCircleV(mousePositionPrevious, lineThickness / 2.0, drawColor);
        DrawCircleV(GetMousePosition(), lineThickness / 2.0, drawColor);
        DrawLineEx(mousePositionPrevious, GetMousePosition(), lineThickness, drawColor);
      EndTextureMode();
    end;

    lineThickness := lineThickness + GetMouseWheelMove();
    if lineThickness < 1.0 then lineThickness := 1.0;
    if lineThickness > 500.0 then lineThickness := 500.0;

    mousePositionPrevious := GetMousePosition();

    BeginDrawing();
      DrawTextureRec(canvas.texture,
        RectangleCreate(0.0, 0.0, canvas.texture.width, -canvas.texture.height),
        Vector2Zero(), WHITE);

      if not leftButtonDown then
        DrawCircleLinesV(GetMousePosition(), lineThickness / 2.0, ColorCreate(127, 127, 127, 127));

      if startText then
        DrawText('try clicking and dragging!', 275, 215, 20, LIGHTGRAY);

    EndDrawing();
  end;

  UnloadRenderTexture(canvas);
  CloseWindow();
end.
