program textures_tiled_drawing;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  OPT_WIDTH = 220;
  MARGIN_SIZE = 8;
  COLOR_SIZE = 16;

procedure DrawTextureTiled(texture: TTexture2D; source, dest: TRectangle; origin: TVector2; rotation, scale: single; tint: TColorB);
var
  tileWidth, tileHeight: integer;
  dx, dy: integer;
begin
  if (texture.id <= 0) or (scale <= 0.0) then Exit;
  if (source.width = 0) or (source.height = 0) then Exit;

  tileWidth := Trunc(source.width * scale);
  tileHeight := Trunc(source.height * scale);

  if (dest.width < tileWidth) and (dest.height < tileHeight) then
  begin
    DrawTexturePro(texture,
      RectangleCreate(source.x, source.y, (dest.width / tileWidth) * source.width, (dest.height / tileHeight) * source.height),
      RectangleCreate(dest.x, dest.y, dest.width, dest.height), origin, rotation, tint);
  end
  else if dest.width <= tileWidth then
  begin
    dy := 0;
    while dy + tileHeight < dest.height do
    begin
      DrawTexturePro(texture,
        RectangleCreate(source.x, source.y, (dest.width / tileWidth) * source.width, source.height),
        RectangleCreate(dest.x, dest.y + dy, dest.width, tileHeight), origin, rotation, tint);
      dy := dy + tileHeight;
    end;
    if dy < dest.height then
    begin
      DrawTexturePro(texture,
        RectangleCreate(source.x, source.y, (dest.width / tileWidth) * source.width, ((dest.height - dy) / tileHeight) * source.height),
        RectangleCreate(dest.x, dest.y + dy, dest.width, dest.height - dy), origin, rotation, tint);
    end;
  end
  else if dest.height <= tileHeight then
  begin
    dx := 0;
    while dx + tileWidth < dest.width do
    begin
      DrawTexturePro(texture,
        RectangleCreate(source.x, source.y, source.width, (dest.height / tileHeight) * source.height),
        RectangleCreate(dest.x + dx, dest.y, tileWidth, dest.height), origin, rotation, tint);
      dx := dx + tileWidth;
    end;
    if dx < dest.width then
    begin
      DrawTexturePro(texture,
        RectangleCreate(source.x, source.y, ((dest.width - dx) / tileWidth) * source.width, (dest.height / tileHeight) * source.height),
        RectangleCreate(dest.x + dx, dest.y, dest.width - dx, dest.height), origin, rotation, tint);
    end;
  end
  else
  begin
    dx := 0;
    while dx + tileWidth < dest.width do
    begin
      dy := 0;
      while dy + tileHeight < dest.height do
      begin
        DrawTexturePro(texture, source,
          RectangleCreate(dest.x + dx, dest.y + dy, tileWidth, tileHeight), origin, rotation, tint);
        dy := dy + tileHeight;
      end;
      if dy < dest.height then
      begin
        DrawTexturePro(texture,
          RectangleCreate(source.x, source.y, source.width, ((dest.height - dy) / tileHeight) * source.height),
          RectangleCreate(dest.x + dx, dest.y + dy, tileWidth, dest.height - dy), origin, rotation, tint);
      end;
      dx := dx + tileWidth;
    end;
    if dx < dest.width then
    begin
      dy := 0;
      while dy + tileHeight < dest.height do
      begin
        DrawTexturePro(texture,
          RectangleCreate(source.x, source.y, ((dest.width - dx) / tileWidth) * source.width, source.height),
          RectangleCreate(dest.x + dx, dest.y + dy, dest.width - dx, tileHeight), origin, rotation, tint);
        dy := dy + tileHeight;
      end;
      if dy < dest.height then
      begin
        DrawTexturePro(texture,
          RectangleCreate(source.x, source.y, ((dest.width - dx) / tileWidth) * source.width, ((dest.height - dy) / tileHeight) * source.height),
          RectangleCreate(dest.x + dx, dest.y + dy, dest.width - dx, dest.height - dy), origin, rotation, tint);
      end;
    end;
  end;
end;

var
  texPattern: TTexture2D;
  recPattern: array[0..5] of TRectangle;
  colors: array[0..9] of TColorB;
  colorRec: array[0..9] of TRectangle;
  activePattern, activeCol: integer;
  scale, rotation: single;
  i, x, y: integer;
  mouse: TVector2;

begin
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - tiled drawing');

  texPattern := LoadTexture(PChar(GetApplicationDirectory + 'resources/patterns.png'));
  SetTextureFilter(texPattern, TEXTURE_FILTER_BILINEAR);

  recPattern[0] := RectangleCreate(3, 3, 66, 66);
  recPattern[1] := RectangleCreate(75, 3, 100, 100);
  recPattern[2] := RectangleCreate(3, 75, 66, 66);
  recPattern[3] := RectangleCreate(7, 156, 50, 50);
  recPattern[4] := RectangleCreate(85, 106, 90, 45);
  recPattern[5] := RectangleCreate(75, 154, 100, 60);

  colors[0] := BLACK; colors[1] := MAROON; colors[2] := ORANGE; colors[3] := BLUE; colors[4] := PURPLE;
  colors[5] := BEIGE; colors[6] := LIME; colors[7] := RED; colors[8] := DARKGRAY; colors[9] := SKYBLUE;

  x := 0;
  y := 0;
  for i := 0 to 9 do
  begin
    colorRec[i].x := 2.0 + MARGIN_SIZE + x;
    colorRec[i].y := 22.0 + 256.0 + MARGIN_SIZE + y;
    colorRec[i].width := COLOR_SIZE * 2.0;
    colorRec[i].height := COLOR_SIZE;

    if i = 4 then
    begin
      x := 0;
      y := y + COLOR_SIZE + MARGIN_SIZE;
    end
    else
      x := x + (COLOR_SIZE * 2 + MARGIN_SIZE);
  end;

  activePattern := 0;
  activeCol := 0;
  scale := 1.0;
  rotation := 0.0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
      mouse := GetMousePosition();

      for i := 0 to 5 do
      begin
        if CheckCollisionPointRec(mouse, RectangleCreate(
          2 + MARGIN_SIZE + recPattern[i].x,
          40 + MARGIN_SIZE + recPattern[i].y,
          recPattern[i].width, recPattern[i].height)) then
        begin
          activePattern := i;
          Break;
        end;
      end;

      for i := 0 to 9 do
      begin
        if CheckCollisionPointRec(mouse, colorRec[i]) then
        begin
          activeCol := i;
          Break;
        end;
      end;
    end;

    if IsKeyPressed(KEY_UP) then scale := scale + 0.25;
    if IsKeyPressed(KEY_DOWN) then scale := scale - 0.25;
    if scale > 10.0 then scale := 10.0
    else if scale <= 0.0 then scale := 0.25;

    if IsKeyPressed(KEY_LEFT) then rotation := rotation - 25.0;
    if IsKeyPressed(KEY_RIGHT) then rotation := rotation + 25.0;

    if IsKeyPressed(KEY_SPACE) then begin rotation := 0.0; scale := 1.0; end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawTextureTiled(texPattern, recPattern[activePattern],
        RectangleCreate(OPT_WIDTH + MARGIN_SIZE, MARGIN_SIZE,
          GetScreenWidth() - OPT_WIDTH - 2 * MARGIN_SIZE,
          GetScreenHeight() - 2 * MARGIN_SIZE),
        Vector2Create(0, 0), rotation, scale, colors[activeCol]);

      DrawRectangle(MARGIN_SIZE, MARGIN_SIZE, OPT_WIDTH - MARGIN_SIZE,
        GetScreenHeight() - 2 * MARGIN_SIZE, ColorAlpha(LIGHTGRAY, 0.5));

      DrawText('Select Pattern', 2 + MARGIN_SIZE, 30 + MARGIN_SIZE, 10, BLACK);
      DrawTexture(texPattern, 2 + MARGIN_SIZE, 40 + MARGIN_SIZE, BLACK);
      DrawRectangle(2 + MARGIN_SIZE + Trunc(recPattern[activePattern].x),
        40 + MARGIN_SIZE + Trunc(recPattern[activePattern].y),
        Trunc(recPattern[activePattern].width),
        Trunc(recPattern[activePattern].height), ColorAlpha(DARKBLUE, 0.3));

      DrawText('Select Color', 2 + MARGIN_SIZE, 10 + 256 + MARGIN_SIZE, 10, BLACK);
      for i := 0 to 9 do
      begin
        DrawRectangleRec(colorRec[i], colors[i]);
        if activeCol = i then DrawRectangleLinesEx(colorRec[i], 3, ColorAlpha(WHITE, 0.5));
      end;

      DrawText('Scale (UP/DOWN to change)', 2 + MARGIN_SIZE, 80 + 256 + MARGIN_SIZE, 10, BLACK);
      DrawText(TextFormat('%.2fx', scale), 2 + MARGIN_SIZE, 92 + 256 + MARGIN_SIZE, 20, BLACK);

      DrawText('Rotation (LEFT/RIGHT to change)', 2 + MARGIN_SIZE, 122 + 256 + MARGIN_SIZE, 10, BLACK);
      DrawText(TextFormat('%.0f degrees', rotation), 2 + MARGIN_SIZE, 134 + 256 + MARGIN_SIZE, 20, BLACK);

      DrawText('Press [SPACE] to reset', 2 + MARGIN_SIZE, 164 + 256 + MARGIN_SIZE, 10, DARKBLUE);

      DrawText(TextFormat('%i FPS', GetFPS()), 2 + MARGIN_SIZE, 2 + MARGIN_SIZE, 20, BLACK);
    EndDrawing();
  end;

  UnloadTexture(texPattern);
  CloseWindow();
end.
