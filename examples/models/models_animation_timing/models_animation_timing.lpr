program models_animation_timing;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, raylib, raygui;

const
  screenWidth = 800;
  screenHeight = 450;

var
  camera: TCamera3D;
  model: TModel;
  position: TVector3;
  anims: PModelAnimation;
  animCount: integer;
  animIndex: integer;
  animCurrentFrame: single;
  animFrameSpeed: single;
  animPause: boolean;
  animFrameProgress: single;
  dropdownEditMode: boolean;
  i: integer;
  animNames: array[0..63] of PChar;
  animNamesStr: string;

begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - animation timing');

  camera.position := Vector3Create(6.0, 6.0, 6.0);
  camera.target := Vector3Create(0.0, 2.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  model := LoadModel(PChar(GetApplicationDirectory + 'resources/models/gltf/robot.glb'));
  position := Vector3Create(0.0, 0.0, 0.0);

  animCount := 0;
  anims := LoadModelAnimations(PChar(GetApplicationDirectory + 'resources/models/gltf/robot.glb'), @animCount);

  // Initialize animation names
  for i := 0 to animCount - 1 do
    animNames[i] := anims[i].name;
  animNames[animCount] := nil;

  // Create animation names string for dropdown
  animNamesStr := '';
  for i := 0 to animCount - 1 do
  begin
    if i > 0 then animNamesStr := animNamesStr + ';';
    animNamesStr := animNamesStr + animNames[i];
  end;

  animIndex := 10;
  animCurrentFrame := 0.0;
  animFrameSpeed := 0.5;
  animPause := false;

  animFrameProgress := 0.0;
  dropdownEditMode := false;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    UpdateCamera(@camera, CAMERA_ORBITAL);

    if IsKeyPressed(KEY_P) then animPause := not animPause;

    if (not animPause) and (animIndex < animCount) then
    begin
      animCurrentFrame := animCurrentFrame + animFrameSpeed;
      if animCurrentFrame >= anims[animIndex].keyframeCount then
        animCurrentFrame := 0.0;
      UpdateModelAnimation(model, anims[animIndex], Trunc(animCurrentFrame));
    end;

    animFrameProgress := animCurrentFrame;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawModel(model, position, 1.0, WHITE);
        DrawGrid(10, 1.0);
      EndMode3D();

      // Animation dropdown
      GuiSetStyle(DROPDOWNBOX, DROPDOWN_ITEMS_SPACING, 1);
      if GuiDropdownBox(RectangleCreate(10, 10, 140, 24),
        PChar(animNamesStr), @animIndex, dropdownEditMode) <> 0 then
        dropdownEditMode := not dropdownEditMode;

      // Speed slider
      GuiSlider(RectangleCreate(260, 10, 500, 24), 'FRAME SPEED: ',
        PChar(Format('x%.1f', [animFrameSpeed])), @animFrameSpeed, 0.1, 2.0);

      // Current frame label
      GuiLabel(RectangleCreate(10, GetScreenHeight() - 64, GetScreenWidth() - 20, 24),
        PChar(Format('CURRENT FRAME: %.2f / %d', [
          animFrameProgress,
          anims[animIndex].keyframeCount
        ])));

      // Progress bar
      GuiProgressBar(RectangleCreate(10, GetScreenHeight() - 40, GetScreenWidth() - 20, 24),
        nil, nil, @animFrameProgress, 0.0, anims[animIndex].keyframeCount);

      // Keyframe markers
      for i := 0 to anims[animIndex].keyframeCount - 1 do
        DrawRectangle(
          10 + Trunc(((GetScreenWidth() - 20) / anims[animIndex].keyframeCount) * i),
          GetScreenHeight() - 40,
          1, 24, BLUE);

    EndDrawing();
  end;

  UnloadModelAnimations(anims, animCount);
  UnloadModel(model);
  CloseWindow();
end.
