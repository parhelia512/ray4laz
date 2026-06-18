program shapes_double_pendulum;

{$mode objfpc}{$H+}

uses cmem, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  SIMULATION_STEPS = 30;
  G = 9.81;

function CalcEndpoint(l, theta: single): TVector2;
begin
  Result := Vector2Create(10 * l * Sin(theta), 10 * l * Cos(theta));
end;

function CalcDoubleEndpoint(l1, t1, l2, t2: single): TVector2;
var
  e1, e2: TVector2;
begin
  e1 := CalcEndpoint(l1, t1);
  e2 := CalcEndpoint(l2, t2);
  Result := Vector2Create(e1.x + e2.x, e1.y + e2.y);
end;

var
  pL1, pM1, pT1, pW1: single;
  pL2, pM2, pT2, pW2: single;
  pLengthScaler, totalM: single;
  prevPos, curPos: TVector2;
  pL1s, pL2s: single;
  lineThick, trailThick, fateAlpha: single;
  target: TRenderTexture2D;
  dt, step, step2: single;
  i: integer;
  delta, sinD, cosD, cos2D, ww1, ww2, a1, a2: single;
  e1: TVector2;

begin
  SetConfigFlags(FLAG_WINDOW_HIGHDPI);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - double pendulum');

  pL1 := 15.0; pM1 := 0.2; pT1 := DEG2RAD * 170; pW1 := 0;
  pL2 := 15.0; pM2 := 0.1; pT2 := 0; pW2 := 0;
  pLengthScaler := 0.1;
  totalM := pM1 + pM2;

  prevPos := CalcDoubleEndpoint(pL1, pT1, pL2, pT2);
  prevPos.x := prevPos.x + screenWidth / 2;
  prevPos.y := prevPos.y + (screenHeight / 2 - 100);

  pL1s := pL1 * pLengthScaler;
  pL2s := pL2 * pLengthScaler;

  lineThick := 20;
  trailThick := 2;
  fateAlpha := 0.01;

  target := LoadRenderTexture(screenWidth, screenHeight);
  SetTextureFilter(target.texture, TEXTURE_FILTER_BILINEAR);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    dt := GetFrameTime();
    step := dt / SIMULATION_STEPS;
    step2 := step * step;

    for i := 0 to SIMULATION_STEPS - 1 do
    begin
      delta := pT1 - pT2;
      sinD := Sin(delta);
      cosD := Cos(delta);
      cos2D := Cos(2 * delta);
      ww1 := pW1 * pW1;
      ww2 := pW2 * pW2;

      a1 := (-G * (2 * pM1 + pM2) * Sin(pT1)
             - pM2 * G * Sin(pT1 - 2 * pT2)
             - 2 * sinD * pM2 * (ww2 * pL2s + ww1 * pL1s * cosD))
            / (pL1s * (2 * pM1 + pM2 - pM2 * cos2D));

      a2 := (2 * sinD * (ww1 * pL1s * totalM
             + G * totalM * Cos(pT1)
             + ww2 * pL2s * pM2 * cosD))
            / (pL2s * (2 * pM1 + pM2 - pM2 * cos2D));

      pT1 := pT1 + pW1 * step + 0.5 * a1 * step2;
      pT2 := pT2 + pW2 * step + 0.5 * a2 * step2;
      pW1 := pW1 + a1 * step;
      pW2 := pW2 + a2 * step;
    end;

    curPos := CalcDoubleEndpoint(pL1, pT1, pL2, pT2);
    curPos.x := curPos.x + screenWidth / 2;
    curPos.y := curPos.y + (screenHeight / 2 - 100);

    BeginTextureMode(target);
      DrawRectangle(0, 0, screenWidth, screenHeight, Fade(BLACK, fateAlpha));
      DrawCircleV(prevPos, trailThick, RED);
      DrawLineEx(prevPos, curPos, trailThick * 2, RED);
    EndTextureMode();

    prevPos := curPos;

    BeginDrawing();
      ClearBackground(BLACK);

      DrawTextureRec(target.texture,
        RectangleCreate(0, 0, target.texture.width, -target.texture.height),
        Vector2Create(0, 0), WHITE);

      e1 := CalcEndpoint(pL1, pT1);
      DrawRectanglePro(RectangleCreate(screenWidth / 2.0, screenHeight / 2.0 - 100, 10 * pL1, lineThick),
        Vector2Create(0, lineThick * 0.5), 90 - RAD2DEG * pT1, RAYWHITE);
      DrawRectanglePro(RectangleCreate(screenWidth / 2.0 + e1.x, screenHeight / 2.0 - 100 + e1.y, 10 * pL2, lineThick),
        Vector2Create(0, lineThick * 0.5), 90 - RAD2DEG * pT2, RAYWHITE);
    EndDrawing();
  end;

  UnloadRenderTexture(target);
  CloseWindow();
end.
