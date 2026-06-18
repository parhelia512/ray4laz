program models_billboard_rendering;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  bill: TTexture2D;
  billPositionStatic: TVector3;
  billPositionRotating: TVector3;
  source: TRectangle;
  billUp: TVector3;
  size: TVector2;
  origin: TVector2;
  distanceStatic: single;
  distanceRotating: single;
  rotation: single;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - billboard rendering');

  camera.position := Vector3Create(5.0, 4.0, 5.0);
  camera.target := Vector3Create(0.0, 2.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  bill := LoadTexture(PChar(GetApplicationDirectory + 'resources/billboard.png'));
  billPositionStatic := Vector3Create(0.0, 2.0, 0.0);
  billPositionRotating := Vector3Create(1.0, 2.0, 1.0);

  source := RectangleCreate(0.0, 0.0, bill.width, bill.height);

  billUp := Vector3Create(0.0, 1.0, 0.0);

  size := Vector2Create(source.width / source.height, 1.0);

  origin := Vector2Scale(size, 0.5);

  distanceStatic := 0.0;
  distanceRotating := 0.0;
  rotation := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    rotation := rotation + 0.4;
    distanceStatic := Vector3Distance(camera.position, billPositionStatic);
    distanceRotating := Vector3Distance(camera.position, billPositionRotating);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawGrid(10, 1.0);

        if distanceStatic > distanceRotating then
        begin
          DrawBillboard(camera, bill, billPositionStatic, 2.0, WHITE);
          DrawBillboardPro(camera, bill, source, billPositionRotating, billUp, size, origin, rotation, WHITE);
        end
        else
        begin
          DrawBillboardPro(camera, bill, source, billPositionRotating, billUp, size, origin, rotation, WHITE);
          DrawBillboard(camera, bill, billPositionStatic, 2.0, WHITE);
        end;
      EndMode3D();

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadTexture(bill);
  CloseWindow();
end.
