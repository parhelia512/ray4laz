program models_waving_cubes;

{$mode objfpc}{$H+}

uses cmem, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  numBlocks = 15;

var
  camera: TCamera3D;
  time: double;
  scale: single;
  cameraTime: double;
  x, y, z: integer;
  blockScale, scatter: single;
  cubePos: TVector3;
  cubeColor: TColorB;
  cubeSize: single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - waving cubes');

  camera.position := Vector3Create(30.0, 20.0, 30.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 70.0;
  camera.projection := CAMERA_PERSPECTIVE;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    time := GetTime();

    scale := (2.0 + sin(time)) * 0.7;

    cameraTime := time * 0.3;
    camera.position.x := cos(cameraTime) * 40.0;
    camera.position.z := sin(cameraTime) * 40.0;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawGrid(10, 5.0);

        for x := 0 to numBlocks - 1 do
          for y := 0 to numBlocks - 1 do
            for z := 0 to numBlocks - 1 do
            begin
              blockScale := (x + y + z) / 30.0;
              scatter := sin(blockScale * 20.0 + time * 4.0);

              cubePos.x := (x - numBlocks / 2.0) * (scale * 3.0) + scatter;
              cubePos.y := (y - numBlocks / 2.0) * (scale * 2.0) + scatter;
              cubePos.z := (z - numBlocks / 2.0) * (scale * 3.0) + scatter;

              cubeColor := ColorFromHSV(((x + y + z) * 18) mod 360, 0.75, 0.9);

              cubeSize := (2.4 - scale) * blockScale;

              DrawCube(cubePos, cubeSize, cubeSize, cubeSize, cubeColor);
            end;

      EndMode3D();

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
