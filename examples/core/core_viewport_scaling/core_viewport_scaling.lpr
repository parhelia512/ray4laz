program core_viewport_scaling;

{$mode objfpc}{$H+}

uses cmem, sysutils, raylib;

const
  INITIAL_SCREEN_WIDTH = 800;
  INITIAL_SCREEN_HEIGHT = 450;
  RESOLUTION_COUNT = 4;

type
  TViewportType = (
    KEEP_ASPECT_INTEGER,
    KEEP_HEIGHT_INTEGER,
    KEEP_WIDTH_INTEGER,
    KEEP_ASPECT,
    KEEP_HEIGHT,
    KEEP_WIDTH,
    VIEWPORT_TYPE_COUNT
  );

var
  screenWidth, screenHeight: integer;
  resolutionList: array[0..RESOLUTION_COUNT - 1] of TVector2;
  resolutionIndex, gameWidth, gameHeight: integer;
  target: TRenderTexture2D;
  sourceRect, destRect: TRectangle;
  viewportType: integer;
  decreaseResolutionButton, increaseResolutionButton: TRectangle;
  decreaseTypeButton, increaseTypeButton: TRectangle;
  mousePosition: TVector2;
  mousePressed: boolean;
  textureMousePosition: TVector2;
  infoRect: TRectangle;
  scaleRatioX, scaleRatioY: single;

procedure KeepAspectCenteredInteger(sw, sh, gw, gh: integer; var sr, dr: TRectangle);
var
  ratioX, ratioY, resizeRatio: integer;
begin
  sr := RectangleCreate(0, gh, gw, -gh);
  ratioX := sw div gw;
  ratioY := sh div gh;
  if ratioX < ratioY then begin resizeRatio := ratioX; end
  else resizeRatio := ratioY;
  dr := RectangleCreate((sw - gw * resizeRatio) div 2, (sh - gh * resizeRatio) div 2, gw * resizeRatio, gh * resizeRatio);
end;

procedure KeepAspectCentered(sw, sh, gw, gh: integer; var sr, dr: TRectangle);
var
  ratioX, ratioY, resizeRatio: single;
begin
  sr := RectangleCreate(0, gh, gw, -gh);
  ratioX := sw / gw;
  ratioY := sh / gh;
  if ratioX < ratioY then begin resizeRatio := ratioX; end
  else resizeRatio := ratioY;
  dr := RectangleCreate(Trunc((sw - gw * resizeRatio) * 0.5), Trunc((sh - gh * resizeRatio) * 0.5), Trunc(gw * resizeRatio), Trunc(gh * resizeRatio));
end;

procedure ResizeRenderSize(vt: integer; var sw, sh: integer; gw, gh: integer; var sr, dr: TRectangle; var tgt: TRenderTexture2D);
begin
  sw := GetScreenWidth();
  sh := GetScreenHeight();

  case vt of
    0: KeepAspectCenteredInteger(sw, sh, gw, gh, sr, dr);
    3: KeepAspectCentered(sw, sh, gw, gh, sr, dr);
  else
    KeepAspectCenteredInteger(sw, sh, gw, gh, sr, dr);
  end;

  UnloadRenderTexture(tgt);
  tgt := LoadRenderTexture(Trunc(sr.width), -Trunc(sr.height));
end;

function Screen2RenderTexturePosition(point: TVector2; textureRect, scaledRect: TRectangle): TVector2;
var
  relativePosition, ratio: TVector2;
begin
  relativePosition := Vector2Create(point.x - scaledRect.x, point.y - scaledRect.y);
  ratio := Vector2Create(textureRect.width / scaledRect.width, -textureRect.height / scaledRect.height);
  Result := Vector2Create(relativePosition.x * ratio.x, relativePosition.y * ratio.x);
end;

begin
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, 'raylib [core] example - viewport scaling');

  screenWidth := INITIAL_SCREEN_WIDTH;
  screenHeight := INITIAL_SCREEN_HEIGHT;

  resolutionList[0] := Vector2Create(64, 64);
  resolutionList[1] := Vector2Create(256, 240);
  resolutionList[2] := Vector2Create(320, 180);
  resolutionList[3] := Vector2Create(3840, 2160);

  resolutionIndex := 0;
  gameWidth := 64;
  gameHeight := 64;

  target := Default(TRenderTexture2D);
  sourceRect := Default(TRectangle);
  destRect := Default(TRectangle);

  viewportType := 0;
  ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);

  decreaseResolutionButton := RectangleCreate(200, 30, 10, 10);
  increaseResolutionButton := RectangleCreate(215, 30, 10, 10);
  decreaseTypeButton := RectangleCreate(200, 45, 10, 10);
  increaseTypeButton := RectangleCreate(215, 45, 10, 10);

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if IsWindowResized() then
      ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);

    mousePosition := GetMousePosition();
    mousePressed := IsMouseButtonPressed(MOUSE_BUTTON_LEFT);

    if CheckCollisionPointRec(mousePosition, decreaseResolutionButton) and mousePressed then
    begin
      resolutionIndex := (resolutionIndex + RESOLUTION_COUNT - 1) mod RESOLUTION_COUNT;
      gameWidth := Trunc(resolutionList[resolutionIndex].x);
      gameHeight := Trunc(resolutionList[resolutionIndex].y);
      ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);
    end;

    if CheckCollisionPointRec(mousePosition, increaseResolutionButton) and mousePressed then
    begin
      resolutionIndex := (resolutionIndex + 1) mod RESOLUTION_COUNT;
      gameWidth := Trunc(resolutionList[resolutionIndex].x);
      gameHeight := Trunc(resolutionList[resolutionIndex].y);
      ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);
    end;

    if CheckCollisionPointRec(mousePosition, decreaseTypeButton) and mousePressed then
    begin
      viewportType := (viewportType + Ord(VIEWPORT_TYPE_COUNT) - 1) mod Ord(VIEWPORT_TYPE_COUNT);
      ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);
    end;

    if CheckCollisionPointRec(mousePosition, increaseTypeButton) and mousePressed then
    begin
      viewportType := (viewportType + 1) mod Ord(VIEWPORT_TYPE_COUNT);
      ResizeRenderSize(viewportType, screenWidth, screenHeight, gameWidth, gameHeight, sourceRect, destRect, target);
    end;

    textureMousePosition := Screen2RenderTexturePosition(mousePosition, sourceRect, destRect);

    BeginTextureMode(target);
      ClearBackground(WHITE);
      DrawCircleV(textureMousePosition, 20.0, LIME);
    EndTextureMode();

    BeginDrawing();
      ClearBackground(BLACK);

      DrawTexturePro(target.texture, sourceRect, destRect, Vector2Create(0, 0), 0.0, WHITE);

      infoRect := RectangleCreate(5, 5, 330, 105);
      DrawRectangleRec(infoRect, Fade(LIGHTGRAY, 0.7));
      DrawRectangleLinesEx(infoRect, 1, BLUE);

      DrawText(PChar(Format('Window Resolution: %d x %d', [screenWidth, screenHeight])), 15, 15, 10, BLACK);
      DrawText(PChar(Format('Game Resolution: %d x %d', [gameWidth, gameHeight])), 15, 30, 10, BLACK);

      case viewportType of
        0: DrawText('Type: KEEP_ASPECT_INTEGER', 15, 45, 10, BLACK);
        1: DrawText('Type: KEEP_HEIGHT_INTEGER', 15, 45, 10, BLACK);
        2: DrawText('Type: KEEP_WIDTH_INTEGER', 15, 45, 10, BLACK);
        3: DrawText('Type: KEEP_ASPECT', 15, 45, 10, BLACK);
        4: DrawText('Type: KEEP_HEIGHT', 15, 45, 10, BLACK);
        5: DrawText('Type: KEEP_WIDTH', 15, 45, 10, BLACK);
      end;

      scaleRatioX := destRect.width / sourceRect.width;
      scaleRatioY := -destRect.height / sourceRect.height;
      if (scaleRatioX < 0.001) or (scaleRatioY < 0.001) then
        DrawText('Scale ratio: INVALID', 15, 60, 10, BLACK)
      else
        DrawText(PChar(Format('Scale ratio: %.2f x %.2f', [scaleRatioX, scaleRatioY])), 15, 60, 10, BLACK);

      DrawText(PChar(Format('Source size: %.2f x %.2f', [sourceRect.width, -sourceRect.height])), 15, 75, 10, BLACK);
      DrawText(PChar(Format('Destination size: %.2f x %.2f', [destRect.width, destRect.height])), 15, 90, 10, BLACK);

      DrawRectangleRec(decreaseTypeButton, SKYBLUE);
      DrawRectangleRec(increaseTypeButton, SKYBLUE);
      DrawRectangleRec(decreaseResolutionButton, SKYBLUE);
      DrawRectangleRec(increaseResolutionButton, SKYBLUE);
      DrawText('<', Trunc(decreaseTypeButton.x) + 3, Trunc(decreaseTypeButton.y) + 1, 10, BLACK);
      DrawText('>', Trunc(increaseTypeButton.x) + 3, Trunc(increaseTypeButton.y) + 1, 10, BLACK);
      DrawText('<', Trunc(decreaseResolutionButton.x) + 3, Trunc(decreaseResolutionButton.y) + 1, 10, BLACK);
      DrawText('>', Trunc(increaseResolutionButton.x) + 3, Trunc(increaseResolutionButton.y) + 1, 10, BLACK);

    EndDrawing();
  end;

  CloseWindow();
end.
