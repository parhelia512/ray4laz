program models_directional_billboard;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath, math, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  skillbot: TTexture2D;
  animTimer: single;
  anim: integer;
  dir: single;
  angle: single;
  cameraDir2D: TVector2;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - directional billboard');

  camera.position := Vector3Create(2.0, 1.0, 2.0);
  camera.target := Vector3Create(0.0, 0.5, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  skillbot := LoadTexture(PChar(GetApplicationDirectory + 'resources/skillbot.png'));

  animTimer := 0.0;
  anim := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    animTimer := animTimer + GetFrameTime();

    if animTimer > 0.5 then
    begin
      animTimer := 0.0;
      anim := anim + 1;
    end;

    if anim >= 4 then anim := 0;

    cameraDir2D := Vector2Create(camera.position.x, camera.position.z);
    angle := Vector2Angle(Vector2Create(2.0, 0.0), cameraDir2D);
    dir := Floor((angle / PI) * 4.0 + 0.25);

    if dir < 0.0 then
      dir := 8.0 - Abs(Trunc(dir));

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawGrid(10, 1.0);
        DrawBillboardPro(camera, skillbot,
          RectangleCreate(anim*24.0, dir*24.0, 24.0, 24.0),
          Vector3Zero(),
          Vector3Create(0.0, 1.0, 0.0),
          Vector2One(),
          Vector2Create(0.5, 0.0),
          0, WHITE);
      EndMode3D();

      DrawText(PChar(Format('animation: %d', [anim])), 10, 10, 20, DARKGRAY);
      DrawText(PChar(Format('direction frame: %.0f', [dir])), 10, 40, 20, DARKGRAY);
    EndDrawing();
  end;

  UnloadTexture(skillbot);
  CloseWindow();
end.
