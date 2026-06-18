program models_orthographic_projection;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  FOVY_PERSPECTIVE = 45.0;
  WIDTH_ORTHOGRAPHIC = 10.0;

var
  camera: TCamera3D;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - orthographic projection');

  camera.position := Vector3Create(0.0, 10.0, 10.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := FOVY_PERSPECTIVE;
  camera.projection := CAMERA_PERSPECTIVE;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_SPACE) then
    begin
      if camera.projection = CAMERA_PERSPECTIVE then
      begin
        camera.fovy := WIDTH_ORTHOGRAPHIC;
        camera.projection := CAMERA_ORTHOGRAPHIC;
      end
      else
      begin
        camera.fovy := FOVY_PERSPECTIVE;
        camera.projection := CAMERA_PERSPECTIVE;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawCube(Vector3Create(-4.0, 0.0, 2.0), 2.0, 5.0, 2.0, RED);
        DrawCubeWires(Vector3Create(-4.0, 0.0, 2.0), 2.0, 5.0, 2.0, GOLD);
        DrawCubeWires(Vector3Create(-4.0, 0.0, -2.0), 3.0, 6.0, 2.0, MAROON);

        DrawSphere(Vector3Create(-1.0, 0.0, -2.0), 1.0, GREEN);
        DrawSphereWires(Vector3Create(1.0, 0.0, 2.0), 2.0, 16, 16, LIME);

        DrawCylinder(Vector3Create(4.0, 0.0, -2.0), 1.0, 2.0, 3.0, 4, SKYBLUE);
        DrawCylinderWires(Vector3Create(4.0, 0.0, -2.0), 1.0, 2.0, 3.0, 4, DARKBLUE);
        DrawCylinderWires(Vector3Create(4.5, -1.0, 2.0), 1.0, 1.0, 2.0, 6, BROWN);

        DrawCylinder(Vector3Create(1.0, 0.0, -4.0), 0.0, 1.5, 3.0, 8, GOLD);
        DrawCylinderWires(Vector3Create(1.0, 0.0, -4.0), 0.0, 1.5, 3.0, 8, PINK);

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText('Press Spacebar to switch camera type', 10, GetScreenHeight() - 30, 20, DARKGRAY);

      if camera.projection = CAMERA_ORTHOGRAPHIC then
        DrawText('ORTHOGRAPHIC', 10, 40, 20, BLACK)
      else if camera.projection = CAMERA_PERSPECTIVE then
        DrawText('PERSPECTIVE', 10, 40, 20, BLACK);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
