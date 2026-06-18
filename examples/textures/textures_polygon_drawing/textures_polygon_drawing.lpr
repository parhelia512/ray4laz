program textures_polygon_drawing;

{$mode objfpc}{$H+}

uses cmem, raylib, rlgl, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_POINTS = 11;

procedure DrawTexturePoly(texture: TTexture2D; center: TVector2; points, texcoords: PVector2; pointCount: integer; tint: TColorB);
var
  i: integer;
begin
  rlSetTexture(texture.id);
  rlBegin(RL_TRIANGLES);

  rlColor4ub(tint.r, tint.g, tint.b, tint.a);

  for i := 0 to pointCount - 2 do
  begin
    rlTexCoord2f(0.5, 0.5);
    rlVertex2f(center.x, center.y);

    rlTexCoord2f(texcoords[i].x, texcoords[i].y);
    rlVertex2f(points[i].x + center.x, points[i].y + center.y);

    rlTexCoord2f(texcoords[i + 1].x, texcoords[i + 1].y);
    rlVertex2f(points[i + 1].x + center.x, points[i + 1].y + center.y);
  end;

  rlEnd();
  rlSetTexture(0);
end;

var
  texcoords: array[0..MAX_POINTS - 1] of TVector2;
  points: array[0..MAX_POINTS - 1] of TVector2;
  positions: array[0..MAX_POINTS - 1] of TVector2;
  texture: TTexture2D;
  angle: single;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - polygon drawing');

  texcoords[0] := Vector2Create(0.75, 0.0);
  texcoords[1] := Vector2Create(0.25, 0.0);
  texcoords[2] := Vector2Create(0.0, 0.5);
  texcoords[3] := Vector2Create(0.0, 0.75);
  texcoords[4] := Vector2Create(0.25, 1.0);
  texcoords[5] := Vector2Create(0.375, 0.875);
  texcoords[6] := Vector2Create(0.625, 0.875);
  texcoords[7] := Vector2Create(0.75, 1.0);
  texcoords[8] := Vector2Create(1.0, 0.75);
  texcoords[9] := Vector2Create(1.0, 0.5);
  texcoords[10] := Vector2Create(0.75, 0.0);

  for i := 0 to MAX_POINTS - 1 do
  begin
    points[i].x := (texcoords[i].x - 0.5) * 256.0;
    points[i].y := (texcoords[i].y - 0.5) * 256.0;
  end;

  for i := 0 to MAX_POINTS - 1 do
    positions[i] := points[i];

  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/cat.png'));

  angle := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    angle := angle + 1.0;
    for i := 0 to MAX_POINTS - 1 do
      positions[i] := Vector2Rotate(points[i], angle * DEG2RAD);

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawText('textured polygon', 20, 20, 20, DARKGRAY);
      DrawTexturePoly(texture, Vector2Create(GetScreenWidth() / 2.0, GetScreenHeight() / 2.0),
        @positions, @texcoords, MAX_POINTS, WHITE);
    EndDrawing();
  end;

  UnloadTexture(texture);
  CloseWindow();
end.
