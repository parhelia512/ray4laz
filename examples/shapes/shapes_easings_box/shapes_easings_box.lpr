program shapes_easings_box;

{$mode objfpc}{$H+}

uses cmem, math, raylib, reasings;

const
  screenWidth = 800;
  screenHeight = 450;

var
  rec: TRectangle;
  rotation, alpha: single;
  state, framesCounter: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - easings box');

  rec := RectangleCreate(screenWidth / 2.0, -100, 100, 100);
  rotation := 0.0;
  alpha := 1.0;
  state := 0;
  framesCounter := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    case state of
      0:
      begin
        Inc(framesCounter);
        rec.y := EaseElasticOut(framesCounter, -100, screenHeight / 2.0 + 100, 120);
        if framesCounter >= 120 then begin framesCounter := 0; state := 1; end;
      end;
      1:
      begin
        Inc(framesCounter);
        rec.height := EaseBounceOut(framesCounter, 100, -90, 120);
        rec.width := EaseBounceOut(framesCounter, 100, screenWidth, 120);
        if framesCounter >= 120 then begin framesCounter := 0; state := 2; end;
      end;
      2:
      begin
        Inc(framesCounter);
        rotation := EaseQuadOut(framesCounter, 0.0, 270.0, 240);
        if framesCounter >= 240 then begin framesCounter := 0; state := 3; end;
      end;
      3:
      begin
        Inc(framesCounter);
        rec.height := EaseCircOut(framesCounter, 10, screenWidth, 120);
        if framesCounter >= 120 then begin framesCounter := 0; state := 4; end;
      end;
      4:
      begin
        Inc(framesCounter);
        alpha := EaseSineOut(framesCounter, 1.0, -1.0, 160);
        if framesCounter >= 160 then begin framesCounter := 0; state := 5; end;
      end;
    end;

    if IsKeyPressed(KEY_SPACE) then
    begin
      rec := RectangleCreate(screenWidth / 2.0, -100, 100, 100);
      rotation := 0.0;
      alpha := 1.0;
      state := 0;
      framesCounter := 0;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawRectanglePro(rec, Vector2Create(rec.width / 2, rec.height / 2), rotation, Fade(BLACK, alpha));
      DrawText('PRESS [SPACE] TO RESET BOX ANIMATION!', 10, screenHeight - 25, 20, LIGHTGRAY);
    EndDrawing();
  end;

  CloseWindow();
end.
