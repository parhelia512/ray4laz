program core_input_actions;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;

type
  TActionType = 0..5;

  TActionInput = record
    key: integer;
    button: integer;
  end;

var
  gamepadIndex: integer;
  actionInputs: array[0..5] of record key, button: integer; end;
  actionSet: char;
  releaseAction: boolean;
  position, size: TVector2;

function IsActionPressed(action: TActionType): boolean;
begin
  Result := False;
  if action < 5 then
    Result := IsKeyPressed(actionInputs[action].key) or IsGamepadButtonPressed(gamepadIndex, actionInputs[action].button);
end;

function IsActionReleased(action: TActionType): boolean;
begin
  Result := False;
  if action < 5 then
    Result := IsKeyReleased(actionInputs[action].key) or IsGamepadButtonReleased(gamepadIndex, actionInputs[action].button);
end;

function IsActionDown(action: TActionType): boolean;
begin
  Result := False;
  if action < 5 then
    Result := IsKeyDown(actionInputs[action].key) or IsGamepadButtonDown(gamepadIndex, actionInputs[action].button);
end;

procedure SetActionsDefault;
begin
  actionInputs[1].key := KEY_W;
  actionInputs[2].key := KEY_S;
  actionInputs[3].key := KEY_A;
  actionInputs[4].key := KEY_D;
  actionInputs[5].key := KEY_SPACE;
  actionInputs[1].button := GAMEPAD_BUTTON_LEFT_FACE_UP;
  actionInputs[2].button := GAMEPAD_BUTTON_LEFT_FACE_DOWN;
  actionInputs[3].button := GAMEPAD_BUTTON_LEFT_FACE_LEFT;
  actionInputs[4].button := GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
  actionInputs[5].button := GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
end;

procedure SetActionsCursor;
begin
  actionInputs[1].key := KEY_UP;
  actionInputs[2].key := KEY_DOWN;
  actionInputs[3].key := KEY_LEFT;
  actionInputs[4].key := KEY_RIGHT;
  actionInputs[5].key := KEY_SPACE;
  actionInputs[1].button := GAMEPAD_BUTTON_RIGHT_FACE_UP;
  actionInputs[2].button := GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
  actionInputs[3].button := GAMEPAD_BUTTON_RIGHT_FACE_LEFT;
  actionInputs[4].button := GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
  actionInputs[5].button := GAMEPAD_BUTTON_LEFT_FACE_DOWN;
end;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - input actions');

  gamepadIndex := 0;
  actionSet := #0;
  SetActionsDefault;
  releaseAction := False;

  position := Vector2Create(400.0, 200.0);
  size := Vector2Create(40.0, 40.0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    gamepadIndex := 0;

    if IsActionDown(1) then position.y := position.y - 2;
    if IsActionDown(2) then position.y := position.y + 2;
    if IsActionDown(3) then position.x := position.x - 2;
    if IsActionDown(4) then position.x := position.x + 2;
    if IsActionPressed(5) then
    begin
      position.x := (screenWidth - size.x) / 2;
      position.y := (screenHeight - size.y) / 2;
    end;

    releaseAction := False;
    if IsActionReleased(5) then releaseAction := True;

    if IsKeyPressed(KEY_TAB) then
    begin
      if actionSet = #0 then
      begin
        actionSet := #1;
        SetActionsCursor;
      end
      else
      begin
        actionSet := #0;
        SetActionsDefault;
      end;
    end;

    BeginDrawing();
      ClearBackground(GRAY);

      // Fix: Use a conditional expression instead of IfThen generic
      if releaseAction then
        DrawRectangleV(position, size, BLUE)
      else
        DrawRectangleV(position, size, RED);

      if actionSet = #0 then
        DrawText('Current input set: WASD (default)', 10, 10, 20, WHITE)
      else
        DrawText('Current input set: Arrow keys', 10, 10, 20, WHITE);
      DrawText('Use TAB key to toggles Actions keyset', 10, 50, 20, GREEN);
    EndDrawing();
  end;

  CloseWindow();
end.
