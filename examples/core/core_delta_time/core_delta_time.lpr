program core_delta_time;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  currentFps: integer;
  deltaCircle, frameCircle: TVector2;
  speed, circleRadius: single;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - delta time');

  currentFps := 60;

  deltaCircle := Vector2Create(0, screenHeight / 3.0);
  frameCircle := Vector2Create(0, screenHeight * (2.0 / 3.0));

  speed := 10.0;
  circleRadius := 32.0;

  SetTargetFPS(currentFps);

  while not WindowShouldClose() do
  begin
    // Adjust the FPS target based on the mouse wheel
    if GetMouseWheelMove() <> 0 then
    begin
      currentFps := currentFps + Round(GetMouseWheelMove());
      if currentFps < 0 then currentFps := 0;
      SetTargetFPS(currentFps);
    end;

    deltaCircle.x := deltaCircle.x + GetFrameTime() * 6.0 * speed;
    frameCircle.x := frameCircle.x + 0.1 * speed;

    if deltaCircle.x > screenWidth then deltaCircle.x := 0;
    if frameCircle.x > screenWidth then frameCircle.x := 0;

    if IsKeyPressed(KEY_R) then
    begin
      deltaCircle.x := 0;
      frameCircle.x := 0;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawCircleV(deltaCircle, circleRadius, RED);
      DrawCircleV(frameCircle, circleRadius, BLUE);

      if currentFps <= 0 then
        DrawText(TextFormat('FPS: unlimited (%i)', GetFPS()), 10, 10, 20, DARKGRAY)
      else
        DrawText(TextFormat('FPS: %i (target: %i)', GetFPS(), currentFps), 10, 10, 20, DARKGRAY);
      DrawText(TextFormat('Frame time: %02.02f ms', GetFrameTime()), 10, 30, 20, DARKGRAY);
      DrawText('Use the scroll wheel to change the fps limit, r to reset', 10, 50, 20, DARKGRAY);

      DrawText('FUNC: x += GetFrameTime()*speed', 10, 90, 20, RED);
      DrawText('FUNC: x += speed', 10, 240, 20, BLUE);

    EndDrawing();
  end;

  CloseWindow();
end.
