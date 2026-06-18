program textures_blend_modes;

{$mode objfpc}{$H+}

uses
cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  blendCountMax = 4;

var
  BgImage: TImage;
  BgTexture: TTexture;
  FgImage: TImage;
  FgTexture: TTexture;
  BlendMode: TBlendMode;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - blend modes');

  BgImage := LoadImage(PChar(GetApplicationDirectory + 'resources/cyberpunk_street_background.png'));
  BgTexture := LoadTextureFromImage(BgImage);

  FgImage := LoadImage(PChar(GetApplicationDirectory + 'resources/cyberpunk_street_foreground.png'));
  FgTexture := LoadTextureFromImage(FgImage);

  UnloadImage(BgImage);
  UnloadImage(FgImage);

  BlendMode := 0;
  SetTargetFPS(60);

  while not WindowShouldClose() do
    begin
      if IsKeyPressed(KEY_SPACE) then
      begin
        if BlendMode >= (BlendCountMax - 1) then
          BlendMode := 0
        else
          Inc(BlendMode);
      end;

      BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawTexture(BgTexture, ScreenWidth div 2 - BgTexture.Width div 2, ScreenHeight div 2 - BgTexture.Height div 2, WHITE);

      BeginBlendMode(BlendMode);
        DrawTexture(FgTexture, ScreenWidth div 2 - FgTexture.Width div 2, ScreenHeight div 2 - FgTexture.Height div 2, WHITE);
      EndBlendMode();

      DrawText('Press SPACE to change blend modes.', 310, 350, 10, GRAY);

      case BlendMode of
        BLEND_ALPHA: DrawText('Current: BLEND_ALPHA', (ScreenWidth div 2) - 60, 370, 10, GRAY);
        BLEND_ADDITIVE: DrawText('Current: BLEND_ADDITIVE', (ScreenWidth div 2) - 60, 370, 10, GRAY);
        BLEND_MULTIPLIED: DrawText('Current: BLEND_MULTIPLIED', (ScreenWidth div 2) - 60, 370, 10, GRAY);
        BLEND_ADD_COLORS: DrawText('Current: BLEND_ADD_COLORS', (ScreenWidth div 2) - 60, 370, 10, GRAY);
      end;

      DrawText('(c) Cyberpunk Street Environment by Luis Zuno (@ansimuz)', ScreenWidth - 330, ScreenHeight - 20, 10, GRAY);

      EndDrawing();
    end;

  UnloadTexture(FgTexture);
  UnloadTexture(BgTexture);
  CloseWindow();
end.
