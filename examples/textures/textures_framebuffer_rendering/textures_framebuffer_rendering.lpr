program textures_framebuffer_rendering;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  splitWidth = 800 div 2;

procedure DrawCameraPrism(camera: TCamera3D; aspect: single; color: TColorB);
var
  length: single;
  planeNDC: array[0..3] of TVector3;
  view, proj, viewProj, inverseViewProj: TMatrix;
  corners: array[0..3] of TVector3;
  x, y, z, vx, vy, vz, vw: single;
  i: integer;
begin
  length := Vector3Distance(camera.position, camera.target);

  planeNDC[0] := Vector3Create(-1.0, -1.0, 1.0);
  planeNDC[1] := Vector3Create(1.0, -1.0, 1.0);
  planeNDC[2] := Vector3Create(1.0, 1.0, 1.0);
  planeNDC[3] := Vector3Create(-1.0, 1.0, 1.0);

  view := GetCameraMatrix(camera);
  proj := MatrixPerspective(camera.fovy * DEG2RAD, aspect, 0.05, length);
  viewProj := MatrixMultiply(view, proj);
  inverseViewProj := MatrixInvert(viewProj);

  for i := 0 to 3 do
  begin
    x := planeNDC[i].x;
    y := planeNDC[i].y;
    z := planeNDC[i].z;

    vx := inverseViewProj.m0*x + inverseViewProj.m4*y + inverseViewProj.m8*z + inverseViewProj.m12;
    vy := inverseViewProj.m1*x + inverseViewProj.m5*y + inverseViewProj.m9*z + inverseViewProj.m13;
    vz := inverseViewProj.m2*x + inverseViewProj.m6*y + inverseViewProj.m10*z + inverseViewProj.m14;
    vw := inverseViewProj.m3*x + inverseViewProj.m7*y + inverseViewProj.m11*z + inverseViewProj.m15;

    corners[i] := Vector3Create(vx/vw, vy/vw, vz/vw);
  end;

  DrawLine3D(corners[0], corners[1], color);
  DrawLine3D(corners[1], corners[2], color);
  DrawLine3D(corners[2], corners[3], color);
  DrawLine3D(corners[3], corners[0], color);

  for i := 0 to 3 do
    DrawLine3D(camera.position, corners[i], color);
end;

var
  subjectCamera, observerCamera: TCamera3D;
  observerTarget, subjectTarget: TRenderTexture2D;
  observerSource, observerDest: TRectangle;
  subjectSource, subjectDest: TRectangle;
  textureAspectRatio: single;
  captureSize: single;
  cropSource, cropDest: TRectangle;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - framebuffer rendering');

  subjectCamera := Default(TCamera3D);
  subjectCamera.position := Vector3Create(5.0, 5.0, 5.0);
  subjectCamera.target := Vector3Create(0.0, 0.0, 0.0);
  subjectCamera.up := Vector3Create(0.0, 1.0, 0.0);
  subjectCamera.fovy := 45.0;
  subjectCamera.projection := CAMERA_PERSPECTIVE;

  observerCamera := Default(TCamera3D);
  observerCamera.position := Vector3Create(10.0, 10.0, 10.0);
  observerCamera.target := Vector3Create(0.0, 0.0, 0.0);
  observerCamera.up := Vector3Create(0.0, 1.0, 0.0);
  observerCamera.fovy := 45.0;
  observerCamera.projection := CAMERA_PERSPECTIVE;

  observerTarget := LoadRenderTexture(splitWidth, screenHeight);
  observerSource := RectangleCreate(0.0, 0.0, observerTarget.texture.width, -observerTarget.texture.height);
  observerDest := RectangleCreate(0.0, 0.0, splitWidth, screenHeight);

  subjectTarget := LoadRenderTexture(splitWidth, screenHeight);
  subjectSource := RectangleCreate(0.0, 0.0, subjectTarget.texture.width, -subjectTarget.texture.height);
  subjectDest := RectangleCreate(splitWidth, 0.0, splitWidth, screenHeight);
  textureAspectRatio := subjectTarget.texture.width / subjectTarget.texture.height;

  captureSize := 128.0;
  cropSource := RectangleCreate((subjectTarget.texture.width - captureSize) / 2.0, (subjectTarget.texture.height - captureSize) / 2.0, captureSize, -captureSize);
  cropDest := RectangleCreate(splitWidth + 20.0, 20.0, captureSize, captureSize);

  SetTargetFPS(60);
  DisableCursor();

  while not WindowShouldClose() do
  begin
    UpdateCamera(@observerCamera, CAMERA_FREE);
    UpdateCamera(@subjectCamera, CAMERA_ORBITAL);

    if IsKeyPressed(KEY_R) then observerCamera.target := Vector3Create(0.0, 0.0, 0.0);

    // Build LHS observer view texture
    BeginTextureMode(observerTarget);
      ClearBackground(RAYWHITE);
      BeginMode3D(observerCamera);
        DrawGrid(10, 1.0);
        DrawCube(Vector3Create(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, GOLD);
        DrawCubeWires(Vector3Create(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, PINK);
        DrawCameraPrism(subjectCamera, textureAspectRatio, GREEN);
      EndMode3D();
      DrawText('Observer View', 10, observerTarget.texture.height - 30, 20, BLACK);
      DrawText('WASD + Mouse to Move', 10, 10, 20, DARKGRAY);
      DrawText('Scroll to Zoom', 10, 30, 20, DARKGRAY);
      DrawText('R to Reset Observer Target', 10, 50, 20, DARKGRAY);
    EndTextureMode();

    // Build RHS subject view texture
    BeginTextureMode(subjectTarget);
      ClearBackground(RAYWHITE);
      BeginMode3D(subjectCamera);
        DrawCube(Vector3Create(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, GOLD);
        DrawCubeWires(Vector3Create(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, PINK);
        DrawGrid(10, 1.0);
      EndMode3D();
      DrawRectangleLines(Trunc((subjectTarget.texture.width - captureSize) / 2.0), Trunc((subjectTarget.texture.height - captureSize) / 2.0), Trunc(captureSize), Trunc(captureSize), GREEN);
      DrawText('Subject View', 10, subjectTarget.texture.height - 30, 20, BLACK);
    EndTextureMode();

    BeginDrawing();
      ClearBackground(BLACK);

      DrawTexturePro(observerTarget.texture, observerSource, observerDest, Vector2Create(0.0, 0.0), 0.0, WHITE);
      DrawTexturePro(subjectTarget.texture, subjectSource, subjectDest, Vector2Create(0.0, 0.0), 0.0, WHITE);
      DrawTexturePro(subjectTarget.texture, cropSource, cropDest, Vector2Create(0.0, 0.0), 0.0, WHITE);
      DrawRectangleLinesEx(cropDest, 2, BLACK);
      DrawLine(splitWidth, 0, splitWidth, screenHeight, BLACK);
    EndDrawing();
  end;

  UnloadRenderTexture(observerTarget);
  UnloadRenderTexture(subjectTarget);
  CloseWindow();
end.
