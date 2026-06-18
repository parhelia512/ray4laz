program models_rlgl_solar_system;

{$mode objfpc}{$H+}

uses cmem, raylib, rlgl, math;

const
  screenWidth = 800;
  screenHeight = 450;

procedure DrawSphereBasic(color: TColorB);
var
  rings, slices, i, j: integer;
begin
  rings := 16;
  slices := 16;

  rlCheckRenderBatchLimit((rings + 2) * slices * 6);

  rlBegin(RL_TRIANGLES);
    rlColor4ub(color.r, color.g, color.b, color.a);

    for i := 0 to rings + 1 do
      for j := 0 to slices - 1 do
      begin
        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * sin(DEG2RAD * (j * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * cos(DEG2RAD * (j * 360.0 / slices)));
        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * sin(DEG2RAD * ((j + 1) * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * cos(DEG2RAD * ((j + 1) * 360.0 / slices)));
        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * sin(DEG2RAD * (j * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * cos(DEG2RAD * (j * 360.0 / slices)));

        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * sin(DEG2RAD * (j * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * cos(DEG2RAD * (j * 360.0 / slices)));
        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * sin(DEG2RAD * ((j + 1) * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * i)) * cos(DEG2RAD * ((j + 1) * 360.0 / slices)));
        rlVertex3f(
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * sin(DEG2RAD * ((j + 1) * 360.0 / slices)),
          sin(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))),
          cos(DEG2RAD * (270 + (180.0 / (rings + 1)) * (i + 1))) * cos(DEG2RAD * ((j + 1) * 360.0 / slices)));
      end;
  rlEnd();
end;

var
  camera: TCamera3D;
  sunRadius, earthRadius, earthOrbitRadius, moonRadius, moonOrbitRadius: single;
  rotationSpeed: single;
  earthRotation, earthOrbitRotation: single;
  moonRotation, moonOrbitRotation: single;
begin
  sunRadius := 4.0;
  earthRadius := 0.6;
  earthOrbitRadius := 8.0;
  moonRadius := 0.16;
  moonOrbitRadius := 1.5;

  InitWindow(screenWidth, screenHeight, 'raylib [models] example - rlgl solar system');

  camera.position := Vector3Create(16.0, 16.0, 16.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  rotationSpeed := 0.2;
  earthRotation := 0.0;
  earthOrbitRotation := 0.0;
  moonRotation := 0.0;
  moonOrbitRotation := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    earthRotation += 5.0 * rotationSpeed;
    earthOrbitRotation += (365 / 360.0 * (5.0 * rotationSpeed) * rotationSpeed);
    moonRotation += 2.0 * rotationSpeed;
    moonOrbitRotation += 8.0 * rotationSpeed;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        rlPushMatrix();
          rlScalef(sunRadius, sunRadius, sunRadius);
          DrawSphereBasic(GOLD);
        rlPopMatrix();

        rlPushMatrix();
          rlRotatef(earthOrbitRotation, 0.0, 1.0, 0.0);
          rlTranslatef(earthOrbitRadius, 0.0, 0.0);

          rlPushMatrix();
            rlRotatef(earthRotation, 0.25, 1.0, 0.0);
            rlScalef(earthRadius, earthRadius, earthRadius);
            DrawSphereBasic(BLUE);
          rlPopMatrix();

          rlRotatef(moonOrbitRotation, 0.0, 1.0, 0.0);
          rlTranslatef(moonOrbitRadius, 0.0, 0.0);
          rlRotatef(moonRotation, 0.0, 1.0, 0.0);
          rlScalef(moonRadius, moonRadius, moonRadius);
          DrawSphereBasic(LIGHTGRAY);
        rlPopMatrix();

        DrawCircle3D(Vector3Create(0.0, 0.0, 0.0), earthOrbitRadius, Vector3Create(1, 0, 0), 90.0, Fade(RED, 0.5));
        DrawGrid(20, 1.0);
      EndMode3D();

      DrawText('EARTH ORBITING AROUND THE SUN!', 400, 10, 20, MAROON);
      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
