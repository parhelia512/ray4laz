program shapes_ellipse_collision;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;

function CheckCollisionPointEllipse(point, center: TVector2; rx, ry: single): boolean;
var
  dx, dy: single;
begin
  dx := (point.x - center.x) / rx;
  dy := (point.y - center.y) / ry;
  Result := (dx * dx + dy * dy) <= 1.0;
end;

function CheckCollisionEllipses(c1: TVector2; rx1, ry1: single; c2: TVector2; rx2, ry2: single): boolean;
var
  dx, dy, dist, theta, cosT, sinT, r1, r2: single;
begin
  dx := c2.x - c1.x;
  dy := c2.y - c1.y;
  dist := Sqrt(dx * dx + dy * dy);

  if dist = 0.0 then
  begin
    Result := True;
    Exit;
  end;

  theta := ArcTan2(dy, dx);
  cosT := Cos(theta);
  sinT := Sin(theta);

  r1 := (rx1 * ry1) / Sqrt(Sqr(ry1 * cosT) + Sqr(rx1 * sinT));
  r2 := (rx2 * ry2) / Sqrt(Sqr(ry2 * cosT) + Sqr(rx2 * sinT));

  Result := dist <= (r1 + r2);
end;

var
  ellipseACenter, ellipseBCenter: TVector2;
  ellipseARx, ellipseARy, ellipseBRx, ellipseBRy: single;
  controlled: integer;
  ellipsesCollide, mouseInA, mouseInB: boolean;
  colorA, colorB: TColorB;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - collision ellipses');
  SetTargetFPS(60);

  ellipseACenter := Vector2Create(screenWidth / 4, screenHeight / 2);
  ellipseARx := 120.0;
  ellipseARy := 70.0;

  ellipseBCenter := Vector2Create(screenWidth * 3 / 4, screenHeight / 2);
  ellipseBRx := 90.0;
  ellipseBRy := 140.0;

  controlled := 0;

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_A) then controlled := 0;
    if IsKeyPressed(KEY_B) then controlled := 1;

    if controlled = 0 then ellipseACenter := GetMousePosition()
    else ellipseBCenter := GetMousePosition();

    ellipsesCollide := CheckCollisionEllipses(
      ellipseACenter, ellipseARx, ellipseARy,
      ellipseBCenter, ellipseBRx, ellipseBRy
    );

    mouseInA := CheckCollisionPointEllipse(GetMousePosition(), ellipseACenter, ellipseARx, ellipseARy);
    mouseInB := CheckCollisionPointEllipse(GetMousePosition(), ellipseBCenter, ellipseBRx, ellipseBRy);

    // Выбираем цвета в зависимости от столкновения
    if ellipsesCollide then
    begin
      colorA := RED;
      colorB := RED;
    end
    else
    begin
      colorA := BLUE;
      colorB := GREEN;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawEllipse(Trunc(ellipseACenter.x), Trunc(ellipseACenter.y), Trunc(ellipseARx), Trunc(ellipseARy), colorA);
      DrawEllipse(Trunc(ellipseBCenter.x), Trunc(ellipseBCenter.y), Trunc(ellipseBRx), Trunc(ellipseBRy), colorB);

      DrawEllipseLines(Trunc(ellipseACenter.x), Trunc(ellipseACenter.y), ellipseARx, ellipseARy, WHITE);
      DrawEllipseLines(Trunc(ellipseBCenter.x), Trunc(ellipseBCenter.y), ellipseBRx, ellipseBRy, WHITE);

      DrawCircleV(ellipseACenter, 4, WHITE);
      DrawCircleV(ellipseBCenter, 4, WHITE);

      if ellipsesCollide then
        DrawText('ELLIPSES COLLIDE', screenWidth div 2 - 120, 40, 28, RED)
      else
        DrawText('NO COLLISION', screenWidth div 2 - 80, 40, 28, DARKGRAY);

      if controlled = 0 then
        DrawText('Controlling: A', 20, screenHeight - 40, 20, YELLOW)
      else
        DrawText('Controlling: B', 20, screenHeight - 40, 20, YELLOW);

      if mouseInA and (controlled <> 0) then
        DrawText('Mouse inside ellipse A', 20, screenHeight - 70, 20, BLUE);
      if mouseInB and (controlled <> 1) then
        DrawText('Mouse inside ellipse B', 20, screenHeight - 70, 20, GREEN);

      DrawText('Press [A] or [B] to switch control', 20, 20, 20, GRAY);

    EndDrawing();
  end;

  CloseWindow();
end.
