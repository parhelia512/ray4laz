program models_tesseract_view;

{$mode objfpc}{$H+}

uses cmem, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  tesseract: array[0..15] of TVector4;
  rotation: single;
  transformed: array[0..15] of TVector3;
  wValues: array[0..15] of single;
  i, j: integer;
  p: TVector4;
  rotXW: TVector2;
  c: single;
  v1, v2: TVector4;
  diff: integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - tesseract view');

  camera.position := Vector3Create(4.0, 4.0, 4.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 0.0, 1.0);
  camera.fovy := 50.0;
  camera.projection := CAMERA_PERSPECTIVE;

  // Tesseract vertices: all combinations of +/-1 in XYZW
  tesseract[0]  := Vector4Create( 1,  1,  1,  1); tesseract[1]  := Vector4Create( 1,  1,  1, -1);
  tesseract[2]  := Vector4Create( 1,  1, -1,  1); tesseract[3]  := Vector4Create( 1,  1, -1, -1);
  tesseract[4]  := Vector4Create( 1, -1,  1,  1); tesseract[5]  := Vector4Create( 1, -1,  1, -1);
  tesseract[6]  := Vector4Create( 1, -1, -1,  1); tesseract[7]  := Vector4Create( 1, -1, -1, -1);
  tesseract[8]  := Vector4Create(-1,  1,  1,  1); tesseract[9]  := Vector4Create(-1,  1,  1, -1);
  tesseract[10] := Vector4Create(-1,  1, -1,  1); tesseract[11] := Vector4Create(-1,  1, -1, -1);
  tesseract[12] := Vector4Create(-1, -1,  1,  1); tesseract[13] := Vector4Create(-1, -1,  1, -1);
  tesseract[14] := Vector4Create(-1, -1, -1,  1); tesseract[15] := Vector4Create(-1, -1, -1, -1);

  rotation := 0.0;
  FillChar(transformed, SizeOf(transformed), 0);
  FillChar(wValues, SizeOf(wValues), 0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    rotation := DEG2RAD * 45.0 * GetTime();

    for i := 0 to 15 do
    begin
      p := tesseract[i];

      // Rotate the XW part of the vector
      rotXW := Vector2Rotate(Vector2Create(p.x, p.w), rotation);
      p.x := rotXW.x;
      p.w := rotXW.y;

      // Projection from XYZW to XYZ from perspective point (0, 0, 0, 3)
      c := 3.0 / (3.0 - p.w);
      p.x := c * p.x;
      p.y := c * p.y;
      p.z := c * p.z;

      transformed[i] := Vector3Create(p.x, p.y, p.z);
      wValues[i] := p.w;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        for i := 0 to 15 do
        begin
          DrawSphere(transformed[i], abs(wValues[i] * 0.1), RED);

          for j := 0 to 15 do
          begin
            v1 := tesseract[i];
            v2 := tesseract[j];
            diff := 0;
            if v1.x = v2.x then Inc(diff);
            if v1.y = v2.y then Inc(diff);
            if v1.z = v2.z then Inc(diff);
            if v1.w = v2.w then Inc(diff);

            if (diff = 3) and (i < j) then
              DrawLine3D(transformed[i], transformed[j], MAROON);
          end;
        end;
      EndMode3D();

    EndDrawing();
  end;

  CloseWindow();
end.
