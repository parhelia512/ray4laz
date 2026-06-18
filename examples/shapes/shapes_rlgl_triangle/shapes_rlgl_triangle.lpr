program shapes_rlgl_triangle;

{$mode objfpc}{$H+}

uses cmem, raylib, rlgl;

const
  screenWidth = 800;
  screenHeight = 450;

var
  startingPositions: array[0..2] of TVector2;
  trianglePositions: array[0..2] of TVector2;
  triangleIndex: integer;
  linesMode: boolean;
  handleRadius: single;
  i: integer;
  mouseDelta: TVector2;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - rlgl triangle');

  startingPositions[0] := Vector2Create(400.0, 150.0);
  startingPositions[1] := Vector2Create(300.0, 300.0);
  startingPositions[2] := Vector2Create(500.0, 300.0);

  trianglePositions[0] := startingPositions[0];
  trianglePositions[1] := startingPositions[1];
  trianglePositions[2] := startingPositions[2];

  triangleIndex := -1;
  linesMode := False;
  handleRadius := 8.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_SPACE) then linesMode := not linesMode;

    for i := 0 to 2 do
    begin
      if CheckCollisionPointCircle(GetMousePosition(), trianglePositions[i], handleRadius) and
         IsMouseButtonDown(MOUSE_BUTTON_LEFT) then
      begin
        triangleIndex := i;
        Break;
      end;
    end;

    if triangleIndex <> -1 then
    begin
      mouseDelta := GetMouseDelta();
      trianglePositions[triangleIndex].x := trianglePositions[triangleIndex].x + mouseDelta.x;
      trianglePositions[triangleIndex].y := trianglePositions[triangleIndex].y + mouseDelta.y;
    end;

    if IsMouseButtonReleased(MOUSE_BUTTON_LEFT) then triangleIndex := -1;

    if IsKeyPressed(KEY_LEFT) then rlEnableBackfaceCulling();
    if IsKeyPressed(KEY_RIGHT) then rlDisableBackfaceCulling();

    if IsKeyPressed(KEY_R) then
    begin
      trianglePositions[0] := startingPositions[0];
      trianglePositions[1] := startingPositions[1];
      trianglePositions[2] := startingPositions[2];
      rlEnableBackfaceCulling();
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      if linesMode then
      begin
        rlBegin(RL_LINES);
          rlColor4ub(255, 0, 0, 255);
          rlVertex2f(trianglePositions[0].x, trianglePositions[0].y);
          rlColor4ub(0, 255, 0, 255);
          rlVertex2f(trianglePositions[1].x, trianglePositions[1].y);

          rlColor4ub(0, 255, 0, 255);
          rlVertex2f(trianglePositions[1].x, trianglePositions[1].y);
          rlColor4ub(0, 0, 255, 255);
          rlVertex2f(trianglePositions[2].x, trianglePositions[2].y);

          rlColor4ub(0, 0, 255, 255);
          rlVertex2f(trianglePositions[2].x, trianglePositions[2].y);
          rlColor4ub(255, 0, 0, 255);
          rlVertex2f(trianglePositions[0].x, trianglePositions[0].y);
        rlEnd();
      end
      else
      begin
        rlBegin(RL_TRIANGLES);
          rlColor4ub(255, 0, 0, 255);
          rlVertex2f(trianglePositions[0].x, trianglePositions[0].y);
          rlColor4ub(0, 255, 0, 255);
          rlVertex2f(trianglePositions[1].x, trianglePositions[1].y);
          rlColor4ub(0, 0, 255, 255);
          rlVertex2f(trianglePositions[2].x, trianglePositions[2].y);
        rlEnd();
      end;

      for i := 0 to 2 do
      begin
        if CheckCollisionPointCircle(GetMousePosition(), trianglePositions[i], handleRadius) then
          DrawCircleV(trianglePositions[i], handleRadius, Fade(DARKGRAY, 0.5));
        if i = triangleIndex then
          DrawCircleV(trianglePositions[i], handleRadius, DARKGRAY);
        DrawCircleLinesV(trianglePositions[i], handleRadius, BLACK);
      end;

      DrawText('SPACE: Toggle lines mode', 10, 10, 20, DARKGRAY);
      DrawText('LEFT-RIGHT: Toggle backface culling', 10, 40, 20, DARKGRAY);
      DrawText('MOUSE: Click and drag vertex points', 10, 70, 20, DARKGRAY);
      DrawText('R: Reset triangle to start positions', 10, 100, 20, DARKGRAY);
    EndDrawing();
  end;

  CloseWindow();
end.
