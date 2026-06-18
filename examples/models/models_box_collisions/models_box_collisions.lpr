program models_box_collisions;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  playerPosition: TVector3;
  playerSize: TVector3;
  playerColor: TColorB;
  enemyBoxPos: TVector3;
  enemyBoxSize: TVector3;
  enemySpherePos: TVector3;
  enemySphereSize: single;
  collision: boolean;
  playerBox: TBoundingBox;
  enemyBox: TBoundingBox;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - box collisions');

  camera.position := Vector3Create(0.0, 10.0, 10.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  playerPosition := Vector3Create(0.0, 1.0, 2.0);
  playerSize := Vector3Create(1.0, 2.0, 1.0);
  playerColor := GREEN;

  enemyBoxPos := Vector3Create(-4.0, 1.0, 0.0);
  enemyBoxSize := Vector3Create(2.0, 2.0, 2.0);

  enemySpherePos := Vector3Create(4.0, 0.0, 0.0);
  enemySphereSize := 1.5;

  collision := false;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyDown(KEY_RIGHT) then playerPosition.x := playerPosition.x + 0.2
    else if IsKeyDown(KEY_LEFT) then playerPosition.x := playerPosition.x - 0.2
    else if IsKeyDown(KEY_DOWN) then playerPosition.z := playerPosition.z + 0.2
    else if IsKeyDown(KEY_UP) then playerPosition.z := playerPosition.z - 0.2;

    collision := false;

    playerBox.min := Vector3Create(playerPosition.x - playerSize.x/2,
                                   playerPosition.y - playerSize.y/2,
                                   playerPosition.z - playerSize.z/2);
    playerBox.max := Vector3Create(playerPosition.x + playerSize.x/2,
                                   playerPosition.y + playerSize.y/2,
                                   playerPosition.z + playerSize.z/2);

    enemyBox.min := Vector3Create(enemyBoxPos.x - enemyBoxSize.x/2,
                                  enemyBoxPos.y - enemyBoxSize.y/2,
                                  enemyBoxPos.z - enemyBoxSize.z/2);
    enemyBox.max := Vector3Create(enemyBoxPos.x + enemyBoxSize.x/2,
                                  enemyBoxPos.y + enemyBoxSize.y/2,
                                  enemyBoxPos.z + enemyBoxSize.z/2);

    if CheckCollisionBoxes(playerBox, enemyBox) then collision := true;
    if CheckCollisionBoxSphere(playerBox, enemySpherePos, enemySphereSize) then collision := true;

    if collision then playerColor := RED
    else playerColor := GREEN;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawCube(enemyBoxPos, enemyBoxSize.x, enemyBoxSize.y, enemyBoxSize.z, GRAY);
        DrawCubeWires(enemyBoxPos, enemyBoxSize.x, enemyBoxSize.y, enemyBoxSize.z, DARKGRAY);

        DrawSphere(enemySpherePos, enemySphereSize, GRAY);
        DrawSphereWires(enemySpherePos, enemySphereSize, 16, 16, DARKGRAY);

        DrawCubeV(playerPosition, playerSize, playerColor);

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawText('Move player with arrow keys to collide', 220, 40, 20, GRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
