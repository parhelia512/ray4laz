program shapes_bullet_hell;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_BULLETS = 500000;

type
  TBullet = record
    position: TVector2;
    acceleration: TVector2;
    disabled: boolean;
    color: TColorB;
  end;

var
  bullets: array of TBullet;
  bulletCount, bulletDisabledCount: integer;
  bulletRadius: integer;
  bulletSpeed: single;
  bulletRows: integer;
  bulletColor: array[0..1] of TColorB;
  baseDirection: single;
  angleIncrement: integer;
  spawnCooldown, spawnCooldownTimer: single;
  magicCircleRotation: single;
  bulletTexture: TRenderTexture2D;
  drawInPerformanceMode: boolean;
  i, row: integer;
  degreesPerRow, bulletDirection: single;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - bullet hell');

  SetLength(bullets, MAX_BULLETS);
  for i := 0 to MAX_BULLETS - 1 do
  begin
    bullets[i].position := Vector2Create(0, 0);
    bullets[i].acceleration := Vector2Create(0, 0);
    bullets[i].disabled := True;
    bullets[i].color := WHITE;
  end;

  bulletCount := 0;
  bulletDisabledCount := 0;
  bulletRadius := 10;
  bulletSpeed := 3.0;
  bulletRows := 6;
  bulletColor[0] := RED;
  bulletColor[1] := BLUE;

  baseDirection := 0;
  angleIncrement := 5;
  spawnCooldown := 2;
  spawnCooldownTimer := spawnCooldown;
  magicCircleRotation := 0;

  bulletTexture := LoadRenderTexture(24, 24);
  BeginTextureMode(bulletTexture);
    DrawCircle(12, 12, bulletRadius, WHITE);
    DrawCircleLines(12, 12, bulletRadius, BLACK);
  EndTextureMode();

  drawInPerformanceMode := True;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if bulletCount >= MAX_BULLETS then
    begin
      bulletCount := 0;
      bulletDisabledCount := 0;
    end;

    spawnCooldownTimer := spawnCooldownTimer - 1;
    if spawnCooldownTimer < 0 then
    begin
      spawnCooldownTimer := spawnCooldown;
      degreesPerRow := 360.0 / bulletRows;

      for row := 0 to bulletRows - 1 do
      begin
        if bulletCount < MAX_BULLETS then
        begin
          bullets[bulletCount].position := Vector2Create(screenWidth / 2, screenHeight / 2);
          bullets[bulletCount].disabled := False;
          bullets[bulletCount].color := bulletColor[row mod 2];

          bulletDirection := baseDirection + degreesPerRow * row;
          bullets[bulletCount].acceleration := Vector2Create(
            bulletSpeed * Cos(bulletDirection * DEG2RAD),
            bulletSpeed * Sin(bulletDirection * DEG2RAD)
          );

          Inc(bulletCount);
        end;
      end;

      baseDirection := baseDirection + angleIncrement;
    end;

    for i := 0 to bulletCount - 1 do
    begin
      if not bullets[i].disabled then
      begin
        bullets[i].position.x := bullets[i].position.x + bullets[i].acceleration.x;
        bullets[i].position.y := bullets[i].position.y + bullets[i].acceleration.y;

        if (bullets[i].position.x < -bulletRadius * 2) or
           (bullets[i].position.x > screenWidth + bulletRadius * 2) or
           (bullets[i].position.y < -bulletRadius * 2) or
           (bullets[i].position.y > screenHeight + bulletRadius * 2) then
        begin
          bullets[i].disabled := True;
          Inc(bulletDisabledCount);
        end;
      end;
    end;

    if (IsKeyPressed(KEY_RIGHT) or IsKeyPressed(KEY_D)) and (bulletRows < 359) then Inc(bulletRows);
    if (IsKeyPressed(KEY_LEFT) or IsKeyPressed(KEY_A)) and (bulletRows > 1) then Dec(bulletRows);
    if IsKeyPressed(KEY_UP) or IsKeyPressed(KEY_W) then bulletSpeed := bulletSpeed + 0.25;
    if (IsKeyPressed(KEY_DOWN) or IsKeyPressed(KEY_S)) and (bulletSpeed > 0.50) then bulletSpeed := bulletSpeed - 0.25;
    if IsKeyPressed(KEY_Z) and (spawnCooldown > 1) then spawnCooldown := spawnCooldown - 1;
    if IsKeyPressed(KEY_X) then spawnCooldown := spawnCooldown + 1;
    if IsKeyPressed(KEY_ENTER) then drawInPerformanceMode := not drawInPerformanceMode;

    if IsKeyDown(KEY_SPACE) then
    begin
      angleIncrement := angleIncrement + 1;
      angleIncrement := angleIncrement mod 360;
    end;

    if IsKeyPressed(KEY_C) then
    begin
      bulletCount := 0;
      bulletDisabledCount := 0;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      magicCircleRotation := magicCircleRotation + 1;
      DrawRectanglePro(RectangleCreate(screenWidth / 2, screenHeight / 2, 120, 120),
        Vector2Create(60.0, 60.0), magicCircleRotation, PURPLE);
      DrawRectanglePro(RectangleCreate(screenWidth / 2, screenHeight / 2, 120, 120),
        Vector2Create(60.0, 60.0), magicCircleRotation + 45, PURPLE);
      DrawCircleLines(screenWidth div 2, screenHeight div 2, 70, BLACK);
      DrawCircleLines(screenWidth div 2, screenHeight div 2, 50, BLACK);
      DrawCircleLines(screenWidth div 2, screenHeight div 2, 30, BLACK);

      if drawInPerformanceMode then
      begin
        for i := 0 to bulletCount - 1 do
        begin
          if not bullets[i].disabled then
          begin
            DrawTexture(bulletTexture.texture,
              Trunc(bullets[i].position.x - bulletTexture.texture.width * 0.5),
              Trunc(bullets[i].position.y - bulletTexture.texture.height * 0.5),
              bullets[i].color);
          end;
        end;
      end
      else
      begin
        for i := 0 to bulletCount - 1 do
        begin
          if not bullets[i].disabled then
          begin
            DrawCircleV(bullets[i].position, bulletRadius, bullets[i].color);
            DrawCircleLinesV(bullets[i].position, bulletRadius, BLACK);
          end;
        end;
      end;

      DrawRectangle(10, 10, 280, 150, ColorCreate(0, 0, 0, 200));
      DrawText('Controls:', 20, 20, 10, LIGHTGRAY);
      DrawText('- Right/Left or A/D: Change rows number', 40, 40, 10, LIGHTGRAY);
      DrawText('- Up/Down or W/S: Change bullet speed', 40, 60, 10, LIGHTGRAY);
      DrawText('- Z or X: Change spawn cooldown', 40, 80, 10, LIGHTGRAY);
      DrawText('- Space (Hold): Change the angle increment', 40, 100, 10, LIGHTGRAY);
      DrawText('- Enter: Switch draw method (Performance)', 40, 120, 10, LIGHTGRAY);
      DrawText('- C: Clear bullets', 40, 140, 10, LIGHTGRAY);

      DrawRectangle(610, 10, 170, 30, ColorCreate(0, 0, 0, 200));
      if drawInPerformanceMode then DrawText('Draw method: DrawTexture(*)', 620, 20, 10, GREEN)
      else DrawText('Draw method: DrawCircle(*)', 620, 20, 10, RED);

      DrawRectangle(135, 410, 530, 30, ColorCreate(0, 0, 0, 200));
      DrawText(PChar(Format('[ FPS: %d, Bullets: %d, Rows: %d, Bullet speed: %.2f, Angle increment per frame: %d, Cooldown: %.0f ]',
        [GetFPS(), bulletCount - bulletDisabledCount, bulletRows, bulletSpeed, angleIncrement, spawnCooldown])),
        155, 420, 10, GREEN);

    EndDrawing();
  end;

  UnloadRenderTexture(bulletTexture);
  SetLength(bullets, 0);
  CloseWindow();
end.
