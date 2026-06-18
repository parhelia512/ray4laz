program shaders_texture_rendering;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

var
  imBlank: TImage;
  texture: TTexture2D;
  shader: TShader;
  time: single;
  timeLoc: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - texture rendering');

  imBlank := GenImageColor(1024, 1024, BLANK);
  texture := LoadTextureFromImage(imBlank);
  UnloadImage(imBlank);

  shader := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/cubes_panning.fs', GLSL_VERSION)));

  time := 0.0;
  timeLoc := GetShaderLocation(shader, 'uTime');
  SetShaderValue(shader, timeLoc, @time, SHADER_UNIFORM_FLOAT);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    time := GetTime();
    SetShaderValue(shader, timeLoc, @time, SHADER_UNIFORM_FLOAT);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginShaderMode(shader);
        DrawTexture(texture, 0, 0, WHITE);
      EndShaderMode();

      DrawText('BACKGROUND is PAINTED and ANIMATED on SHADER!', 10, 10, 20, MAROON);
    EndDrawing();
  end;

  UnloadShader(shader);
  UnloadTexture(texture);
  CloseWindow();
end.
