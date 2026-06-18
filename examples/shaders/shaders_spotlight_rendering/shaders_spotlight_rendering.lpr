program shaders_spotlight_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  MAX_SPOTS = 3;
  MAX_STARS = 400;

type
  TSpot = record
    position: TVector2;
    speed: TVector2;
    inner, radius: single;
    positionLoc, innerLoc, radiusLoc: cardinal;
  end;

  TStar = record
    position: TVector2;
    speed: TVector2;
  end;

var
  texRay: TTexture2D;
  stars: array[0..MAX_STARS - 1] of TStar;
  frameCounter: integer;
  shdrSpot: TShader;
  spots: array[0..MAX_SPOTS - 1] of TSpot;
  wLoc: cardinal;
  sw: single;
  i, n, m: integer;
  posName, innerName, radiusName: string;
  mp: TVector2;
procedure ResetStar(var star: TStar);
begin
  star.position := Vector2Create(GetScreenWidth() / 2.0, GetScreenHeight() / 2.0);
  star.speed.x := GetRandomValue(-1000, 1000) / 100.0;
  star.speed.y := GetRandomValue(-1000, 1000) / 100.0;

  while Abs(star.speed.x) + Abs(star.speed.y) <= 1 do
  begin
    star.speed.x := GetRandomValue(-1000, 1000) / 100.0;
    star.speed.y := GetRandomValue(-1000, 1000) / 100.0;
  end;

  star.position := Vector2Add(star.position, Vector2Multiply(star.speed, Vector2Create(8.0, 8.0)));
end;

procedure UpdateStar(var star: TStar);
begin
  star.position := Vector2Add(star.position, star.speed);
  if (star.position.x < 0) or (star.position.x > GetScreenWidth()) or
     (star.position.y < 0) or (star.position.y > GetScreenHeight()) then
    ResetStar(star);
end;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - spotlight rendering');
  HideCursor();

  texRay := LoadTexture(PChar(GetApplicationDirectory + 'resources/raysan.png'));

  for n := 0 to MAX_STARS - 1 do
    ResetStar(stars[n]);

  for m := 0 to Trunc(screenWidth / 2.0) - 1 do
    for n := 0 to MAX_STARS - 1 do
      UpdateStar(stars[n]);

  frameCounter := 0;

  shdrSpot := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/spotlight.fs', GLSL_VERSION)));

  for i := 0 to MAX_SPOTS - 1 do
  begin
    posName := 'spots[' + IntToStr(i) + '].pos';
    innerName := 'spots[' + IntToStr(i) + '].inner';
    radiusName := 'spots[' + IntToStr(i) + '].radius';

    spots[i].positionLoc := GetShaderLocation(shdrSpot, PChar(posName));
    spots[i].innerLoc := GetShaderLocation(shdrSpot, PChar(innerName));
    spots[i].radiusLoc := GetShaderLocation(shdrSpot, PChar(radiusName));
  end;

  wLoc := GetShaderLocation(shdrSpot, 'screenWidth');
  sw := GetScreenWidth();
  SetShaderValue(shdrSpot, wLoc, @sw, SHADER_UNIFORM_FLOAT);

  for i := 0 to MAX_SPOTS - 1 do
  begin
    spots[i].position.x := GetRandomValue(64, screenWidth - 64);
    spots[i].position.y := GetRandomValue(64, screenHeight - 64);
    spots[i].speed := Vector2Create(0, 0);

    while (Abs(spots[i].speed.x) + Abs(spots[i].speed.y)) < 2 do
    begin
      spots[i].speed.x := GetRandomValue(-400, 40) / 25.0;
      spots[i].speed.y := GetRandomValue(-400, 40) / 25.0;
    end;

    spots[i].inner := 28.0 * (i + 1);
    spots[i].radius := 48.0 * (i + 1);

    SetShaderValue(shdrSpot, spots[i].positionLoc, @spots[i].position.x, SHADER_UNIFORM_VEC2);
    SetShaderValue(shdrSpot, spots[i].innerLoc, @spots[i].inner, SHADER_UNIFORM_FLOAT);
    SetShaderValue(shdrSpot, spots[i].radiusLoc, @spots[i].radius, SHADER_UNIFORM_FLOAT);
  end;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    Inc(frameCounter);

    for n := 0 to MAX_STARS - 1 do
      UpdateStar(stars[n]);

    for i := 0 to MAX_SPOTS - 1 do
    begin
      if i = 0 then
      begin
  
        mp := GetMousePosition();
        spots[i].position.x := mp.x;
        spots[i].position.y := screenHeight - mp.y;
      end
      else
      begin
        spots[i].position.x := spots[i].position.x + spots[i].speed.x;
        spots[i].position.y := spots[i].position.y + spots[i].speed.y;
        if spots[i].position.x < 64 then spots[i].speed.x := -spots[i].speed.x;
        if spots[i].position.x > (screenWidth - 64) then spots[i].speed.x := -spots[i].speed.x;
        if spots[i].position.y < 64 then spots[i].speed.y := -spots[i].speed.y;
        if spots[i].position.y > (screenHeight - 64) then spots[i].speed.y := -spots[i].speed.y;
      end;
      SetShaderValue(shdrSpot, spots[i].positionLoc, @spots[i].position.x, SHADER_UNIFORM_VEC2);
    end;

    BeginDrawing();
      ClearBackground(DARKBLUE);

      for n := 0 to MAX_STARS - 1 do
        DrawRectangle(Trunc(stars[n].position.x), Trunc(stars[n].position.y), 2, 2, WHITE);

      for i := 0 to 15 do
      begin
        DrawTexture(texRay,
          Trunc((screenWidth / 2.0) + Cos((frameCounter + i * 8) / 51.45) * (screenWidth / 2.2) - 32),
          Trunc((screenHeight / 2.0) + Sin((frameCounter + i * 8) / 17.87) * (screenHeight / 4.2)), WHITE);
      end;

      BeginShaderMode(shdrSpot);
        DrawRectangle(0, 0, screenWidth, screenHeight, WHITE);
      EndShaderMode();

      DrawFPS(10, 10);
      DrawText('Move the mouse!', 10, 30, 20, GREEN);
      DrawText('Pitch Black', Trunc(screenWidth * 0.2), screenHeight div 2, 20, GREEN);
      DrawText('Dark', Trunc(screenWidth * 0.66), screenHeight div 2, 20, GREEN);

    EndDrawing();
  end;

  UnloadTexture(texRay);
  UnloadShader(shdrSpot);
  CloseWindow();
end.
