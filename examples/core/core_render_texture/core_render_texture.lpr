program core_render_texture;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;

var
  renderTextureWidth, renderTextureHeight: integer;
  target: TRenderTexture2D;
  ballPosition, ballSpeed: TVector2;
  ballRadius: integer;
  rotation: single;

begin
  // Initialization
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - render texture');

  renderTextureWidth := 300;
  renderTextureHeight := 300;
  target := LoadRenderTexture(renderTextureWidth, renderTextureHeight);

  ballPosition := Vector2Create(renderTextureWidth / 2.0, renderTextureHeight / 2.0);
  ballSpeed := Vector2Create(5.0, 4.0);
  ballRadius := 20;

  rotation := 0.0;

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    ballPosition.x := ballPosition.x + ballSpeed.x;
    ballPosition.y := ballPosition.y + ballSpeed.y;

    // Check walls collision for bouncing
    if (ballPosition.x >= (renderTextureWidth - ballRadius)) or (ballPosition.x <= ballRadius) then
      ballSpeed.x := -ballSpeed.x;
    if (ballPosition.y >= (renderTextureHeight - ballRadius)) or (ballPosition.y <= ballRadius) then
      ballSpeed.y := -ballSpeed.y;

    // Render texture rotation
    rotation := rotation + 0.5;

    // Draw to render texture
    BeginTextureMode(target);
      ClearBackground(SKYBLUE);
      DrawRectangle(0, 0, 20, 20, RED);
      DrawCircleV(ballPosition, ballRadius, MAROON);
    EndTextureMode();

    // Draw to screen
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw render texture with rotation
      DrawTexturePro(target.texture,
        RectangleCreate(0, 0, target.texture.width, -target.texture.height),
        RectangleCreate(screenWidth / 2.0, screenHeight / 2.0, target.texture.width, target.texture.height),
        Vector2Create(target.texture.width / 2.0, target.texture.height / 2.0),
        rotation,
        WHITE
      );

      DrawText('DRAWING BOUNCING BALL INSIDE RENDER TEXTURE!', 10, screenHeight - 40, 20, BLACK);
      DrawFPS(10, 10);

    EndDrawing();
  end;

  // De-Initialization
  UnloadRenderTexture(target);
  CloseWindow();
end.
