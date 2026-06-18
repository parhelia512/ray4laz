program shapes_recursive_tree;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raygui, math;

const
  screenWidth = 800;
  screenHeight = 450;

type
  TBranch = record
    start, endPos: TVector2;
    angle, length: single;
  end;

var
  start: TVector2;
  angle, thick, treeDepth, branchDecay, length: single;
  bezier: boolean;
  theta: single;
  maxBranches, count, i: integer;
  branches: array[0..1029] of TBranch;
  nextLength, angle1, angle2: single;
  branchStart, branchEnd1, branchEnd2: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - recursive tree');

  start := Vector2Create(screenWidth / 2.0 - 125.0, screenHeight);
  angle := 40.0;
  thick := 1.0;
  treeDepth := 10.0;
  branchDecay := 0.66;
  length := 120.0;
  bezier := False;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    theta := angle * DEG2RAD;
    maxBranches := Trunc(Power(2, Floor(treeDepth)));
    count := 0;

    branches[count].start := start;
    branches[count].endPos := Vector2Create(start.x + length * Sin(0.0), start.y - length * Cos(0.0));
    branches[count].angle := 0.0;
    branches[count].length := length;
    Inc(count);

    i := 0;
    while i < count do
    begin
      if branches[i].length < 2 then
      begin
        Inc(i);
        Continue;
      end;

      nextLength := branches[i].length * branchDecay;

      if (count < maxBranches) and (nextLength >= 2) then
      begin
        branchStart := branches[i].endPos;
        angle1 := branches[i].angle + theta;
        branchEnd1 := Vector2Create(branchStart.x + nextLength * Sin(angle1), branchStart.y - nextLength * Cos(angle1));
        branches[count].start := branchStart;
        branches[count].endPos := branchEnd1;
        branches[count].angle := angle1;
        branches[count].length := nextLength;
        Inc(count);

        angle2 := branches[i].angle - theta;
        branchEnd2 := Vector2Create(branchStart.x + nextLength * Sin(angle2), branchStart.y - nextLength * Cos(angle2));
        branches[count].start := branchStart;
        branches[count].endPos := branchEnd2;
        branches[count].angle := angle2;
        branches[count].length := nextLength;
        Inc(count);
      end;

      Inc(i);
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      for i := 0 to count - 1 do
      begin
        if branches[i].length >= 2 then
        begin
          if bezier then
            DrawLineBezier(branches[i].start, branches[i].endPos, thick, RED)
          else
            DrawLineEx(branches[i].start, branches[i].endPos, thick, RED);
        end;
      end;

      DrawLine(580, 0, 580, GetScreenHeight(), ColorCreate(218, 218, 218, 255));
      DrawRectangle(580, 0, GetScreenWidth(), GetScreenHeight(), ColorCreate(232, 232, 232, 255));

      GuiSliderBar(RectangleCreate(640, 40, 120, 20), 'Angle', PChar(Format('%.0f', [angle])), @angle, 0, 180);
      GuiSliderBar(RectangleCreate(640, 70, 120, 20), 'Length', PChar(Format('%.0f', [length])), @length, 12.0, 240.0);
      GuiSliderBar(RectangleCreate(640, 100, 120, 20), 'Decay', PChar(Format('%.2f', [branchDecay])), @branchDecay, 0.1, 0.78);
      GuiSliderBar(RectangleCreate(640, 130, 120, 20), 'Depth', PChar(Format('%.0f', [treeDepth])), @treeDepth, 1.0, 10.0);
      GuiSliderBar(RectangleCreate(640, 160, 120, 20), 'Thick', PChar(Format('%.0f', [thick])), @thick, 1, 8);
      GuiCheckBox(RectangleCreate(640, 190, 20, 20), 'Bezier', @bezier);

      DrawFPS(10, 10);
    EndDrawing();
  end;

  CloseWindow();
end.
