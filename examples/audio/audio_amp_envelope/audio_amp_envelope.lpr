program audio_amp_envelope;

{$mode objfpc}{$H+}

uses cmem, raylib, raygui, math, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  BUFFER_SIZE = 4096;
  SAMPLE_RATE = 44100;

type
  TADSRState = (IDLE = 0, ATTACK, DECAY, SUSTAIN, RELEASE);

  TEnvelope = record
    attackTime, decayTime, sustainLevel, releaseTime: single;
    currentValue: single;
    state: TADSRState;
  end;

procedure FillAudioBuffer(i: integer; buffer: PSingle; envelopeValue: single; audioTime: PSingle);
begin
  buffer[i] := envelopeValue * Sin(2.0 * PI * 440 * audioTime^);
  audioTime^ := audioTime^ + 1.0 / SAMPLE_RATE;
end;

procedure UpdateEnvelope(var env: TEnvelope);
var
  sampleTime: single;
begin
  sampleTime := 1.0 / SAMPLE_RATE;

  case env.state of
    ATTACK:
    begin
      env.currentValue := env.currentValue + (1.0 / env.attackTime) * sampleTime;
      if env.currentValue >= 1.0 then
      begin
        env.currentValue := 1.0;
        env.state := DECAY;
      end;
    end;
    DECAY:
    begin
      env.currentValue := env.currentValue - ((1.0 - env.sustainLevel) / env.decayTime) * sampleTime;
      if env.currentValue <= env.sustainLevel then
      begin
        env.currentValue := env.sustainLevel;
        env.state := SUSTAIN;
      end;
    end;
    SUSTAIN:
      env.currentValue := env.sustainLevel;
    RELEASE:
    begin
      env.currentValue := env.currentValue - (env.sustainLevel / env.releaseTime) * sampleTime;
      if env.currentValue <= 0.001 then
      begin
        env.currentValue := 0.0;
        env.state := IDLE;
      end;
    end;
  end;
end;

procedure DrawADSRGraph(env: TEnvelope; bounds: TRectangle);
var
  sustainWidth, totalTime, scaleX, scaleY: single;
  start, peak, sustain, rel, endPos: TVector2;
begin
  DrawRectangleRec(bounds, Fade(LIGHTGRAY, 0.3));
  DrawRectangleLinesEx(bounds, 1, GRAY);

  sustainWidth := 1.0;
  totalTime := env.attackTime + env.decayTime + sustainWidth + env.releaseTime;
  scaleX := bounds.width / totalTime;
  scaleY := bounds.height;

  start := Vector2Create(bounds.x, bounds.y + bounds.height);
  peak := Vector2Create(start.x + env.attackTime * scaleX, bounds.y);
  sustain := Vector2Create(peak.x + env.decayTime * scaleX, bounds.y + (1.0 - env.sustainLevel) * scaleY);
  rel := Vector2Create(sustain.x + sustainWidth * scaleX, sustain.y);
  endPos := Vector2Create(rel.x + env.releaseTime * scaleX, bounds.y + bounds.height);

  DrawLineV(start, peak, SKYBLUE);
  DrawLineV(peak, sustain, BLUE);
  DrawLineV(sustain, rel, DARKBLUE);
  DrawLineV(rel, endPos, ORANGE);

  DrawText('ADSR Visualizer', Trunc(bounds.x), Trunc(bounds.y) - 20, 10, DARKGRAY);
end;

var
  stream: TAudioStream;
  buffer: array[0..BUFFER_SIZE - 1] of single;
  audioTime: single;
  env: TEnvelope;
  i: integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [audio] example - amp envelope');

  InitAudioDevice();
  SetAudioStreamBufferSizeDefault(BUFFER_SIZE);

  stream := LoadAudioStream(SAMPLE_RATE, 32, 1);

  audioTime := 0.0;
  env.attackTime := 1.0;
  env.decayTime := 1.0;
  env.sustainLevel := 0.5;
  env.releaseTime := 1.0;
  env.currentValue := 0.0;
  env.state := IDLE;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsKeyPressed(KEY_SPACE) then env.state := ATTACK;
    if IsKeyReleased(KEY_SPACE) and (env.state <> IDLE) then env.state := RELEASE;

    if IsAudioStreamProcessed(stream) then
    begin
      if (env.state <> IDLE) or (env.currentValue > 0.0) then
      begin

        for i := 0 to BUFFER_SIZE - 1 do
        begin
          UpdateEnvelope(env);
          FillAudioBuffer(i, @buffer, env.currentValue, @audioTime);
        end;
      end
      else
      begin
        FillChar(buffer, SizeOf(buffer), 0);
        audioTime := 0.0;
      end;
      UpdateAudioStream(stream, @buffer, BUFFER_SIZE);
    end;

    if not IsAudioStreamPlaying(stream) then PlayAudioStream(stream);

    BeginDrawing();
      ClearBackground(RAYWHITE);

      GuiSliderBar(RectangleCreate(100, 60, 400, 30), 'Attack (s)', PChar(Format('%2.2fs', [env.attackTime])), @env.attackTime, 0.1, 3.0);
      GuiSliderBar(RectangleCreate(100, 100, 400, 30), 'Decay (s)', PChar(Format('%2.2fs', [env.decayTime])), @env.decayTime, 0.1, 3.0);
      GuiSliderBar(RectangleCreate(100, 140, 400, 30), 'Sustain', PChar(Format('%2.2f', [env.sustainLevel])), @env.sustainLevel, 0.0, 1.0);
      GuiSliderBar(RectangleCreate(100, 180, 400, 30), 'Release (s)', PChar(Format('%2.2fs', [env.releaseTime])), @env.releaseTime, 0.1, 3.0);

      DrawADSRGraph(env, RectangleCreate(100, 250, 400, 100));

      DrawCircleV(Vector2Create(520, 350 - env.currentValue * 100), 5, MAROON);
      DrawText(PChar(Format('Current Gain: %2.2f', [env.currentValue])), 535, Trunc(345 - env.currentValue * 100), 10, MAROON);

      DrawText('Press SPACE to PLAY the sound!', 200, 400, 20, LIGHTGRAY);
    EndDrawing();
  end;

  UnloadAudioStream(stream);
  CloseAudioDevice();
  CloseWindow();
end.
