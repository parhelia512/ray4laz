program core_undo_redo;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_UNDO_STATES = 26;
  GRID_CELL_SIZE = 24;
  MAX_GRID_CELLS_X = 30;
  MAX_GRID_CELLS_Y = 13;

type
  TPoint = record
    x, y: integer;
  end;

  TPlayerState = record
    cell: TPoint;
    color: TColorB;
  end;

procedure DrawUndoBuffer(position: TVector2; firstUndoIndex, lastUndoIndex, currentUndoIndex, slotSize: integer);
var
  i: integer;
begin
  DrawRectangle(Trunc(position.x) + 8 + slotSize * currentUndoIndex, Trunc(position.y) - 10, 8, 8, RED);
  DrawRectangleLines(Trunc(position.x) + 2 + slotSize * firstUndoIndex, Trunc(position.y) + 27, 8, 8, BLACK);
  DrawRectangle(Trunc(position.x) + 14 + slotSize * lastUndoIndex, Trunc(position.y) + 27, 8, 8, BLACK);

  for i := 0 to MAX_UNDO_STATES - 1 do
  begin
    DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, LIGHTGRAY);
    DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, GRAY);
  end;

  if firstUndoIndex <= lastUndoIndex then
  begin
    for i := firstUndoIndex to lastUndoIndex do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, SKYBLUE);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, BLUE);
    end;
  end
  else
  begin
    for i := firstUndoIndex to MAX_UNDO_STATES - 1 do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, SKYBLUE);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, BLUE);
    end;
    for i := 0 to lastUndoIndex do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, SKYBLUE);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, BLUE);
    end;
  end;

  if firstUndoIndex < currentUndoIndex then
  begin
    for i := firstUndoIndex to currentUndoIndex - 1 do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, GREEN);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, LIME);
    end;
  end
  else if currentUndoIndex < firstUndoIndex then
  begin
    for i := firstUndoIndex to MAX_UNDO_STATES - 1 do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, GREEN);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, LIME);
    end;
    for i := 0 to currentUndoIndex - 1 do
    begin
      DrawRectangle(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, GREEN);
      DrawRectangleLines(Trunc(position.x) + slotSize * i, Trunc(position.y), slotSize, slotSize, LIME);
    end;
  end;

  DrawRectangle(Trunc(position.x) + slotSize * currentUndoIndex, Trunc(position.y), slotSize, slotSize, GOLD);
  DrawRectangleLines(Trunc(position.x) + slotSize * currentUndoIndex, Trunc(position.y), slotSize, slotSize, ORANGE);
end;

var
  currentUndoIndex, firstUndoIndex, lastUndoIndex: integer;
  undoFrameCounter: integer;
  undoInfoPos: TVector2;
  player: TPlayerState;
  states: array[0..MAX_UNDO_STATES - 1] of TPlayerState;
  gridPosition: TVector2;
  i: integer;
  nextUndoIndex: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - undo redo');

  currentUndoIndex := 0;
  firstUndoIndex := 0;
  lastUndoIndex := 0;
  undoFrameCounter := 0;
  undoInfoPos := Vector2Create(110, 400);

  player.cell.x := 10;
  player.cell.y := 10;
  player.color := RED;

  for i := 0 to MAX_UNDO_STATES - 1 do
    states[i] := player;

  gridPosition := Vector2Create(40, 60);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_RIGHT) then Inc(player.cell.x)
    else if IsKeyPressed(KEY_LEFT) then Dec(player.cell.x)
    else if IsKeyPressed(KEY_UP) then Dec(player.cell.y)
    else if IsKeyPressed(KEY_DOWN) then Inc(player.cell.y);

    if player.cell.x < 0 then player.cell.x := 0
    else if player.cell.x >= MAX_GRID_CELLS_X then player.cell.x := MAX_GRID_CELLS_X - 1;
    if player.cell.y < 0 then player.cell.y := 0
    else if player.cell.y >= MAX_GRID_CELLS_Y then player.cell.y := MAX_GRID_CELLS_Y - 1;

    if IsKeyPressed(KEY_SPACE) then
    begin
      player.color.r := GetRandomValue(20, 255);
      player.color.g := GetRandomValue(20, 220);
      player.color.b := GetRandomValue(20, 240);
    end;

    Inc(undoFrameCounter);
    if undoFrameCounter >= 2 then
    begin
      if not CompareMem(@states[currentUndoIndex], @player, SizeOf(TPlayerState)) then
      begin
        Inc(currentUndoIndex);
        if currentUndoIndex >= MAX_UNDO_STATES then currentUndoIndex := 0;
        if currentUndoIndex = firstUndoIndex then Inc(firstUndoIndex);
        if firstUndoIndex >= MAX_UNDO_STATES then firstUndoIndex := 0;

        states[currentUndoIndex] := player;
        lastUndoIndex := currentUndoIndex;
      end;
      undoFrameCounter := 0;
    end;

    if IsKeyDown(KEY_LEFT_CONTROL) and IsKeyPressed(KEY_Z) then
    begin
      if currentUndoIndex <> firstUndoIndex then
      begin
        Dec(currentUndoIndex);
        if currentUndoIndex < 0 then currentUndoIndex := MAX_UNDO_STATES - 1;
        if not CompareMem(@states[currentUndoIndex], @player, SizeOf(TPlayerState)) then
          player := states[currentUndoIndex];
      end;
    end;

    if IsKeyDown(KEY_LEFT_CONTROL) and IsKeyPressed(KEY_Y) then
    begin
      if currentUndoIndex <> lastUndoIndex then
      begin
        nextUndoIndex := currentUndoIndex + 1;
        if nextUndoIndex >= MAX_UNDO_STATES then nextUndoIndex := 0;
        if nextUndoIndex <> firstUndoIndex then
        begin
          currentUndoIndex := nextUndoIndex;
          if not CompareMem(@states[currentUndoIndex], @player, SizeOf(TPlayerState)) then
            player := states[currentUndoIndex];
        end;
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawText('[ARROWS] MOVE PLAYER - [SPACE] CHANGE PLAYER COLOR', 40, 20, 20, DARKGRAY);

      if lastUndoIndex > firstUndoIndex then
      begin
        for i := firstUndoIndex to currentUndoIndex - 1 do
          DrawRectangle(Trunc(gridPosition.x) + states[i].cell.x * GRID_CELL_SIZE, Trunc(gridPosition.y) + states[i].cell.y * GRID_CELL_SIZE,
            GRID_CELL_SIZE, GRID_CELL_SIZE, LIGHTGRAY);
      end
      else if firstUndoIndex > lastUndoIndex then
      begin
        if (currentUndoIndex < MAX_UNDO_STATES) and (currentUndoIndex > lastUndoIndex) then
        begin
          for i := firstUndoIndex to currentUndoIndex - 1 do
            DrawRectangle(Trunc(gridPosition.x) + states[i].cell.x * GRID_CELL_SIZE, Trunc(gridPosition.y) + states[i].cell.y * GRID_CELL_SIZE,
              GRID_CELL_SIZE, GRID_CELL_SIZE, LIGHTGRAY);
        end
        else
        begin
          for i := firstUndoIndex to MAX_UNDO_STATES - 1 do
            DrawRectangle(Trunc(gridPosition.x) + states[i].cell.x * GRID_CELL_SIZE, Trunc(gridPosition.y) + states[i].cell.y * GRID_CELL_SIZE,
              GRID_CELL_SIZE, GRID_CELL_SIZE, LIGHTGRAY);
          for i := 0 to currentUndoIndex - 1 do
            DrawRectangle(Trunc(gridPosition.x) + states[i].cell.x * GRID_CELL_SIZE, Trunc(gridPosition.y) + states[i].cell.y * GRID_CELL_SIZE,
              GRID_CELL_SIZE, GRID_CELL_SIZE, LIGHTGRAY);
        end;
      end;

      for i := 0 to MAX_GRID_CELLS_Y do
        DrawLine(Trunc(gridPosition.x), Trunc(gridPosition.y) + i * GRID_CELL_SIZE,
          Trunc(gridPosition.x) + MAX_GRID_CELLS_X * GRID_CELL_SIZE, Trunc(gridPosition.y) + i * GRID_CELL_SIZE, GRAY);
      for i := 0 to MAX_GRID_CELLS_X do
        DrawLine(Trunc(gridPosition.x) + i * GRID_CELL_SIZE, Trunc(gridPosition.y),
          Trunc(gridPosition.x) + i * GRID_CELL_SIZE, Trunc(gridPosition.y) + MAX_GRID_CELLS_Y * GRID_CELL_SIZE, GRAY);

      DrawRectangle(Trunc(gridPosition.x) + player.cell.x * GRID_CELL_SIZE, Trunc(gridPosition.y) + player.cell.y * GRID_CELL_SIZE,
        GRID_CELL_SIZE + 1, GRID_CELL_SIZE + 1, player.color);

      DrawText('UNDO STATES:', Trunc(undoInfoPos.x) - 85, Trunc(undoInfoPos.y) + 9, 10, DARKGRAY);
      DrawUndoBuffer(undoInfoPos, firstUndoIndex, lastUndoIndex, currentUndoIndex, 24);

    EndDrawing();
  end;

  CloseWindow();
end.
