program models_mesh_picking;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath, sysutils, math;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  ray: TRay;
  tower: TModel;
  texture: TTexture2D;
  towerPos: TVector3;
  towerBBox: TBoundingBox;
  g0, g1, g2, g3: TVector3;
  ta, tb, tc: TVector3;
  bary: TVector3;
  sp: TVector3;
  sr: single;
  collision: TRayCollision;
  hitObjectName: string;
  cursorColor: TColorB;
  normalEnd: TVector3;
  groundHitInfo, triHitInfo, sphereHitInfo, boxHitInfo, meshHitInfo: TRayCollision;
  m: integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - mesh picking');

  camera.position := Vector3Create(20.0, 20.0, 20.0);
  camera.target := Vector3Create(0.0, 8.0, 0.0);
  camera.up := Vector3Create(0.0, 1.6, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  FillChar(ray, SizeOf(ray), 0);

  tower := LoadModel(PChar(GetApplicationDirectory + 'resources/models/obj/turret.obj'));
  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/models/obj/turret_diffuse.png'));
  tower.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture := texture;

  towerPos := Vector3Create(0.0, 0.0, 0.0);
  towerBBox := GetMeshBoundingBox(tower.meshes[0]);

  g0 := Vector3Create(-50.0, 0.0, -50.0);
  g1 := Vector3Create(-50.0, 0.0,  50.0);
  g2 := Vector3Create( 50.0, 0.0,  50.0);
  g3 := Vector3Create( 50.0, 0.0, -50.0);

  ta := Vector3Create(-25.0, 0.5, 0.0);
  tb := Vector3Create(-4.0, 2.5, 1.0);
  tc := Vector3Create(-8.0, 6.5, 0.0);

  bary := Vector3Create(0.0, 0.0, 0.0);

  sp := Vector3Create(-30.0, 5.0, 5.0);
  sr := 4.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsCursorHidden() then
      UpdateCamera(@camera, CAMERA_FIRST_PERSON);

    if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
    begin
      if IsCursorHidden() then
        EnableCursor()
      else
        DisableCursor();
    end;

    FillChar(collision, SizeOf(collision), 0);
    hitObjectName := 'None';
    collision.distance := MaxSingle;
    collision.hit := false;
    cursorColor := WHITE;

    ray := GetScreenToWorldRay(GetMousePosition(), camera);

    groundHitInfo := GetRayCollisionQuad(ray, g0, g1, g2, g3);
    if (groundHitInfo.hit) and (groundHitInfo.distance < collision.distance) then
    begin
      collision := groundHitInfo;
      cursorColor := GREEN;
      hitObjectName := 'Ground';
    end;

    triHitInfo := GetRayCollisionTriangle(ray, ta, tb, tc);
    if (triHitInfo.hit) and (triHitInfo.distance < collision.distance) then
    begin
      collision := triHitInfo;
      cursorColor := PURPLE;
      hitObjectName := 'Triangle';
      bary := Vector3Barycenter(collision.point, ta, tb, tc);
    end;

    sphereHitInfo := GetRayCollisionSphere(ray, sp, sr);
    if (sphereHitInfo.hit) and (sphereHitInfo.distance < collision.distance) then
    begin
      collision := sphereHitInfo;
      cursorColor := ORANGE;
      hitObjectName := 'Sphere';
    end;

    boxHitInfo := GetRayCollisionBox(ray, towerBBox);
    if (boxHitInfo.hit) and (boxHitInfo.distance < collision.distance) then
    begin
      collision := boxHitInfo;
      cursorColor := ORANGE;
      hitObjectName := 'Box';

      FillChar(meshHitInfo, SizeOf(meshHitInfo), 0);
      for m := 0 to tower.meshCount - 1 do
      begin
        meshHitInfo := GetRayCollisionMesh(ray, tower.meshes[m], tower.transform);
        if meshHitInfo.hit then
        begin
          if (not collision.hit) or (collision.distance > meshHitInfo.distance) then
            collision := meshHitInfo;
          Break;
        end;
      end;

      if meshHitInfo.hit then
      begin
        collision := meshHitInfo;
        cursorColor := ORANGE;
        hitObjectName := 'Mesh';
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(tower, towerPos, 1.0, WHITE);

        DrawLine3D(ta, tb, PURPLE);
        DrawLine3D(tb, tc, PURPLE);
        DrawLine3D(tc, ta, PURPLE);

        DrawSphereWires(sp, sr, 8, 8, PURPLE);

        if boxHitInfo.hit then
          DrawBoundingBox(towerBBox, LIME);

        if collision.hit then
        begin
          DrawCube(collision.point, 0.3, 0.3, 0.3, cursorColor);
          DrawCubeWires(collision.point, 0.3, 0.3, 0.3, RED);

          normalEnd.x := collision.point.x + collision.normal.x;
          normalEnd.y := collision.point.y + collision.normal.y;
          normalEnd.z := collision.point.z + collision.normal.z;

          DrawLine3D(collision.point, normalEnd, RED);
        end;

        DrawRay(ray, MAROON);
        DrawGrid(10, 10.0);
      EndMode3D();

      DrawText(PChar('Hit Object: ' + hitObjectName), 10, 50, 10, BLACK);

      if collision.hit then
      begin
        DrawText(PChar(Format('Distance: %3.2f', [collision.distance])), 10, 70, 10, BLACK);
        DrawText(PChar(Format('Hit Pos: %3.2f %3.2f %3.2f',
          [collision.point.x, collision.point.y, collision.point.z])), 10, 85, 10, BLACK);
        DrawText(PChar(Format('Hit Norm: %3.2f %3.2f %3.2f',
          [collision.normal.x, collision.normal.y, collision.normal.z])), 10, 100, 10, BLACK);

        if triHitInfo.hit and (hitObjectName = 'Triangle') then
          DrawText(PChar(Format('Barycenter: %3.2f %3.2f %3.2f', [bary.x, bary.y, bary.z])), 10, 115, 10, BLACK);
      end;

      DrawText('Right click mouse to toggle camera controls', 10, 430, 10, GRAY);
      DrawText('(c) Turret 3D model by Alberto Cano', screenWidth - 200, screenHeight - 20, 10, GRAY);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadModel(tower);
  UnloadTexture(texture);
  CloseWindow();
end.
