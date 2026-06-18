program shapes_starfield_effect;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  STAR_COUNT = 420;

var
  bgColor: TColorB;
  speed: single;
  drawLines: boolean;
  stars: array[0..STAR_COUNT - 1] of TVector3;
  starsScreenPos: array[0..STAR_COUNT - 1] of TVector2;
  i: integer;
  dt, t, radius: single;
  startPos: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - starfield effect');

  bgColor := ColorLerp(DARKBLUE, BLACK, 0.69);
  speed := 10.0 / 9.0;
  drawLines := True;

  for i := 0 to STAR_COUNT - 1 do
  begin
    stars[i].x := GetRandomValue(-screenWidth div 2, screenWidth div 2);
    stars[i].y := GetRandomValue(-screenHeight div 2, screenHeight div 2);
    stars[i].z := 1.0;
  end;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if GetMouseWheelMove() <> 0 then
      speed := speed + 2.0 * GetMouseWheelMove() / 9.0;
    if speed < 0.0 then speed := 0.1
    else if speed > 2.0 then speed := 2.0;

    if IsKeyPressed(KEY_SPACE) then drawLines := not drawLines;

    dt := GetFrameTime();
    for i := 0 to STAR_COUNT - 1 do
    begin
      stars[i].z := stars[i].z - dt * speed;

      starsScreenPos[i] := Vector2Create(
        screenWidth * 0.5 + stars[i].x / stars[i].z,
        screenHeight * 0.5 + stars[i].y / stars[i].z
      );

      if (stars[i].z < 0.0) or (starsScreenPos[i].x < 0) or (starsScreenPos[i].y < 0.0) or
         (starsScreenPos[i].x > screenWidth) or (starsScreenPos[i].y > screenHeight) then
      begin
        stars[i].x := GetRandomValue(-screenWidth div 2, screenWidth div 2);
        stars[i].y := GetRandomValue(-screenHeight div 2, screenHeight div 2);
        stars[i].z := 1.0;
      end;
    end;

    BeginDrawing();
      ClearBackground(bgColor);

      for i := 0 to STAR_COUNT - 1 do
      begin
        if drawLines then
        begin
          t := Clamp(stars[i].z + 1.0 / 32.0, 0.0, 1.0);
          if (t - stars[i].z) > 1e-3 then
          begin
            startPos := Vector2Create(
              screenWidth * 0.5 + stars[i].x / t,
              screenHeight * 0.5 + stars[i].y / t
            );
            DrawLineV(startPos, starsScreenPos[i], RAYWHITE);
          end;
        end
        else
        begin
          radius := Lerp(stars[i].z, 1.0, 5.0);
          DrawCircleV(starsScreenPos[i], radius, RAYWHITE);
        end;
      end;

      DrawText(TextFormat('[MOUSE WHEEL] Current Speed: %.0f', 9.0 * speed / 2.0), 10, 40, 20, RAYWHITE);
      if drawLines then
        DrawText('[SPACE] Current draw mode: Lines', 10, 70, 20, RAYWHITE)
      else
        DrawText('[SPACE] Current draw mode: Circles', 10, 70, 20, RAYWHITE);

      DrawFPS(10, 10);

    EndDrawing();
  end;

  CloseWindow();
end.
