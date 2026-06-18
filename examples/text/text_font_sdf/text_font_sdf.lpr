program text_font_sdf;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;

var
  Msg: PChar;
  FileSize: Integer;
  FileData: PByte;
  FontDefault: TFont;
  Atlas: TImage;
  FontSDF: TFont;
  Shader: TShader;
  FontPosition, TextSize: TVector2;
  FontSize: Single;
  CurrentFont: Integer;

begin
  // Initialization
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - font sdf');

  // NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)
  Msg := 'Signed Distance Fields';

  // Loading file to memory
  FileSize := 0;
  FileData := LoadFileData(PChar(GetApplicationDirectory + 'resources/anonymous_pro_bold.ttf'), @FileSize);

  // Default font generation from TTF font
  FontDefault := Default(TFont);
  FontDefault.baseSize := 16;
  FontDefault.glyphCount := 95;

  // Loading font data from memory data
  // Parameters > font size: 16, no glyphs array provided (0), glyphs count: 95 (autogenerate chars array)
  FontDefault.glyphs := LoadFontData(FileData, FileSize, 16, nil, 95, FONT_DEFAULT, @FontDefault.glyphCount);
  // Parameters > glyphs count: 95, font size: 16, glyphs padding in image: 4 px, pack method: 0 (default)
  Atlas := GenImageFontAtlas(FontDefault.glyphs, @FontDefault.recs, 95, 16, 4, 0);
  FontDefault.texture := LoadTextureFromImage(Atlas);
  UnloadImage(Atlas);

  // SDF font generation from TTF font
  FontSDF := Default(TFont);
  FontSDF.baseSize := 16;
  FontSDF.glyphCount := 95;
  // Parameters > font size: 16, no glyphs array provided (0), glyphs count: 0 (defaults to 95)
  FontSDF.glyphs := LoadFontData(FileData, FileSize, 16, nil, 0, FONT_SDF, @FontSDF.glyphCount);
  // Parameters > glyphs count: 95, font size: 16, glyphs padding in image: 0 px, pack method: 1 (Skyline algorithm)
  Atlas := GenImageFontAtlas(FontSDF.glyphs, @FontSDF.recs, 95, 16, 0, 1);
  FontSDF.texture := LoadTextureFromImage(Atlas);
  UnloadImage(Atlas);

  UnloadFileData(FileData);      // Free memory from loaded file

  // Load SDF required shader (we use default vertex shader)
  Shader := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/sdf.fs', GLSL_VERSION)));
  SetTextureFilter(FontSDF.texture, TEXTURE_FILTER_BILINEAR);    // Required for SDF font

  FontPosition := Vector2Create(40, screenHeight / 2.0 - 50);
  TextSize := Vector2Create(0, 0);
  FontSize := 16.0;
  CurrentFont := 0;            // 0 - fontDefault, 1 - fontSDF

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    FontSize := FontSize + GetMouseWheelMove() * 8.0;

    if FontSize < 6 then
      FontSize := 6;

    if IsKeyDown(KEY_SPACE) then
      CurrentFont := 1
    else
      CurrentFont := 0;

    if CurrentFont = 0 then
      TextSize := MeasureTextEx(FontDefault, Msg, FontSize, 0)
    else
      TextSize := MeasureTextEx(FontSDF, Msg, FontSize, 0);

    FontPosition.x := GetScreenWidth() / 2 - TextSize.x / 2;
    FontPosition.y := GetScreenHeight() / 2 - TextSize.y / 2 + 80;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      if CurrentFont = 1 then
      begin
        // NOTE: SDF fonts require a custom SDF shader to compute fragment color
        BeginShaderMode(Shader);    // Activate SDF font shader
          DrawTextEx(FontSDF, Msg, FontPosition, FontSize, 0, BLACK);
        EndShaderMode();            // Activate our default shader for next drawings

        DrawTexture(FontSDF.texture, 10, 10, BLACK);
      end
      else
      begin
        DrawTextEx(FontDefault, Msg, FontPosition, FontSize, 0, BLACK);
        DrawTexture(FontDefault.texture, 10, 10, BLACK);
      end;

      if CurrentFont = 1 then
        DrawText('SDF!', 320, 20, 80, RED)
      else
        DrawText('default font', 315, 40, 30, GRAY);

      DrawText('FONT SIZE: 16.0', GetScreenWidth() - 240, 20, 20, DARKGRAY);
      DrawText(PChar(Format('RENDER SIZE: %.2f', [FontSize])), GetScreenWidth() - 240, 50, 20, DARKGRAY);
      DrawText('Use MOUSE WHEEL to SCALE TEXT!', GetScreenWidth() - 240, 90, 10, DARKGRAY);

      DrawText('HOLD SPACE to USE SDF FONT VERSION!', 340, GetScreenHeight() - 30, 20, MAROON);

    EndDrawing();
  end;

  // De-Initialization
  UnloadFont(FontDefault);    // Default font unloading
  UnloadFont(FontSDF);        // SDF font unloading

  UnloadShader(Shader);       // Unload SDF shader

  CloseWindow();
end.
