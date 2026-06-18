program textures_cellular_automata;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  imageWidth = 800;
  imageHeight = 800 div 2;

  // Rule button sizes and positions
  drawRuleStartX = 585;
  drawRuleStartY = 10;
  drawRuleSpacing = 15;
  drawRuleGroupSpacing = 50;
  drawRuleSize = 14;
  drawRuleInnerSize = 10;

  // Preset button sizes
  presetsSizeX = 42;
  presetsSizeY = 22;

  linesUpdatedPerFrame = 4;

// Compute next line pixels
procedure ComputeLine(var image: TImage; line, rule: integer);
var
  i: integer;
  prevValue: integer;
  currValue: boolean;
begin
  // Boundaries are not computed, always 0
  for i := 1 to imageWidth - 2 do
  begin
    // Get, from the previous line, the 3 pixels states as a binary value
    prevValue := 0;
    if GetImageColor(image, i - 1, line - 1).r < 5 then prevValue := prevValue + 4;  // Left pixel
    if GetImageColor(image, i,     line - 1).r < 5 then prevValue := prevValue + 2;  // Center pixel
    if GetImageColor(image, i + 1, line - 1).r < 5 then prevValue := prevValue + 1;  // Right pixel

    // Get next value from rule bitmask
    currValue := (rule and (1 shl prevValue)) <> 0;

    // Update pixel color
    if currValue then
      ImageDrawPixel(@image, i, line, BLACK)
    else
      ImageDrawPixel(@image, i, line, RAYWHITE);
  end;
end;

var
  image: TImage;
  texture: TTexture2D;
  rule, line: integer;
  presetValues: array[0..9] of integer = (18, 30, 60, 86, 102, 124, 126, 150, 182, 225);
  presetsCount: integer;
  mouse: TVector2;
  mouseInCell: integer;
  i, cellX, cellY: integer;
  j: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [textures] example - cellular automata');

  // Image that contains the cellular automaton
  image := GenImageColor(imageWidth, imageHeight, RAYWHITE);
  // The top central pixel set as black
  ImageDrawPixel(@image, imageWidth div 2, 0, BLACK);

  texture := LoadTextureFromImage(image);

  presetsCount := 10;
  rule := 30;  // Starting rule
  line := 1;   // Line to compute, starting from line 1

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    mouse := GetMousePosition();
    mouseInCell := -1;   // -1: outside any button; 0-7: rule cells; 8+: preset cells

    // Check mouse on rule cells
    for i := 0 to 7 do
    begin
      cellX := drawRuleStartX - drawRuleGroupSpacing * i + drawRuleSpacing;
      cellY := drawRuleStartY + drawRuleSpacing;
      if (mouse.x >= cellX) and (mouse.x <= cellX + drawRuleSize) and
         (mouse.y >= cellY) and (mouse.y <= cellY + drawRuleSize) then
      begin
        mouseInCell := i;  // 0-7: rule cells
        Break;
      end;
    end;

    // Check mouse on preset cells
    if mouseInCell < 0 then
    begin
      for i := 0 to presetsCount - 1 do
      begin
        cellX := 4 + (presetsSizeX + 2) * (i div 2);
        cellY := 2 + (presetsSizeY + 2) * (i mod 2);
        if (mouse.x >= cellX) and (mouse.x <= cellX + presetsSizeX) and
           (mouse.y >= cellY) and (mouse.y <= cellY + presetsSizeY) then
        begin
          mouseInCell := i + 8;  // 8+: preset cells
          Break;
        end;
      end;
    end;

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and (mouseInCell >= 0) then
    begin
      // Rule changed both by selecting a preset or toggling a bit
      if mouseInCell < 8 then
        rule := rule xor (1 shl mouseInCell)
      else
        rule := presetValues[mouseInCell - 8];

      // Reset image
      ImageClearBackground(@image, RAYWHITE);
      ImageDrawPixel(@image, imageWidth div 2, 0, BLACK);
      line := 1;
    end;

    // Compute next lines
    if line < imageHeight then
    begin
      for i := 0 to linesUpdatedPerFrame - 1 do
      begin
        if line + i < imageHeight then
          ComputeLine(image, line + i, rule);
      end;
      line := line + linesUpdatedPerFrame;

      UpdateTexture(texture, image.data);
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw cellular automaton texture
      DrawTexture(texture, 0, screenHeight - imageHeight, WHITE);

      // Draw preset values
      for i := 0 to presetsCount - 1 do
      begin
        cellX := 4 + (presetsSizeX + 2) * (i div 2);
        cellY := 2 + (presetsSizeY + 2) * (i mod 2);

        DrawText(PChar(IntToStr(presetValues[i])), 8 + (presetsSizeX + 2) * (i div 2),
          4 + (presetsSizeY + 2) * (i mod 2), 20, GRAY);
        DrawRectangleLines(cellX, cellY, presetsSizeX, presetsSizeY, BLUE);

        // If the mouse is on this preset, highlight it
        if mouseInCell = i + 8 then
          DrawRectangleLinesEx(RectangleCreate(cellX - 2, cellY - 2,
            presetsSizeX + 4, presetsSizeY + 4), 3, RED);
      end;

      // Draw rule bits
      for i := 0 to 7 do
      begin
        // The three input bits
        for j := 0 to 2 do
        begin
          cellX := drawRuleStartX - drawRuleGroupSpacing * i + drawRuleSpacing * j;
          cellY := drawRuleStartY;
          DrawRectangleLines(cellX, cellY, drawRuleSize, drawRuleSize, GRAY);
          if (i and (4 shr j)) <> 0 then
            DrawRectangle(cellX + 2, cellY + 2, drawRuleInnerSize, drawRuleInnerSize, BLACK);
        end;

        // The output bit
        cellX := drawRuleStartX - drawRuleGroupSpacing * i + drawRuleSpacing;
        cellY := drawRuleStartY + drawRuleSpacing;
        DrawRectangleLines(cellX, cellY, drawRuleSize, drawRuleSize, BLUE);
        if (rule and (1 shl i)) <> 0 then
          DrawRectangle(cellX + 2, cellY + 2, drawRuleInnerSize, drawRuleInnerSize, BLACK);

        // If the mouse is on this rule bit, highlight it
        if mouseInCell = i then
          DrawRectangleLinesEx(RectangleCreate(cellX - 2, cellY - 2,
            drawRuleSize + 4, drawRuleSize + 4), 3, RED);
      end;

      DrawText(PChar(Format('RULE: %d', [rule])), drawRuleStartX + drawRuleSpacing * 4,
        drawRuleStartY + 1, 30, GRAY);

    EndDrawing();
  end;

  // De-Initialization
  UnloadImage(image);
  UnloadTexture(texture);
  CloseWindow();
end.
