program shapes_vector_angle;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  v0, v1, v2: TVector2;
  angle: single;
  angleMode: integer;
  startAngle: single;
  v1Normal, v2Normal: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - vector angle');

  v0 := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);
  v1 := Vector2Add(v0, Vector2Create(100.0, 80.0));
  v2 := Vector2Create(0, 0);

  angle := 0.0;
  angleMode := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    startAngle := 0.0;

    if angleMode = 0 then
      startAngle := -Vector2LineAngle(v0, v1) * RAD2DEG;
    if angleMode = 1 then
      startAngle := 0.0;

    v2 := GetMousePosition();

    if IsKeyPressed(KEY_SPACE) then
    begin
      if angleMode = 0 then angleMode := 1
      else angleMode := 0;
    end;

    if (angleMode = 0) and IsMouseButtonDown(MOUSE_BUTTON_RIGHT) then
      v1 := GetMousePosition();

    if angleMode = 0 then
    begin
      v1Normal := Vector2Normalize(Vector2Subtract(v1, v0));
      v2Normal := Vector2Normalize(Vector2Subtract(v2, v0));
      angle := Vector2Angle(v1Normal, v2Normal) * RAD2DEG;
    end
    else if angleMode = 1 then
    begin
      angle := Vector2LineAngle(v0, v2) * RAD2DEG;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      if angleMode = 0 then
      begin
        DrawText('MODE 0: Angle between V1 and V2', 10, 10, 20, BLACK);
        DrawText('Right Click to Move V1', 10, 30, 20, DARKGRAY);

        DrawLineEx(v0, v1, 2.0, BLACK);
        DrawLineEx(v0, v2, 2.0, RED);

        DrawCircleSector(v0, 40.0, startAngle, startAngle + angle, 32, Fade(GREEN, 0.6));
      end
      else if angleMode = 1 then
      begin
        DrawText('MODE 1: Angle formed by line V1 to V2', 10, 10, 20, BLACK);

        DrawLine(0, screenHeight div 2, screenWidth, screenHeight div 2, LIGHTGRAY);
        DrawLineEx(v0, v2, 2.0, RED);

        DrawCircleSector(v0, 40.0, startAngle, startAngle - angle, 32, Fade(GREEN, 0.6));
      end;

      DrawText('v0', Trunc(v0.x), Trunc(v0.y), 10, DARKGRAY);

      if (angleMode = 0) and (Vector2Subtract(v0, v1).y > 0.0) then
        DrawText('v1', Trunc(v1.x), Trunc(v1.y) - 10, 10, DARKGRAY);
      if (angleMode = 0) and (Vector2Subtract(v0, v1).y < 0.0) then
        DrawText('v1', Trunc(v1.x), Trunc(v1.y), 10, DARKGRAY);

      if angleMode = 1 then
        DrawText('v1', Trunc(v0.x) + 40, Trunc(v0.y), 10, DARKGRAY);

      DrawText('v2', Trunc(v2.x) - 10, Trunc(v2.y) - 10, 10, DARKGRAY);

      DrawText('Press SPACE to change MODE', 460, 10, 20, DARKGRAY);
      DrawText(TextFormat('ANGLE: %2.2f', angle), 10, 70, 20, LIME);

    EndDrawing();
  end;

  CloseWindow();
end.
