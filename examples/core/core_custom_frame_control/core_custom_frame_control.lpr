program core_custom_frame_control;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  previousTime: Double;
  currentTime: Double;
  updateDrawTime: Double;
  waitTimeD: Double;
  deltaTime: Single;
  timeCounter: Single;
  position: Single;
  pause: Boolean;
  targetFPS: Integer;
  i: Integer;

begin
  // Initialization
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - custom frame control');

  // Custom timing variables
  previousTime := GetTime();    // Previous time measure
  currentTime := 0.0;           // Current time measure
  updateDrawTime := 0.0;        // Update + Draw time
  waitTimeD := 0.0;              // Wait time (if target fps required)
  deltaTime := 0.0;             // Frame time (Update + Draw + Wait time)

  timeCounter := 0.0;           // Accumulative time counter (seconds)
  position := 0.0;              // Circle position
  pause := False;               // Pause control flag

  targetFPS := 60;              // Our initial target fps

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    PollInputEvents();          // Poll input events (SUPPORT_CUSTOM_FRAME_CONTROL)

    if IsKeyPressed(KEY_SPACE) then
      pause := not pause;

    if IsKeyPressed(KEY_UP) then
      targetFPS := targetFPS + 20
    else if IsKeyPressed(KEY_DOWN) then
      targetFPS := targetFPS - 20;

    if targetFPS < 0 then
      targetFPS := 0;

    if not pause then
    begin
      position := position + 200 * deltaTime;  // We move at 200 pixels per second
      if position >= GetScreenWidth() then
        position := 0;
      timeCounter := timeCounter + deltaTime;   // We count time (seconds)
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to Trunc(GetScreenWidth() / 200) - 1 do
        DrawRectangle(200 * i, 0, 1, GetScreenHeight(), SKYBLUE);

      DrawCircle(Trunc(position), Trunc(GetScreenHeight() / 2 - 25), 50, RED);

      DrawText(PChar(Format('%.0f ms', [timeCounter * 1000.0])), Trunc(position - 40), Trunc(GetScreenHeight() / 2 - 100), 20, MAROON);
      DrawText(PChar(Format('PosX: %.0f', [position])), Trunc(position - 50), Trunc(GetScreenHeight() / 2 + 40), 20, BLACK);

      DrawText('Circle is moving at a constant 200 pixels/sec,'#10'independently of the frame rate.', 10, 10, 20, DARKGRAY);
      DrawText('PRESS SPACE to PAUSE MOVEMENT', 10, GetScreenHeight() - 60, 20, GRAY);
      DrawText('PRESS UP | DOWN to CHANGE TARGET FPS', 10, GetScreenHeight() - 30, 20, GRAY);
      DrawText(PChar(Format('TARGET FPS: %d', [targetFPS])), GetScreenWidth() - 220, 10, 20, LIME);

      if deltaTime <> 0 then
        DrawText(PChar(Format('CURRENT FPS: %d', [Trunc(1.0 / deltaTime)])), GetScreenWidth() - 220, 40, 20, GREEN);

    EndDrawing();

    // NOTE: In case raylib is configured to SUPPORT_CUSTOM_FRAME_CONTROL,
    // Events polling, screen buffer swap and frame time control must be managed by the user

    SwapScreenBuffer();         // Flip the back buffer to screen (front buffer)

    currentTime := GetTime();
    updateDrawTime := currentTime - previousTime;

    if targetFPS > 0 then       // We want a fixed frame rate
    begin
      waitTimeD := (1.0 / targetFPS) - updateDrawTime;
      if waitTimeD > 0.0 then
      begin
        WaitTime(waitTimeD);
        currentTime := GetTime();
        deltaTime := currentTime - previousTime;
      end;
    end
    else
      deltaTime := updateDrawTime;    // Framerate could be variable

    previousTime := currentTime;
  end;

  // De-Initialization
  CloseWindow();
end.
