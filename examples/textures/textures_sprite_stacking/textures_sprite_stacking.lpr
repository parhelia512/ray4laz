program textures_sprite_stacking;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;

var
  booth: TTexture2D;
  stackScale, stackSpacing: single;
  stackCount: cardinal;
  rotationSpeed, rotation: single;
  speedChange: single;
  frameWidth, frameHeight: single;
  scaledWidth, scaledHeight: single;
  i: integer;
  source, dest: TRectangle;
  origin: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - sprite stacking');

  booth := LoadTexture(PChar(GetApplicationDirectory + 'resources/booth.png'));

  stackScale := 3.0;
  stackSpacing := 2.0;
  stackCount := 122;
  rotationSpeed := 30.0;
  rotation := 0.0;
  speedChange := 0.25;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    stackSpacing := stackSpacing + GetMouseWheelMove() * 0.1;
    stackSpacing := Clamp(stackSpacing, 0.0, 5.0);

    if IsKeyDown(KEY_LEFT) or IsKeyDown(KEY_A) then rotationSpeed := rotationSpeed - speedChange;
    if IsKeyDown(KEY_RIGHT) or IsKeyDown(KEY_D) then rotationSpeed := rotationSpeed + speedChange;

    rotation := rotation + rotationSpeed * GetFrameTime();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      frameWidth := booth.Width;
      frameHeight := booth.Height / stackCount;
      scaledWidth := frameWidth * stackScale;
      scaledHeight := frameHeight * stackScale;

      for i := stackCount - 1 downto 0 do
      begin
        source := RectangleCreate(0.0, i * frameHeight, frameWidth, frameHeight);
        dest := RectangleCreate(screenWidth / 2.0, (screenHeight / 2.0) + (i * stackSpacing) - (stackSpacing * stackCount / 2.0), scaledWidth, scaledHeight);
        origin := Vector2Create(scaledWidth / 2.0, scaledHeight / 2.0);
        DrawTexturePro(booth, source, dest, origin, rotation, WHITE);
      end;

      DrawText('A/D to spin', 10, 10, 20, DARKGRAY);
      DrawText('mouse wheel to change separation (aka ''angle'')', 10, 30, 20, DARKGRAY);
      DrawText(PChar(Format('current spacing: %.01f', [stackSpacing])), 10, 50, 20, DARKGRAY);
      DrawText(PChar(Format('current speed: %.02f', [rotationSpeed])), 10, 70, 20, DARKGRAY);
      DrawText('redbooth model (c) kluchek under cc 4.0', 10, 420, 20, DARKGRAY);

    EndDrawing();
  end;

  UnloadTexture(booth);
  CloseWindow();
end.
