program shapes_easings_rectangles;

{$mode objfpc}{$H+}

uses cmem, math, raylib, reasings;

const
  screenWidth = 800;
  screenHeight = 450;
  RECS_WIDTH = 50;
  RECS_HEIGHT = 50;
  MAX_RECS_X = 800 div RECS_WIDTH;
  MAX_RECS_Y = 450 div RECS_HEIGHT;
  PLAY_TIME_IN_FRAMES = 240;

var
  recs: array[0..MAX_RECS_X * MAX_RECS_Y - 1] of TRectangle;
  rotation: single;
  framesCounter, state: integer;
  x, y, i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - easings rectangles');

  for y := 0 to MAX_RECS_Y - 1 do
    for x := 0 to MAX_RECS_X - 1 do
    begin
      recs[y * MAX_RECS_X + x].x := RECS_WIDTH / 2.0 + RECS_WIDTH * x;
      recs[y * MAX_RECS_X + x].y := RECS_HEIGHT / 2.0 + RECS_HEIGHT * y;
      recs[y * MAX_RECS_X + x].width := RECS_WIDTH;
      recs[y * MAX_RECS_X + x].height := RECS_HEIGHT;
    end;

  rotation := 0.0;
  framesCounter := 0;
  state := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if state = 0 then
    begin
      Inc(framesCounter);
      for i := 0 to MAX_RECS_X * MAX_RECS_Y - 1 do
      begin
        recs[i].height := EaseCircOut(framesCounter, RECS_HEIGHT, -RECS_HEIGHT, PLAY_TIME_IN_FRAMES);
        recs[i].width := EaseCircOut(framesCounter, RECS_WIDTH, -RECS_WIDTH, PLAY_TIME_IN_FRAMES);
        if recs[i].height < 0 then recs[i].height := 0;
        if recs[i].width < 0 then recs[i].width := 0;
        if (recs[i].height = 0) and (recs[i].width = 0) then state := 1;
        rotation := EaseLinearIn(framesCounter, 0.0, 360.0, PLAY_TIME_IN_FRAMES);
      end;
    end
    else if (state = 1) and IsKeyPressed(KEY_SPACE) then
    begin
      framesCounter := 0;
      for i := 0 to MAX_RECS_X * MAX_RECS_Y - 1 do
      begin
        recs[i].height := RECS_HEIGHT;
        recs[i].width := RECS_WIDTH;
      end;
      state := 0;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      if state = 0 then
      begin
        for i := 0 to MAX_RECS_X * MAX_RECS_Y - 1 do
          DrawRectanglePro(recs[i], Vector2Create(recs[i].width / 2, recs[i].height / 2), rotation, RED);
      end
      else if state = 1 then
        DrawText('PRESS [SPACE] TO PLAY AGAIN!', 240, 200, 20, GRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
