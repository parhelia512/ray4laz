program models_basic_voxel;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  WORLD_SIZE = 8;

type
  TVoxelGrid = array[0..WORLD_SIZE-1, 0..WORLD_SIZE-1, 0..WORLD_SIZE-1] of boolean;

var
  camera: TCamera3D;
  cubeMesh: TMesh;
  cubeModel: TModel;
  voxels: TVoxelGrid;
  x, y, z: integer;
  screenCenter: TVector2;
  ray: TRay;
  closestDistance: single;
  closestVoxelPosition: TVector3;
  voxelFound: boolean;
  position: TVector3;
  box: TBoundingBox;
  collision: TRayCollision;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - basic voxel');

  DisableCursor();

  camera.position := Vector3Create(-2.0, 0.0, -2.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  cubeMesh := GenMeshCube(1.0, 1.0, 1.0);
  cubeModel := LoadModelFromMesh(cubeMesh);
  cubeModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].color := BEIGE;

  for x := 0 to WORLD_SIZE-1 do
    for y := 0 to WORLD_SIZE-1 do
      for z := 0 to WORLD_SIZE-1 do
        voxels[x, y, z] := true;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_FIRST_PERSON);

    if IsMouseButtonPressed(MOUSE_LEFT_BUTTON) then
    begin
      screenCenter := Vector2Create(GetScreenWidth()/2.0, GetScreenHeight()/2.0);
      ray := GetScreenToWorldRay(screenCenter, camera);

      closestDistance := 99999.0;
      closestVoxelPosition := Vector3Create(-1, -1, -1);
      voxelFound := false;

      for x := 0 to WORLD_SIZE-1 do
        for y := 0 to WORLD_SIZE-1 do
          for z := 0 to WORLD_SIZE-1 do
          begin
            if not voxels[x, y, z] then continue;

            position := Vector3Create(x, y, z);
            box.min := Vector3Create(position.x - 0.5, position.y - 0.5, position.z - 0.5);
            box.max := Vector3Create(position.x + 0.5, position.y + 0.5, position.z + 0.5);

            collision := GetRayCollisionBox(ray, box);
            if collision.hit and (collision.distance < closestDistance) then
            begin
              closestDistance := collision.distance;
              closestVoxelPosition := Vector3Create(x, y, z);
              voxelFound := true;
            end;
          end;

      if voxelFound then
      begin
        voxels[Trunc(closestVoxelPosition.x),
               Trunc(closestVoxelPosition.y),
               Trunc(closestVoxelPosition.z)] := false;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawGrid(10, 1.0);

        for x := 0 to WORLD_SIZE-1 do
          for y := 0 to WORLD_SIZE-1 do
            for z := 0 to WORLD_SIZE-1 do
            begin
              if not voxels[x, y, z] then continue;
              position := Vector3Create(x, y, z);
              DrawModel(cubeModel, position, 1.0, BEIGE);
              DrawCubeWires(position, 1.0, 1.0, 1.0, BLACK);
            end;
      EndMode3D();

      DrawCircle(GetScreenWidth() div 2, GetScreenHeight() div 2, 4, RED);

      DrawText('Left-click a voxel to remove it!', 10, 10, 20, DARKGRAY);
      DrawText('WASD to move, mouse to look around', 10, 35, 10, GRAY);
    EndDrawing();
  end;

  UnloadModel(cubeModel);
  CloseWindow();
end.
