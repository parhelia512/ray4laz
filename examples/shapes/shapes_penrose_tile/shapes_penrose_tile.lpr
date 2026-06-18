program shapes_penrose_tile;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  STR_MAX_SIZE = 10000;
  TURTLE_STACK_MAX_SIZE = 50;

type
  TTurtleState = record
    origin: TVector2;
    angle: single;
  end;

  TPenroseLSystem = record
    steps: integer;
    production: PChar;
    ruleW, ruleX, ruleY, ruleZ: PChar;
    drawLength, theta: single;
  end;

var
  turtleStack: array[0..TURTLE_STACK_MAX_SIZE - 1] of TTurtleState;
  turtleTop: integer;

procedure PushTurtleState(state: TTurtleState);
begin
  if turtleTop < (TURTLE_STACK_MAX_SIZE - 1) then
  begin
    Inc(turtleTop);
    turtleStack[turtleTop] := state;
  end
  else
    TraceLog(LOG_WARNING, 'TURTLE STACK OVERFLOW!');
end;

function PopTurtleState: TTurtleState;
begin
  if turtleTop >= 0 then
  begin
    Result := turtleStack[turtleTop];
    Dec(turtleTop);
  end
  else
  begin
    TraceLog(LOG_WARNING, 'TURTLE STACK UNDERFLOW!');
    Result := Default(TTurtleState);
  end;
end;

function CreatePenroseLSystem(drawLength: single): TPenroseLSystem;
begin
  Result.steps := 0;
  Result.ruleW := 'YF++ZF4-XF[-YF4-WF]++';
  Result.ruleX := '+YF--ZF[3-WF--XF]+';
  Result.ruleY := '-WF++XF[+++YF++ZF]-';
  Result.ruleZ := '--YF++++WF[+ZF++++XF]--XF';
  Result.drawLength := drawLength;
  Result.theta := 36.0;

  GetMem(Result.production, SizeOf(AnsiChar) * STR_MAX_SIZE);
  FillChar(Result.production^, STR_MAX_SIZE, 0);
  Move('[X]++[X]++[X]++[X]++[X]'[1], Result.production^, Length('[X]++[X]++[X]++[X]++[X]'));
end;

procedure BuildProductionStep(var ls: TPenroseLSystem);
var
  newProduction: PChar;
  productionLength, i, t, remainingSpace: integer;
  step: AnsiChar;
begin
  GetMem(newProduction, SizeOf(AnsiChar) * STR_MAX_SIZE);
  FillChar(newProduction^, STR_MAX_SIZE, 0);

  productionLength := StrLen(ls.production);

  for i := 0 to productionLength - 1 do
  begin
    step := ls.production[i];
    remainingSpace := STR_MAX_SIZE - StrLen(newProduction) - 1;

    case step of
      'W': StrLCat(newProduction, ls.ruleW, remainingSpace);
      'X': StrLCat(newProduction, ls.ruleX, remainingSpace);
      'Y': StrLCat(newProduction, ls.ruleY, remainingSpace);
      'Z': StrLCat(newProduction, ls.ruleZ, remainingSpace);
    else
      if step <> 'F' then
      begin
        t := StrLen(newProduction);
        newProduction[t] := step;
        newProduction[t + 1] := #0;
      end;
    end;
  end;

  ls.drawLength := ls.drawLength * 0.5;
  Move(newProduction^, ls.production^, STR_MAX_SIZE);

  FreeMem(newProduction);
end;

procedure DrawPenroseLSystem(var ls: TPenroseLSystem);
var
  screenCenter: TVector2;
  turtle: TTurtleState;
  repeats, productionLength, i, j: integer;
  step: AnsiChar;
  radAngle: single;
  startPosWorld, startPosScreen, endPosScreen: TVector2;
begin
  screenCenter := Vector2Create(GetScreenWidth() / 2.0, GetScreenHeight() / 2.0);

  turtle.origin := Vector2Create(0, 0);
  turtle.angle := -90.0;

  repeats := 1;
  productionLength := StrLen(ls.production);
  Inc(ls.steps, 12);
  if ls.steps > productionLength then ls.steps := productionLength;

  for i := 0 to ls.steps - 1 do
  begin
    step := ls.production[i];
    if step = 'F' then
    begin
      for j := 0 to repeats - 1 do
      begin
        startPosWorld := turtle.origin;
        radAngle := DEG2RAD * turtle.angle;
        turtle.origin.x := turtle.origin.x + ls.drawLength * Cos(radAngle);
        turtle.origin.y := turtle.origin.y + ls.drawLength * Sin(radAngle);
        startPosScreen := Vector2Create(startPosWorld.x + screenCenter.x, startPosWorld.y + screenCenter.y);
        endPosScreen := Vector2Create(turtle.origin.x + screenCenter.x, turtle.origin.y + screenCenter.y);
        DrawLineEx(startPosScreen, endPosScreen, 2, Fade(BLACK, 0.2));
      end;
      repeats := 1;
    end
    else if step = '+' then
    begin
      for j := 0 to repeats - 1 do
        turtle.angle := turtle.angle + ls.theta;
      repeats := 1;
    end
    else if step = '-' then
    begin
      for j := 0 to repeats - 1 do
        turtle.angle := turtle.angle - ls.theta;
      repeats := 1;
    end
    else if step = '[' then
      PushTurtleState(turtle)
    else if step = ']' then
      turtle := PopTurtleState
    else if (Ord(step) >= 48) and (Ord(step) <= 57) then
      repeats := Ord(step) - 48;
  end;

  turtleTop := -1;
end;

var
  ls: TPenroseLSystem;
  drawLength: single;
  minGenerations, maxGenerations, generations: integer;
  rebuild: boolean;
  i: integer;

begin
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - penrose tile');

  drawLength := 460.0;
  minGenerations := 0;
  maxGenerations := 4;
  generations := 0;

  ls := CreatePenroseLSystem(drawLength * (generations / maxGenerations));
  for i := 0 to generations - 1 do
    BuildProductionStep(ls);

  SetTargetFPS(120);

  while not WindowShouldClose() do
  begin
    rebuild := False;

    if IsKeyPressed(KEY_UP) then
    begin
      if generations < maxGenerations then
      begin
        Inc(generations);
        rebuild := True;
      end;
    end
    else if IsKeyPressed(KEY_DOWN) then
    begin
      if generations > minGenerations then
      begin
        Dec(generations);
        if generations > 0 then rebuild := True;
      end;
    end;

    if rebuild then
    begin
      FreeMem(ls.production);
      ls := CreatePenroseLSystem(drawLength * (generations / maxGenerations));
      for i := 0 to generations - 1 do
        BuildProductionStep(ls);
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      if generations > 0 then DrawPenroseLSystem(ls);

      DrawText('penrose l-system', 10, 10, 20, DARKGRAY);
      DrawText('press up or down to change generations', 10, 30, 20, DARKGRAY);
      DrawText(PChar(Format('generations: %d', [generations])), 10, 50, 20, DARKGRAY);
    EndDrawing();
  end;

  FreeMem(ls.production);
  CloseWindow();
end.
