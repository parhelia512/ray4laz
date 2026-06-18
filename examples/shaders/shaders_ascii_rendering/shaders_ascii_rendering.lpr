program shaders_ascii_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

var
  fudesumi, raysan: TTexture2D;
  shader: TShader;
  resolutionLoc, fontSizeLoc: integer;
  fontSize: single;
  resolution: array[0..1] of single;
  circlePos: TVector2;
  circleSpeed: single;
  target: TRenderTexture2D;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - ascii rendering');

  fudesumi := LoadTexture(PChar(GetApplicationDirectory + 'resources/fudesumi.png'));
  raysan := LoadTexture(PChar(GetApplicationDirectory + 'resources/raysan.png'));

  shader := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/ascii.fs', GLSL_VERSION)));

  resolutionLoc := GetShaderLocation(shader, 'resolution');
  fontSizeLoc := GetShaderLocation(shader, 'fontSize');

  fontSize := 9.0;
  resolution[0] := screenWidth;
  resolution[1] := screenHeight;
  SetShaderValue(shader, resolutionLoc, @resolution, SHADER_UNIFORM_VEC2);

  circlePos := Vector2Create(40.0, screenHeight * 0.5);
  circleSpeed := 1.0;

  target := LoadRenderTexture(screenWidth, screenHeight);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    circlePos.x := circlePos.x + circleSpeed;
    if (circlePos.x > 200.0) or (circlePos.x < 40.0) then circleSpeed := circleSpeed * -1;

    if IsKeyPressed(KEY_LEFT) and (fontSize > 9.0) then fontSize := fontSize - 1;
    if IsKeyPressed(KEY_RIGHT) and (fontSize < 15.0) then fontSize := fontSize + 1;

    SetShaderValue(shader, fontSizeLoc, @fontSize, SHADER_UNIFORM_FLOAT);

    BeginTextureMode(target);
      ClearBackground(WHITE);
      DrawTexture(fudesumi, 500, -30, WHITE);
      DrawTextureV(raysan, circlePos, WHITE);
    EndTextureMode();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginShaderMode(shader);
        DrawTextureRec(target.texture,
          RectangleCreate(0, 0, target.texture.width, -target.texture.height),
          Vector2Create(0, 0), WHITE);
      EndShaderMode();

      DrawRectangle(0, 0, screenWidth, 40, BLACK);
      DrawText(PChar(Format('Ascii effect - FontSize:%2.0f - [Left] -1 [Right] +1', [fontSize])), 120, 10, 20, LIGHTGRAY);
      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadRenderTexture(target);
  UnloadShader(shader);
  UnloadTexture(fudesumi);
  UnloadTexture(raysan);
  CloseWindow();
end.
