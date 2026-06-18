program shapes_ball_physics;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_BALLS = 5000;

type
  TBall = record
    position: TVector2;
    speed: TVector2;
    prevPosition: TVector2;
    radius: single;
    friction, elasticity: single;
    color: TColorB;
    grabbed: boolean;
  end;

var
  balls: array[0..MAX_BALLS - 1] of TBall;
  ballCount: integer;
  grabbedBall: integer;
  pressOffset: TVector2;
  gravity: single;
  windowPosition: TVector2;
  i: integer;
  delta: single;
  mousePos: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - ball physics');

  balls[0].position := Vector2Create(GetScreenWidth() / 2.0, GetScreenHeight() / 2.0);
  balls[0].speed := Vector2Create(200, 200);
  balls[0].prevPosition := Vector2Create(0, 0);
  balls[0].radius := 40;
  balls[0].friction := 0.99;
  balls[0].elasticity := 0.9;
  balls[0].color := BLUE;
  balls[0].grabbed := False;

  ballCount := 1;
  grabbedBall := -1;
  pressOffset := Vector2Create(0, 0);
  gravity := 100;
  windowPosition := GetWindowPosition();

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    delta := GetFrameTime();
    mousePos := GetMousePosition();

    // Checks if a ball was grabbed
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
      for i := ballCount - 1 downto 0 do
      begin
        pressOffset.x := mousePos.x - balls[i].position.x;
        pressOffset.y := mousePos.y - balls[i].position.y;

        if Sqrt(Sqr(pressOffset.x) + Sqr(pressOffset.y)) <= balls[i].radius then
        begin
          balls[i].grabbed := True;
          grabbedBall := i;
          Break;
        end;
      end;
    end;

    // Releases any ball that was grabbed
    if IsMouseButtonReleased(MOUSE_BUTTON_LEFT) then
    begin
      if grabbedBall >= 0 then
      begin
        balls[grabbedBall].grabbed := False;
        grabbedBall := -1;
      end;
    end;

    // Creates a new ball
    if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) or (IsKeyDown(KEY_LEFT_CONTROL) and IsMouseButtonDown(MOUSE_BUTTON_RIGHT)) then
    begin
      if ballCount < MAX_BALLS then
      begin
        balls[ballCount].position := mousePos;
        balls[ballCount].speed := Vector2Create(GetRandomValue(-300, 300), GetRandomValue(-300, 300));
        balls[ballCount].prevPosition := Vector2Create(0, 0);
        balls[ballCount].radius := 20.0 + GetRandomValue(0, 30);
        balls[ballCount].friction := 0.99;
        balls[ballCount].elasticity := 0.9;
        balls[ballCount].color := ColorCreate(GetRandomValue(0, 255), GetRandomValue(0, 255), GetRandomValue(0, 255), 255);
        balls[ballCount].grabbed := False;
        Inc(ballCount);
      end;
    end;

    // Get window position change for shaking
    if Vector2Length(Vector2Subtract(windowPosition, GetWindowPosition())) > 5.0 then
    begin
      for i := 0 to ballCount - 1 do
      begin
        if not balls[i].grabbed then
          balls[i].speed := Vector2Add(balls[i].speed, Vector2Scale(Vector2Subtract(windowPosition, GetWindowPosition()), 10.0));
      end;
    end;

    // Shake balls
    if IsMouseButtonPressed(MOUSE_BUTTON_MIDDLE) then
    begin
      for i := 0 to ballCount - 1 do
      begin
        if not balls[i].grabbed then
          balls[i].speed := Vector2Create(GetRandomValue(-2000, 2000), GetRandomValue(-2000, 2000));
      end;
    end;

    // Changes gravity
    gravity := gravity + GetMouseWheelMove() * 5;

    // Updates each ball state
    for i := 0 to ballCount - 1 do
    begin
      if not balls[i].grabbed then
      begin
        balls[i].position.x := balls[i].position.x + balls[i].speed.x * delta;
        balls[i].position.y := balls[i].position.y + balls[i].speed.y * delta;

        if (balls[i].position.x + balls[i].radius) >= screenWidth then
        begin
          balls[i].position.x := screenWidth - balls[i].radius;
          balls[i].speed.x := -balls[i].speed.x * balls[i].elasticity;
        end
        else if (balls[i].position.x - balls[i].radius) <= 0 then
        begin
          balls[i].position.x := balls[i].radius;
          balls[i].speed.x := -balls[i].speed.x * balls[i].elasticity;
        end;

        if (balls[i].position.y + balls[i].radius) >= screenHeight then
        begin
          balls[i].position.y := screenHeight - balls[i].radius;
          balls[i].speed.y := -balls[i].speed.y * balls[i].elasticity;
        end
        else if (balls[i].position.y - balls[i].radius) <= 0 then
        begin
          balls[i].position.y := balls[i].radius;
          balls[i].speed.y := -balls[i].speed.y * balls[i].elasticity;
        end;

        balls[i].speed.x := balls[i].speed.x * balls[i].friction;
        balls[i].speed.y := balls[i].speed.y * balls[i].friction + gravity;
      end
      else
      begin
        balls[i].position.x := mousePos.x - pressOffset.x;
        balls[i].position.y := mousePos.y - pressOffset.y;
        balls[i].speed.x := (balls[i].position.x - balls[i].prevPosition.x) / delta;
        balls[i].speed.y := (balls[i].position.y - balls[i].prevPosition.y) / delta;
        balls[i].prevPosition := balls[i].position;
      end;
    end;

    windowPosition := GetWindowPosition();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to ballCount - 1 do
      begin
        DrawCircleV(balls[i].position, balls[i].radius, balls[i].color);
        DrawCircleLinesV(balls[i].position, balls[i].radius, BLACK);
      end;

      DrawText('grab a ball by pressing with the mouse and throw it by releasing', 10, 10, 10, DARKGRAY);
      DrawText('right click to create new balls (keep left control pressed to create a lot)', 10, 30, 10, DARKGRAY);
      DrawText('use mouse wheel to change gravity', 10, 50, 10, DARKGRAY);
      DrawText('middle click to shake', 10, 70, 10, DARKGRAY);
      DrawText(TextFormat('BALL COUNT: %d', ballCount), 10, GetScreenHeight() - 70, 20, BLACK);
      DrawText(TextFormat('GRAVITY: %.2f', gravity), 10, GetScreenHeight() - 40, 20, BLACK);

    EndDrawing();
  end;

  CloseWindow();
end.
