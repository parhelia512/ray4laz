program textures_clipboard_image;

{$mode objfpc}{$H+}

uses cmem, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_TEXTURE_COLLECTION = 20;

type
  TTextureCollection = record
    texture: TTexture2D;
    position: TVector2;
  end;

var
  collection: array[0..MAX_TEXTURE_COLLECTION - 1] of TTextureCollection;
  currentCollectionIndex: integer;
  image: TImage;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - clipboard image');

  for i := 0 to MAX_TEXTURE_COLLECTION - 1 do
  begin
    collection[i].texture := Default(TTexture2D);
    collection[i].position := Vector2Create(0, 0);
  end;

  currentCollectionIndex := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_R) then
    begin
      for i := 0 to MAX_TEXTURE_COLLECTION - 1 do
        UnloadTexture(collection[i].texture);
      currentCollectionIndex := 0;
    end;

    if IsKeyDown(KEY_LEFT_CONTROL) and IsKeyPressed(KEY_V) and
       (currentCollectionIndex < MAX_TEXTURE_COLLECTION) then
    begin
      image := GetClipboardImage();
      if IsImageValid(image) then
      begin
        collection[currentCollectionIndex].texture := LoadTextureFromImage(image);
        collection[currentCollectionIndex].position := GetMousePosition();
        Inc(currentCollectionIndex);
        UnloadImage(image);
      end
      else
        TraceLog(LOG_INFO, 'IMAGE: Could not retrieve image from clipboard');
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to currentCollectionIndex - 1 do
      begin
        if IsTextureValid(collection[i].texture) then
        begin
          DrawTexturePro(collection[i].texture,
            RectangleCreate(0, 0, collection[i].texture.width, collection[i].texture.height),
            RectangleCreate(collection[i].position.x, collection[i].position.y,
              collection[i].texture.width, collection[i].texture.height),
            Vector2Create(collection[i].texture.width * 0.5, collection[i].texture.height * 0.5),
            0.0, WHITE);
        end;
      end;

      DrawRectangle(0, 0, screenWidth, 40, BLACK);
      DrawText('Clipboard Image - Ctrl+V to Paste and R to Reset', 120, 10, 20, LIGHTGRAY);

    EndDrawing();
  end;

  for i := 0 to MAX_TEXTURE_COLLECTION - 1 do
    UnloadTexture(collection[i].texture);

  CloseWindow();
end.
