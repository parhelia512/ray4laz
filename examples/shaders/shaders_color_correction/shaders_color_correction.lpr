program shaders_color_correction;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  MAX_TEXTURES = 4;

var
  texture: array[0..MAX_TEXTURES - 1] of TTexture2D;
  shdrColorCorrection: TShader;
  imageIndex: integer;
  resetButtonClicked: integer;
  contrast, saturation, brightness: single;
  contrastLoc, saturationLoc, brightnessLoc: integer;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - color correction');

  texture[0] := LoadTexture(PChar(GetApplicationDirectory + 'resources/parrots.png'));
  texture[1] := LoadTexture(PChar(GetApplicationDirectory + 'resources/cat.png'));
  texture[2] := LoadTexture(PChar(GetApplicationDirectory + 'resources/mandrill.png'));
  texture[3] := LoadTexture(PChar(GetApplicationDirectory + 'resources/fudesumi.png'));

  shdrColorCorrection := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/color_correction.fs', GLSL_VERSION)));

  imageIndex := 0;
  resetButtonClicked := 0;
  contrast := 0.0;
  saturation := 0.0;
  brightness := 0.0;

  contrastLoc := GetShaderLocation(shdrColorCorrection, 'contrast');
  saturationLoc := GetShaderLocation(shdrColorCorrection, 'saturation');
  brightnessLoc := GetShaderLocation(shdrColorCorrection, 'brightness');

  SetShaderValue(shdrColorCorrection, contrastLoc, @contrast, SHADER_UNIFORM_FLOAT);
  SetShaderValue(shdrColorCorrection, saturationLoc, @saturation, SHADER_UNIFORM_FLOAT);
  SetShaderValue(shdrColorCorrection, brightnessLoc, @brightness, SHADER_UNIFORM_FLOAT);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_ONE) then imageIndex := 0
    else if IsKeyPressed(KEY_TWO) then imageIndex := 1
    else if IsKeyPressed(KEY_THREE) then imageIndex := 2
    else if IsKeyPressed(KEY_FOUR) then imageIndex := 3;

    if IsKeyPressed(KEY_R) or (resetButtonClicked = 1) then
    begin
      contrast := 0.0;
      saturation := 0.0;
      brightness := 0.0;
    end;

    SetShaderValue(shdrColorCorrection, contrastLoc, @contrast, SHADER_UNIFORM_FLOAT);
    SetShaderValue(shdrColorCorrection, saturationLoc, @saturation, SHADER_UNIFORM_FLOAT);
    SetShaderValue(shdrColorCorrection, brightnessLoc, @brightness, SHADER_UNIFORM_FLOAT);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginShaderMode(shdrColorCorrection);
        DrawTexture(texture[imageIndex], 580 div 2 - texture[imageIndex].Width div 2, GetScreenHeight() div 2 - texture[imageIndex].Height div 2, WHITE);
      EndShaderMode();

      DrawLine(580, 0, 580, GetScreenHeight(), ColorCreate(218, 218, 218, 255));
      DrawRectangle(580, 0, GetScreenWidth(), GetScreenHeight(), ColorCreate(232, 232, 232, 255));

      DrawText('Color Correction', 585, 40, 20, GRAY);
      DrawText('Picture', 602, 75, 10, GRAY);
      DrawText('Press [1] - [4] to Change Picture', 600, 230, 8, GRAY);
      DrawText('Press [R] to Reset Values', 600, 250, 8, GRAY);

      GuiToggleGroup(RectangleCreate(645, 70, 20, 20), '1;2;3;4', @imageIndex);
      GuiSliderBar(RectangleCreate(645, 100, 120, 20), 'Contrast', PChar(Format('%.0f', [contrast])), @contrast, -100.0, 100.0);
      GuiSliderBar(RectangleCreate(645, 130, 120, 20), 'Saturation', PChar(Format('%.0f', [saturation])), @saturation, -100.0, 100.0);
      GuiSliderBar(RectangleCreate(645, 160, 120, 20), 'Brightness', PChar(Format('%.0f', [brightness])), @brightness, -100.0, 100.0);
      resetButtonClicked := GuiButton(RectangleCreate(645, 190, 40, 20), 'Reset');

      DrawFPS(710, 10);
    EndDrawing();
  end;

  for i := 0 to MAX_TEXTURES - 1 do
    UnloadTexture(texture[i]);
  UnloadShader(shdrColorCorrection);
  CloseWindow();
end.
