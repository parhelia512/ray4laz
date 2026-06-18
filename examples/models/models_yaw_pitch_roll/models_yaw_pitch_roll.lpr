program models_yaw_pitch_roll;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  texture: TTexture2D;
  pitch, roll, yaw: single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - yaw pitch roll');

  camera.position := Vector3Create(0.0, 50.0, -120.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 30.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/obj/plane.obj'));
  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/models/obj/plane_diffuse.png'));

  SetTextureWrap(texture, TEXTURE_WRAP_REPEAT);

  model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture := texture;

  pitch := 0.0;
  roll := 0.0;
  yaw := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Plane pitch (x-axis) controls
    if IsKeyDown(KEY_DOWN) then pitch += 0.6
    else if IsKeyDown(KEY_UP) then pitch -= 0.6
    else
    begin
      if pitch > 0.3 then pitch -= 0.3
      else if pitch < -0.3 then pitch += 0.3;
    end;

    // Plane yaw (y-axis) controls
    if IsKeyDown(KEY_S) then yaw -= 1.0
    else if IsKeyDown(KEY_A) then yaw += 1.0
    else
    begin
      if yaw > 0.0 then yaw -= 0.5
      else if yaw < 0.0 then yaw += 0.5;
    end;

    // Plane roll (z-axis) controls
    if IsKeyDown(KEY_LEFT) then roll -= 1.0
    else if IsKeyDown(KEY_RIGHT) then roll += 1.0
    else
    begin
      if roll > 0.0 then roll -= 0.5
      else if roll < 0.0 then roll += 0.5;
    end;

    // Transformation matrix for rotations
    model.transform := MatrixRotateXYZ(Vector3Create(DEG2RAD * pitch, DEG2RAD * yaw, DEG2RAD * roll));

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, Vector3Create(0.0, -8.0, 0.0), 1.0, WHITE);
        DrawGrid(10, 10.0);
      EndMode3D();

      DrawRectangle(30, 370, 260, 70, Fade(GREEN, 0.5));
      DrawRectangleLines(30, 370, 260, 70, Fade(DARKGREEN, 0.5));
      DrawText('Pitch controlled with: KEY_UP / KEY_DOWN', 40, 380, 10, DARKGRAY);
      DrawText('Roll controlled with: KEY_LEFT / KEY_RIGHT', 40, 400, 10, DARKGRAY);
      DrawText('Yaw controlled with: KEY_A / KEY_S', 40, 420, 10, DARKGRAY);

      DrawText('(c) WWI Plane Model created by GiaHanLam', screenWidth - 240, screenHeight - 20, 10, DARKGRAY);
    EndDrawing();
  end;

  UnloadModel(model);
  UnloadTexture(texture);
  CloseWindow();
end.
