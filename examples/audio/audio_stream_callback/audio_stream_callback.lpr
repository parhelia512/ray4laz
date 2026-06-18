program audio_stream_callback;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  screenWidth = 800;
  screenHeight = 450;
  BUFFER_SIZE = 4096;
  SAMPLE_RATE = 44100;

type
  TWaveType = (SINE = 0, SQUARE, TRIANGLE, SAWTOOTH);

var
  waveFrequency, newWaveFrequency, waveIndex: integer;
  buffer: array[0..SAMPLE_RATE - 1] of single;
  waveTypesAsString: array[0..3] of PChar;

procedure SineCallback(framesOut: Pointer; frameCount: Cardinal); cdecl;
var
  wavelength, i: integer;
  framesOutFloat: PSingle;
begin
  framesOutFloat := PSingle(framesOut);
  wavelength := SAMPLE_RATE div waveFrequency;
  for i := 0 to frameCount - 1 do
  begin
    framesOutFloat[i] := Sin(2 * PI * waveIndex / wavelength);
    Inc(waveIndex);
    if waveIndex >= wavelength then
    begin
      waveFrequency := newWaveFrequency;
      waveIndex := 0;
    end;
  end;
  for i := 0 to SAMPLE_RATE - frameCount - 1 do
    buffer[i] := buffer[i + frameCount];
  for i := 0 to frameCount - 1 do
    buffer[SAMPLE_RATE - frameCount + i] := framesOutFloat[i];
end;

procedure SquareCallback(framesOut: Pointer; frameCount: Cardinal); cdecl;
var
  wavelength, i: integer;
  framesOutFloat: PSingle;
begin
  framesOutFloat := PSingle(framesOut);
  wavelength := SAMPLE_RATE div waveFrequency;
  for i := 0 to frameCount - 1 do
  begin
    if waveIndex < wavelength div 2 then
      framesOutFloat[i] := 1.0
    else
      framesOutFloat[i] := -1.0;
    Inc(waveIndex);
    if waveIndex >= wavelength then
    begin
      waveFrequency := newWaveFrequency;
      waveIndex := 0;
    end;
  end;
  for i := 0 to SAMPLE_RATE - frameCount - 1 do
    buffer[i] := buffer[i + frameCount];
  for i := 0 to frameCount - 1 do
    buffer[SAMPLE_RATE - frameCount + i] := framesOutFloat[i];
end;

procedure TriangleCallback(framesOut: Pointer; frameCount: Cardinal); cdecl;
var
  wavelength, i: integer;
  framesOutFloat: PSingle;
begin
  framesOutFloat := PSingle(framesOut);
  wavelength := SAMPLE_RATE div waveFrequency;
  for i := 0 to frameCount - 1 do
  begin
    if waveIndex < wavelength div 2 then
      framesOutFloat[i] := -1.0 + 2.0 * waveIndex / (wavelength div 2)
    else
      framesOutFloat[i] := 1.0 - 2.0 * (waveIndex - wavelength div 2) / (wavelength div 2);
    Inc(waveIndex);
    if waveIndex >= wavelength then
    begin
      waveFrequency := newWaveFrequency;
      waveIndex := 0;
    end;
  end;
  for i := 0 to SAMPLE_RATE - frameCount - 1 do
    buffer[i] := buffer[i + frameCount];
  for i := 0 to frameCount - 1 do
    buffer[SAMPLE_RATE - frameCount + i] := framesOutFloat[i];
end;

procedure SawtoothCallback(framesOut: Pointer; frameCount: Cardinal); cdecl;
var
  wavelength, i: integer;
  framesOutFloat: PSingle;
begin
  framesOutFloat := PSingle(framesOut);
  wavelength := SAMPLE_RATE div waveFrequency;
  for i := 0 to frameCount - 1 do
  begin
    framesOutFloat[i] := -1.0 + 2.0 * waveIndex / wavelength;
    Inc(waveIndex);
    if waveIndex >= wavelength then
    begin
      waveFrequency := newWaveFrequency;
      waveIndex := 0;
    end;
  end;
  for i := 0 to SAMPLE_RATE - frameCount - 1 do
    buffer[i] := buffer[i + frameCount];
  for i := 0 to frameCount - 1 do
    buffer[SAMPLE_RATE - frameCount + i] := framesOutFloat[i];
end;

var
  stream: TAudioStream;
  waveType: TWaveType;
  i: integer;
  startPos, endPos: TVector2;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [audio] example - stream callback');
  InitAudioDevice();

  SetAudioStreamBufferSizeDefault(BUFFER_SIZE);
  stream := LoadAudioStream(SAMPLE_RATE, 32, 1);
  PlayAudioStream(stream);

  waveType := SINE;
  SetAudioStreamCallback(stream, @SineCallback);

  waveFrequency := 440;
  newWaveFrequency := 440;
  waveIndex := 0;

  waveTypesAsString[0] := 'sine';
  waveTypesAsString[1] := 'square';
  waveTypesAsString[2] := 'triangle';
  waveTypesAsString[3] := 'sawtooth';

  FillChar(buffer, SizeOf(buffer), 0);

  SetTargetFPS(30);

  while not WindowShouldClose() do
  begin
    if IsKeyDown(KEY_UP) then
    begin
      newWaveFrequency := newWaveFrequency + 10;
      if newWaveFrequency > 12500 then newWaveFrequency := 12500;
    end;

    if IsKeyDown(KEY_DOWN) then
    begin
      newWaveFrequency := newWaveFrequency - 10;
      if newWaveFrequency < 20 then newWaveFrequency := 20;
    end;

    if IsKeyPressed(KEY_LEFT) then
    begin
      case waveType of
        SINE: waveType := SAWTOOTH;
        SQUARE: waveType := SINE;
        TRIANGLE: waveType := SQUARE;
        SAWTOOTH: waveType := TRIANGLE;
      end;
      case waveType of
        SINE: SetAudioStreamCallback(stream, @SineCallback);
        SQUARE: SetAudioStreamCallback(stream, @SquareCallback);
        TRIANGLE: SetAudioStreamCallback(stream, @TriangleCallback);
        SAWTOOTH: SetAudioStreamCallback(stream, @SawtoothCallback);
      end;
    end;

    if IsKeyPressed(KEY_RIGHT) then
    begin
      case waveType of
        SINE: waveType := SQUARE;
        SQUARE: waveType := TRIANGLE;
        TRIANGLE: waveType := SAWTOOTH;
        SAWTOOTH: waveType := SINE;
      end;
      case waveType of
        SINE: SetAudioStreamCallback(stream, @SineCallback);
        SQUARE: SetAudioStreamCallback(stream, @SquareCallback);
        TRIANGLE: SetAudioStreamCallback(stream, @TriangleCallback);
        SAWTOOTH: SetAudioStreamCallback(stream, @SawtoothCallback);
      end;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);
      DrawText(PChar(Format('frequency: %i', [newWaveFrequency])), screenWidth - 220, 10, 20, RED);
      DrawText(PChar(Format('wave type: %s', [waveTypesAsString[Integer(waveType)]])), screenWidth - 220, 30, 20, RED);
      DrawText('Up/down to change frequency', 10, 10, 20, DARKGRAY);
      DrawText('Left/right to change wave type', 10, 30, 20, DARKGRAY);

      for i := 0 to screenWidth - 1 do
      begin
        startPos := Vector2Create(i, 250 - 50 * buffer[SAMPLE_RATE - SAMPLE_RATE div 100 + i * SAMPLE_RATE div 100 div screenWidth]);
        endPos := Vector2Create(i + 1, 250 - 50 * buffer[SAMPLE_RATE - SAMPLE_RATE div 100 + (i + 1) * SAMPLE_RATE div 100 div screenWidth]);
        DrawLineV(startPos, endPos, RED);
      end;

    EndDrawing();
  end;

  UnloadAudioStream(stream);
  CloseAudioDevice();
  CloseWindow();
end.
