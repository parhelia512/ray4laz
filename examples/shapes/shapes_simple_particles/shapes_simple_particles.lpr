program shapes_simple_particles;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_PARTICLES = 3000;

type
  TParticleType = (WATER = 0, SMOKE, FIRE);

  TParticle = record
    particleType: TParticleType;
    position: TVector2;
    velocity: TVector2;
    radius: single;
    color: TColorB;
    lifeTime: single;
    alive: boolean;
  end;

  TCircularBuffer = record
    head: integer;
    tail: integer;
    buffer: array[0..MAX_PARTICLES - 1] of TParticle;
  end;

var
  circularBuffer: TCircularBuffer;
  emissionRate: integer;
  currentType: TParticleType;
  emitterPosition: TVector2;
  j, i: integer;

procedure EmitParticle(emitterPos: TVector2; pType: TParticleType);
var
  speed: single;
  direction: single;
begin
  // Check if buffer full
  if ((circularBuffer.head + 1) mod MAX_PARTICLES) = circularBuffer.tail then
    Exit;

  circularBuffer.buffer[circularBuffer.head].position := emitterPos;
  circularBuffer.buffer[circularBuffer.head].alive := True;
  circularBuffer.buffer[circularBuffer.head].lifeTime := 0.0;
  circularBuffer.buffer[circularBuffer.head].particleType := pType;

  speed := (Random(10)) / 5.0;
  case pType of
    WATER:
    begin
      circularBuffer.buffer[circularBuffer.head].radius := 5.0;
      circularBuffer.buffer[circularBuffer.head].color := BLUE;
    end;
    SMOKE:
    begin
      circularBuffer.buffer[circularBuffer.head].radius := 7.0;
      circularBuffer.buffer[circularBuffer.head].color := GRAY;
      circularBuffer.buffer[circularBuffer.head].color.a := 200;
    end;
    FIRE:
    begin
      circularBuffer.buffer[circularBuffer.head].radius := 10.0;
      circularBuffer.buffer[circularBuffer.head].color := YELLOW;
      speed := speed / 10.0;
    end;
  end;

  direction := Random(360);
  circularBuffer.buffer[circularBuffer.head].velocity := Vector2Create(
    speed * Cos(direction * DEG2RAD),
    speed * Sin(direction * DEG2RAD)
  );

  circularBuffer.head := (circularBuffer.head + 1) mod MAX_PARTICLES;
end;

procedure UpdateParticles;
var
  i: integer;
begin
  i := circularBuffer.tail;
  while i <> circularBuffer.head do
  begin
    circularBuffer.buffer[i].lifeTime := circularBuffer.buffer[i].lifeTime + 1.0 / 60.0;

    case circularBuffer.buffer[i].particleType of
      WATER:
      begin
        circularBuffer.buffer[i].position.x := circularBuffer.buffer[i].position.x + circularBuffer.buffer[i].velocity.x;
        circularBuffer.buffer[i].velocity.y := circularBuffer.buffer[i].velocity.y + 0.2;
        circularBuffer.buffer[i].position.y := circularBuffer.buffer[i].position.y + circularBuffer.buffer[i].velocity.y;
      end;
      SMOKE:
      begin
        circularBuffer.buffer[i].position.x := circularBuffer.buffer[i].position.x + circularBuffer.buffer[i].velocity.x;
        circularBuffer.buffer[i].velocity.y := circularBuffer.buffer[i].velocity.y - 0.05;
        circularBuffer.buffer[i].position.y := circularBuffer.buffer[i].position.y + circularBuffer.buffer[i].velocity.y;
        circularBuffer.buffer[i].radius := circularBuffer.buffer[i].radius + 0.5;
        if circularBuffer.buffer[i].color.a >= 4 then
          circularBuffer.buffer[i].color.a := circularBuffer.buffer[i].color.a - 4
        else
          circularBuffer.buffer[i].alive := False;
      end;
      FIRE:
      begin
        circularBuffer.buffer[i].position.x := circularBuffer.buffer[i].position.x +
          circularBuffer.buffer[i].velocity.x + Cos(circularBuffer.buffer[i].lifeTime * 215.0);
        circularBuffer.buffer[i].velocity.y := circularBuffer.buffer[i].velocity.y - 0.05;
        circularBuffer.buffer[i].position.y := circularBuffer.buffer[i].position.y + circularBuffer.buffer[i].velocity.y;
        circularBuffer.buffer[i].radius := circularBuffer.buffer[i].radius - 0.15;
        if circularBuffer.buffer[i].color.g >= 3 then
          circularBuffer.buffer[i].color.g := circularBuffer.buffer[i].color.g - 3
        else
          circularBuffer.buffer[i].alive := False;
        if circularBuffer.buffer[i].radius <= 0.02 then
          circularBuffer.buffer[i].alive := False;
      end;
    end;

    // Disable particle when out of screen
    if (circularBuffer.buffer[i].position.x < -circularBuffer.buffer[i].radius) or
       (circularBuffer.buffer[i].position.x > (screenWidth + circularBuffer.buffer[i].radius)) or
       (circularBuffer.buffer[i].position.y < -circularBuffer.buffer[i].radius) or
       (circularBuffer.buffer[i].position.y > (screenHeight + circularBuffer.buffer[i].radius)) then
    begin
      circularBuffer.buffer[i].alive := False;
    end;

    i := (i + 1) mod MAX_PARTICLES;
  end;
end;

procedure UpdateCircularBuffer;
begin
  while (circularBuffer.tail <> circularBuffer.head) and (not circularBuffer.buffer[circularBuffer.tail].alive) do
  begin
    circularBuffer.tail := (circularBuffer.tail + 1) mod MAX_PARTICLES;
  end;
end;

procedure DrawParticles;
var
  i: integer;
begin
  i := circularBuffer.tail;
  while i <> circularBuffer.head do
  begin
    if circularBuffer.buffer[i].alive then
    begin
      DrawCircleV(circularBuffer.buffer[i].position,
                  circularBuffer.buffer[i].radius,
                  circularBuffer.buffer[i].color);
    end;
    i := (i + 1) mod MAX_PARTICLES;
  end;
end;

const
  particleTypeNames: array[0..2] of string = ('WATER', 'SMOKE', 'FIRE');

begin
  Randomize; // Initialize random number generator
  InitWindow(screenWidth, screenHeight, 'raylib [shapes] example - simple particles');

  circularBuffer.head := 0;
  circularBuffer.tail := 0;

  emissionRate := -2;
  currentType := WATER;
  emitterPosition := Vector2Create(screenWidth / 2.0, screenHeight / 2.0);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Emit new particles
    if emissionRate < 0 then
    begin
      if Random(-emissionRate) = 0 then
        EmitParticle(emitterPosition, currentType);
    end
    else
    begin
      for i := 0 to emissionRate do
        EmitParticle(emitterPosition, currentType);
    end;

    UpdateParticles;
    UpdateCircularBuffer;

    if IsKeyPressed(KEY_UP) then Inc(emissionRate);
    if IsKeyPressed(KEY_DOWN) then Dec(emissionRate);

    if IsKeyPressed(KEY_RIGHT) then
    begin
      if currentType = FIRE then currentType := WATER
      else currentType := Succ(currentType);
    end;
    if IsKeyPressed(KEY_LEFT) then
    begin
      if currentType = WATER then currentType := FIRE
      else currentType := Pred(currentType);
    end;

    if IsMouseButtonDown(MOUSE_LEFT_BUTTON) then
      emitterPosition := GetMousePosition();

    BeginDrawing();
      ClearBackground(RAYWHITE);

      DrawParticles;

      DrawRectangle(5, 5, 315, 75, Fade(SKYBLUE, 0.5));
      DrawRectangleLines(5, 5, 315, 75, BLUE);

      DrawText('CONTROLS:', 15, 15, 10, BLACK);
      DrawText('UP/DOWN: Change Particle Emission Rate', 15, 35, 10, BLACK);
      DrawText('LEFT/RIGHT: Change Particle Type (Water, Smoke, Fire)', 15, 55, 10, BLACK);

      if emissionRate < 0 then
        DrawText(PChar(Format('Particles every %d frames | Type: %s', [-emissionRate, particleTypeNames[Integer(currentType)]])), 15, 95, 10, DARKGRAY)
      else
        DrawText(PChar(Format('%d Particles per frame | Type: %s', [emissionRate + 1, particleTypeNames[Integer(currentType)]])), 15, 95, 10, DARKGRAY);

      DrawFPS(screenWidth - 80, 10);

    EndDrawing();
  end;

  CloseWindow();
end.
