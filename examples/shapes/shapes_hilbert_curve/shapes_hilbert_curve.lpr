program shapes_hilbert_curve;

{$mode objfpc}{$H+}

uses
  cmem, raylib, raygui, math, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

// Compute Hilbert path U positions
function ComputeHilbertStep(order, index: integer): TVector2;
const
  hilbertPoints: array[0..3] of TVector2 = (
    (x: 0; y: 0), (x: 0; y: 1), (x: 1; y: 1), (x: 1; y: 0)
  );
var
  hilbertIndex: integer;
  vect: TVector2;
  temp: single;
  len: integer;
  j: integer;
begin
  hilbertIndex := index and 3;
  vect := hilbertPoints[hilbertIndex];
  temp := 0.0;
  len := 0;

  for j := 1 to order - 1 do
  begin
    index := index shr 2;
    hilbertIndex := index and 3;
    len := 1 shl j;

    case hilbertIndex of
      0:
      begin
        temp := vect.x;
        vect.x := vect.y;
        vect.y := temp;
      end;
      2: vect.x := vect.x + len;
      1: vect.y := vect.y + len;
      3:
      begin
        temp := len - 1 - vect.x;
        vect.x := 2 * len - 1 - vect.y;
        vect.y := temp;
      end;
    end;
  end;

  Result := vect;
end;

var
  order: integer;
  size: single;
  strokeCount: integer;
  hilbertPath: array of TVector2;
  prevOrder: integer;
  prevSize: integer;
  counter: integer;
  thick: single;
  animate: boolean;
  N: integer;
  len: single;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - hilbert curve');

  order := 2;
  size := GetScreenHeight();
  strokeCount := 0;
  SetLength(hilbertPath, 0);

  prevOrder := order;
  prevSize := Trunc(size);
  counter := 0;
  thick := 2.0;
  animate := True;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update - check if order or size have changed
    if (prevOrder <> order) or (prevSize <> Trunc(size)) then
    begin
      // Unload old path
      SetLength(hilbertPath, 0);

      // Generate new path
      N := 1 shl order;
      len := size / N;
      strokeCount := N * N;

      SetLength(hilbertPath, strokeCount);
      for i := 0 to strokeCount - 1 do
      begin
        hilbertPath[i] := ComputeHilbertStep(order, i);
        hilbertPath[i].x := hilbertPath[i].x * len + len / 2.0;
        hilbertPath[i].y := hilbertPath[i].y * len + len / 2.0;
      end;

      if animate then
        counter := 0
      else
        counter := strokeCount;

      prevOrder := order;
      prevSize := Trunc(size);
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      if counter < strokeCount then
      begin
        // Draw Hilbert path animation, one stroke every frame
        for i := 1 to counter do
          DrawLineEx(hilbertPath[i], hilbertPath[i - 1], thick,
            ColorFromHSV((i / strokeCount) * 360.0, 1.0, 1.0));
        Inc(counter);
      end
      else
      begin
        // Draw full Hilbert path
        for i := 1 to strokeCount - 1 do
          DrawLineEx(hilbertPath[i], hilbertPath[i - 1], thick,
            ColorFromHSV((i / strokeCount) * 360.0, 1.0, 1.0));
      end;

      // Draw UI using raygui
      GuiCheckBox(RectangleCreate(450, 50, 20, 20), 'ANIMATE GENERATION ON CHANGE', @animate);
      GuiSpinner(RectangleCreate(585, 100, 180, 30), 'HILBERT CURVE ORDER:  ', @order, 2, 8, False);
      GuiSlider(RectangleCreate(524, 150, 240, 24), 'THICKNESS:  ', nil, @thick, 1.0, 10.0);
      GuiSlider(RectangleCreate(524, 190, 240, 24), 'TOTAL SIZE: ', nil, @size, 10.0, GetScreenHeight() * 1.5);

    EndDrawing();
  end;

  // De-Initialization
  SetLength(hilbertPath, 0);
  CloseWindow();
end.
