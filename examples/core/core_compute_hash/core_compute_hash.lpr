program core_compute_hash;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, raygui;

const
  screenWidth = 800;
  screenHeight = 450;

// Get data as hex text (converts unsigned int array to hex string)
function GetDataAsHexText(data: PCardinal; dataSize: integer): PChar;
var
  i: integer;
  hexText: string;
begin
  hexText := '';

  if (data <> nil) and (dataSize > 0) and (dataSize < 15) then
  begin
    for i := 0 to dataSize - 1 do
      hexText := hexText + UpperCase(Format('%.8x', [data[i]]));
  end
  else
    hexText := '00000000';

  // Return a PChar that will be valid until next call
  // Using static buffer for simplicity
  Result := PChar(hexText);
end;

var
  textInput: array[0..95] of AnsiChar;
  textBoxEditMode: boolean;
  btnComputeHashes: boolean;
  hashCRC32: cardinal;
  hashMD5, hashSHA1, hashSHA256: PCardinal;
  base64Text: PChar;
  base64TextSize: integer;
  textInputLen: integer;
  i: integer;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - compute hash');

  // Initialize text input
  StrPCopy(textInput, 'The quick brown fox jumps over the lazy dog.');
  textBoxEditMode := False;
  btnComputeHashes := False;

  hashCRC32 := 0;
  hashMD5 := nil;
  hashSHA1 := nil;
  hashSHA256 := nil;
  base64Text := nil;
  base64TextSize := 0;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    if btnComputeHashes then
    begin
      textInputLen := TextLength(textInput);

      // Free previous base64 text if exists
      if base64Text <> nil then
        MemFree(base64Text);

      // Encode data to Base64 string
      base64Text := EncodeDataBase64(@textInput, textInputLen, @base64TextSize);

      // Compute hashes
      hashCRC32 := ComputeCRC32(@textInput, textInputLen);
      hashMD5 := ComputeMD5(@textInput, textInputLen);
      hashSHA1 := ComputeSHA1(@textInput, textInputLen);
      hashSHA256 := ComputeSHA256(@textInput, textInputLen);

      btnComputeHashes := False;
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
      GuiSetStyle(DEFAULT, TEXT_SPACING, 2);
      GuiLabel(RectangleCreate(40, 26, 720, 32), 'INPUT DATA (TEXT):');
      GuiSetStyle(DEFAULT, TEXT_SPACING, 1);
      GuiSetStyle(DEFAULT, TEXT_SIZE, 10);

      if GuiTextBox(RectangleCreate(40, 64, 720, 32), textInput, 95, textBoxEditMode) <> 0 then
        textBoxEditMode := not textBoxEditMode;

      if GuiButton(RectangleCreate(40, 104, 720, 32), 'COMPUTE INPUT DATA HASHES') <> 0 then
        btnComputeHashes := True;

      GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
      GuiSetStyle(DEFAULT, TEXT_SPACING, 2);
      GuiLabel(RectangleCreate(40, 160, 720, 32), 'INPUT DATA HASH VALUES:');
      GuiSetStyle(DEFAULT, TEXT_SPACING, 1);
      GuiSetStyle(DEFAULT, TEXT_SIZE, 10);

      GuiSetStyle(TEXTBOX, TEXT_READONLY, 1);

      // CRC32
      GuiLabel(RectangleCreate(40, 200, 120, 32), 'CRC32 [32 bit]:');
      GuiTextBox(RectangleCreate(160, 200, 600, 32), GetDataAsHexText(@hashCRC32, 1), 120, False);

      // MD5
      GuiLabel(RectangleCreate(40, 236, 120, 32), 'MD5 [128 bit]:');
      GuiTextBox(RectangleCreate(160, 236, 600, 32), GetDataAsHexText(hashMD5, 4), 120, False);

      // SHA1
      GuiLabel(RectangleCreate(40, 272, 120, 32), 'SHA1 [160 bit]:');
      GuiTextBox(RectangleCreate(160, 272, 600, 32), GetDataAsHexText(hashSHA1, 5), 120, False);

      // SHA256
      GuiLabel(RectangleCreate(40, 308, 120, 32), 'SHA256 [256 bit]:');
      GuiTextBox(RectangleCreate(160, 308, 600, 32), GetDataAsHexText(hashSHA256, 8), 120, False);

      // Base64
      GuiSetState(STATE_FOCUSED);
      GuiLabel(RectangleCreate(40, 356, 320, 32), 'BONUS - BASE64 ENCODED STRING:');
      GuiSetState(STATE_NORMAL);
      GuiLabel(RectangleCreate(40, 386, 120, 32), 'BASE64 ENCODING:');
      if base64Text <> nil then
        GuiTextBox(RectangleCreate(160, 386, 600, 32), base64Text, 120, False);

      GuiSetStyle(TEXTBOX, TEXT_READONLY, 0);

    EndDrawing();
  end;

  // De-Initialization
  if base64Text <> nil then
    MemFree(base64Text);

  CloseWindow();
end.
