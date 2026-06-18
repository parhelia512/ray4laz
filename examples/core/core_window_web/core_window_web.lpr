program core_window_web;

{$mode objfpc}{$H+}

uses cmem, raylib;

var
  screenWidth, screenHeight: integer;

procedure UpdateDrawFrame;
begin
  BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawText('Congrats! You created your first window!', 190, 200, 20, LIGHTGRAY);
  EndDrawing();
end;

begin
  screenWidth := 800;
  screenHeight := 450;

  InitWindow(screenWidth, screenHeight, 'raylib [core] example - window web');
  SetTargetFPS(60);

  while not WindowShouldClose() do
    UpdateDrawFrame;

  CloseWindow();
end.
