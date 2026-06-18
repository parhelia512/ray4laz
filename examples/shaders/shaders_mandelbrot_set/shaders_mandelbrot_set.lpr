program shaders_mandelbrot_set;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, math;

const
  screenWidth = 800;
  screenHeight = 450;
  GLSL_VERSION = 330;
  zoomSpeed = 1.01;
  offsetSpeedMul = 2.0;
  startingZoom = 0.6;
  startingOffset: array[0..1] of single = (-0.5, 0.0);

  pointsOfInterest: array[0..5] of array[0..2] of single = (
    (-1.76826775, -0.00422996283, 28435.9238),
    (0.322004497, -0.0357099883, 56499.7266),
    (-0.748880744, -0.0562955774, 9237.59082),
    (-1.78385007, -0.0156200649, 14599.5283),
    (-0.0985441282, -0.924688697, 26259.8535),
    (0.317785531, -0.0322612226, 29297.9258)
  );

var
  shader: TShader;
  target: TRenderTexture2D;
  offset: array[0..1] of single;
  zoom: single;
  maxIterations: integer;
  maxIterationsMultiplier: single;
  showControls: boolean;
  zoomLoc, offsetLoc, maxIterationsLoc: integer;
  updateShader: boolean;
  interestIndex: integer;
  mousePos: TVector2;
  offsetVelocity: array[0..1] of single;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [shaders] example - mandelbrot set');

  shader := LoadShader(nil, PChar(TextFormat('resources/shaders/glsl%i/mandelbrot_set.fs', GLSL_VERSION)));
  target := LoadRenderTexture(GetScreenWidth(), GetScreenHeight());

  offset[0] := startingOffset[0];
  offset[1] := startingOffset[1];
  zoom := startingZoom;
  maxIterations := 333;
  maxIterationsMultiplier := 166.5;
  showControls := True;

  zoomLoc := GetShaderLocation(shader, 'zoom');
  offsetLoc := GetShaderLocation(shader, 'offset');
  maxIterationsLoc := GetShaderLocation(shader, 'maxIterations');

  SetShaderValue(shader, zoomLoc, @zoom, SHADER_UNIFORM_FLOAT);
  SetShaderValue(shader, offsetLoc, @offset, SHADER_UNIFORM_VEC2);
  SetShaderValue(shader, maxIterationsLoc, @maxIterations, SHADER_UNIFORM_INT);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    updateShader := False;

    if IsKeyPressed(KEY_ONE) then begin interestIndex := 0; offset[0] := pointsOfInterest[0][0]; offset[1] := pointsOfInterest[0][1]; zoom := pointsOfInterest[0][2]; updateShader := True; end;
    if IsKeyPressed(KEY_TWO) then begin interestIndex := 1; offset[0] := pointsOfInterest[1][0]; offset[1] := pointsOfInterest[1][1]; zoom := pointsOfInterest[1][2]; updateShader := True; end;
    if IsKeyPressed(KEY_THREE) then begin interestIndex := 2; offset[0] := pointsOfInterest[2][0]; offset[1] := pointsOfInterest[2][1]; zoom := pointsOfInterest[2][2]; updateShader := True; end;
    if IsKeyPressed(KEY_FOUR) then begin interestIndex := 3; offset[0] := pointsOfInterest[3][0]; offset[1] := pointsOfInterest[3][1]; zoom := pointsOfInterest[3][2]; updateShader := True; end;
    if IsKeyPressed(KEY_FIVE) then begin interestIndex := 4; offset[0] := pointsOfInterest[4][0]; offset[1] := pointsOfInterest[4][1]; zoom := pointsOfInterest[4][2]; updateShader := True; end;
    if IsKeyPressed(KEY_SIX) then begin interestIndex := 5; offset[0] := pointsOfInterest[5][0]; offset[1] := pointsOfInterest[5][1]; zoom := pointsOfInterest[5][2]; updateShader := True; end;

    if IsKeyPressed(KEY_R) then
    begin
      offset[0] := startingOffset[0];
      offset[1] := startingOffset[1];
      zoom := startingZoom;
      updateShader := True;
    end;

    if IsKeyPressed(KEY_F1) then showControls := not showControls;

    if IsKeyPressed(KEY_UP) then begin maxIterationsMultiplier := maxIterationsMultiplier * 1.4; updateShader := True; end;
    if IsKeyPressed(KEY_DOWN) then begin maxIterationsMultiplier := maxIterationsMultiplier / 1.4; updateShader := True; end;

    if IsMouseButtonDown(MOUSE_BUTTON_LEFT) or IsMouseButtonDown(MOUSE_BUTTON_RIGHT) then
    begin
      if IsMouseButtonDown(MOUSE_BUTTON_LEFT) then
        zoom := zoom * zoomSpeed
      else
        zoom := zoom / zoomSpeed;

      mousePos := GetMousePosition();
      offsetVelocity[0] := (mousePos.x / screenWidth - 0.5) * offsetSpeedMul / zoom;
      offsetVelocity[1] := (mousePos.y / screenHeight - 0.5) * offsetSpeedMul / zoom;

      offset[0] := offset[0] + GetFrameTime() * offsetVelocity[0];
      offset[1] := offset[1] + GetFrameTime() * offsetVelocity[1];

      updateShader := True;
    end;

    if updateShader then
    begin
      maxIterations := Trunc(Sqrt(2.0 * Sqrt(Abs(1.0 - Sqrt(37.5 * zoom)))) * maxIterationsMultiplier);
      SetShaderValue(shader, zoomLoc, @zoom, SHADER_UNIFORM_FLOAT);
      SetShaderValue(shader, offsetLoc, @offset, SHADER_UNIFORM_VEC2);
      SetShaderValue(shader, maxIterationsLoc, @maxIterations, SHADER_UNIFORM_INT);
    end;

    BeginTextureMode(target);
      ClearBackground(BLACK);
      DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK);
    EndTextureMode();

    BeginDrawing();
      ClearBackground(BLACK);

      BeginShaderMode(shader);
        DrawTextureEx(target.texture, Vector2Create(0.0, 0.0), 0.0, 1.0, WHITE);
      EndShaderMode();

      if showControls then
      begin
        DrawText('Press Mouse buttons right/left to zoom in/out and move', 10, 15, 10, RAYWHITE);
        DrawText('Press F1 to toggle these controls', 10, 30, 10, RAYWHITE);
        DrawText('Press [1 - 6] to change point of interest', 10, 45, 10, RAYWHITE);
        DrawText('Press UP | DOWN to change number of iterations', 10, 60, 10, RAYWHITE);
        DrawText('Press R to recenter the camera', 10, 75, 10, RAYWHITE);
      end;
    EndDrawing();
  end;

  UnloadShader(shader);
  UnloadRenderTexture(target);
  CloseWindow();
end.
