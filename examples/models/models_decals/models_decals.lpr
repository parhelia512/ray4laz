program models_decals;

{$mode objfpc}{$H+}

uses
  cmem, sysutils, math, raylib, raymath;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_DECALS = 256;

type
  PMeshBuilder = ^TMeshBuilder;
  TMeshBuilder = record
    vertexCount: integer;
    vertexCapacity: integer;
    vertices: array of TVector3;
    uvs: array of TVector2;
  end;

var
  meshBuilders: array[0..1] of TMeshBuilder;

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

// Initialize mesh builder
procedure InitMeshBuilder(mb: PMeshBuilder);
begin
  mb^.vertexCount := 0;
  mb^.vertexCapacity := 0;
  SetLength(mb^.vertices, 0);
  SetLength(mb^.uvs, 0);
end;

// Free mesh builder
procedure FreeMeshBuilder(mb: PMeshBuilder);
begin
  SetLength(mb^.vertices, 0);
  SetLength(mb^.uvs, 0);
  mb^.vertexCount := 0;
  mb^.vertexCapacity := 0;
end;

// Add triangle to mesh builder (dynamic array manager)
procedure AddTriangleToMeshBuilder(mb: PMeshBuilder; const vertices: array of TVector3);
var
  i: integer;
  newVertexCapacity: integer;
begin
  // Reallocate and copy if we need to
  if mb^.vertexCapacity <= (mb^.vertexCount + 3) then
  begin
    newVertexCapacity := ((mb^.vertexCapacity div 256) + 1) * 256;
    if newVertexCapacity < 256 then newVertexCapacity := 256;
    SetLength(mb^.vertices, newVertexCapacity);
    mb^.vertexCapacity := newVertexCapacity;
  end;

  // Add 3 vertices
  for i := 0 to 2 do
    mb^.vertices[mb^.vertexCount + i] := vertices[i];

  mb^.vertexCount := mb^.vertexCount + 3;
end;

// Build a Mesh from MeshBuilder data
function BuildMesh(mb: PMeshBuilder): TMesh;
var
  outMesh: TMesh;
  i: integer;
begin
  FillChar(outMesh, SizeOf(outMesh), 0);

  if mb^.vertexCount = 0 then
  begin
    Result := outMesh;
    Exit;
  end;

  outMesh.vertexCount := mb^.vertexCount;
  outMesh.triangleCount := mb^.vertexCount div 3;

  outMesh.vertices := MemAlloc(outMesh.vertexCount * 3 * SizeOf(single));
  if Length(mb^.uvs) > 0 then
    outMesh.texcoords := MemAlloc(outMesh.vertexCount * 2 * SizeOf(single));

  for i := 0 to mb^.vertexCount - 1 do
  begin
    outMesh.vertices[3*i + 0] := mb^.vertices[i].x;
    outMesh.vertices[3*i + 1] := mb^.vertices[i].y;
    outMesh.vertices[3*i + 2] := mb^.vertices[i].z;

    if Length(mb^.uvs) > 0 then
    begin
      outMesh.texcoords[2*i + 0] := mb^.uvs[i].x;
      outMesh.texcoords[2*i + 1] := mb^.uvs[i].y;
    end;
  end;

  UploadMesh(@outMesh, false);
  Result := outMesh;
end;

// Clip segment against plane
function ClipSegment(v0, v1, p: TVector3; s: single): TVector3;
var
  d0, d1, s0: single;
begin
  d0 := Vector3DotProduct(v0, p) - s;
  d1 := Vector3DotProduct(v1, p) - s;

  if Abs(d0 - d1) < 0.0001 then
  begin
    Result := Vector3Lerp(v0, v1, 0.5);
    Exit;
  end;

  s0 := d0 / (d0 - d1);
  Result := Vector3Lerp(v0, v1, s0);
end;

// Generate mesh decals for provided model
function GenMeshDecal(target: TModel; projection: TMatrix; decalSize, decalOffset: single): TMesh;
var
  invProj: TMatrix;
  mbIndex: integer;
  meshIndex, tri, v, i: integer;
  mesh: TMesh;
  vertices: array[0..2] of TVector3;
  insideCount: integer;
  vTrans: TVector3;
  planes: array[0..5] of TVector3;
  face: integer;
  inMesh, outMesh: PMeshBuilder;
  s: single;
  nV1, nV2, nV3, nV4: TVector3;
  d1, d2, d3: single;
  v1Out, v2Out, v3Out, total: integer;
  theMesh: PMeshBuilder;
begin
  // Check if we need to free static data
  if target.meshCount = -1 then
  begin
    FreeMeshBuilder(@meshBuilders[0]);
    FreeMeshBuilder(@meshBuilders[1]);
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;

  invProj := MatrixInvert(projection);

  // Reset mesh builders
  meshBuilders[0].vertexCount := 0;
  meshBuilders[1].vertexCount := 0;

  mbIndex := 0;

  // First pass: collect triangles inside bounding box
  for meshIndex := 0 to target.meshCount - 1 do
  begin
    mesh := target.meshes[meshIndex];

    for tri := 0 to mesh.triangleCount - 1 do
    begin
      // Get triangle vertices
      if mesh.indices = nil then
      begin
        for v := 0 to 2 do
        begin
          vertices[v].x := mesh.vertices[9*tri + 3*v + 0];
          vertices[v].y := mesh.vertices[9*tri + 3*v + 1];
          vertices[v].z := mesh.vertices[9*tri + 3*v + 2];
        end;
      end
      else
      begin
        for v := 0 to 2 do
        begin
          vertices[v].x := mesh.vertices[3*mesh.indices[3*tri + v] + 0];
          vertices[v].y := mesh.vertices[3*mesh.indices[3*tri + v] + 1];
          vertices[v].z := mesh.vertices[3*mesh.indices[3*tri + v] + 2];
        end;
      end;

      // Transform vertices and check if inside decal box
      insideCount := 0;
      for i := 0 to 2 do
      begin
        vTrans := Vector3Transform(vertices[i], projection);
        if (Abs(vTrans.x) < decalSize) or (Abs(vTrans.y) <= decalSize) or (Abs(vTrans.z) <= decalSize) then
          Inc(insideCount);
        vertices[i] := vTrans;
      end;

      if insideCount > 0 then
        AddTriangleToMeshBuilder(@meshBuilders[mbIndex], vertices);
    end;
  end;

  // Clipping planes
  planes[0] := Vector3Create(1, 0, 0);
  planes[1] := Vector3Create(-1, 0, 0);
  planes[2] := Vector3Create(0, 1, 0);
  planes[3] := Vector3Create(0, -1, 0);
  planes[4] := Vector3Create(0, 0, 1);
  planes[5] := Vector3Create(0, 0, -1);

  // Clip against all 6 planes
  for face := 0 to 5 do
  begin
    mbIndex := 1 - mbIndex;
    inMesh := @meshBuilders[1 - mbIndex];
    outMesh := @meshBuilders[mbIndex];
    outMesh^.vertexCount := 0;
    s := 0.5 * decalSize;

    i := 0;
    while i < inMesh^.vertexCount do
    begin
      d1 := Vector3DotProduct(inMesh^.vertices[i + 0], planes[face]) - s;
      d2 := Vector3DotProduct(inMesh^.vertices[i + 1], planes[face]) - s;
      d3 := Vector3DotProduct(inMesh^.vertices[i + 2], planes[face]) - s;

      v1Out := 0;
      v2Out := 0;
      v3Out := 0;
      if d1 > 0 then v1Out := 1;
      if d2 > 0 then v2Out := 1;
      if d3 > 0 then v3Out := 1;
      total := v1Out + v2Out + v3Out;

      case total of
        0: // All inside
        begin
          AddTriangleToMeshBuilder(outMesh,
            [inMesh^.vertices[i], inMesh^.vertices[i+1], inMesh^.vertices[i+2]]);
        end;
        1: // One vertex outside
        begin
          if v1Out = 1 then
          begin
            nV1 := inMesh^.vertices[i + 1];
            nV2 := inMesh^.vertices[i + 2];
            nV3 := ClipSegment(inMesh^.vertices[i], nV1, planes[face], s);
            nV4 := ClipSegment(inMesh^.vertices[i], nV2, planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV1, nV2, nV3]);
            AddTriangleToMeshBuilder(outMesh, [nV4, nV3, nV2]);
          end
          else if v2Out = 1 then
          begin
            nV1 := inMesh^.vertices[i];
            nV2 := inMesh^.vertices[i + 2];
            nV3 := ClipSegment(inMesh^.vertices[i + 1], nV1, planes[face], s);
            nV4 := ClipSegment(inMesh^.vertices[i + 1], nV2, planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV3, nV2, nV1]);
            AddTriangleToMeshBuilder(outMesh, [nV2, nV3, nV4]);
          end
          else if v3Out = 1 then
          begin
            nV1 := inMesh^.vertices[i];
            nV2 := inMesh^.vertices[i + 1];
            nV3 := ClipSegment(inMesh^.vertices[i + 2], nV1, planes[face], s);
            nV4 := ClipSegment(inMesh^.vertices[i + 2], nV2, planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV1, nV2, nV3]);
            AddTriangleToMeshBuilder(outMesh, [nV4, nV3, nV2]);
          end;
        end;
        2: // Two vertices outside
        begin
          if v1Out = 0 then
          begin
            nV1 := inMesh^.vertices[i];
            nV2 := ClipSegment(nV1, inMesh^.vertices[i + 1], planes[face], s);
            nV3 := ClipSegment(nV1, inMesh^.vertices[i + 2], planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV1, nV2, nV3]);
          end;
          if v2Out = 0 then
          begin
            nV1 := inMesh^.vertices[i + 1];
            nV2 := ClipSegment(nV1, inMesh^.vertices[i + 2], planes[face], s);
            nV3 := ClipSegment(nV1, inMesh^.vertices[i], planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV1, nV2, nV3]);
          end;
          if v3Out = 0 then
          begin
            nV1 := inMesh^.vertices[i + 2];
            nV2 := ClipSegment(nV1, inMesh^.vertices[i], planes[face], s);
            nV3 := ClipSegment(nV1, inMesh^.vertices[i + 1], planes[face], s);
            AddTriangleToMeshBuilder(outMesh, [nV1, nV2, nV3]);
          end;
        end;
        // 3: All outside - discard
      end;

      Inc(i, 3);
    end;
  end;

  theMesh := @meshBuilders[mbIndex];

  if theMesh^.vertexCount > 0 then
  begin
    SetLength(theMesh^.uvs, theMesh^.vertexCount);

    for i := 0 to theMesh^.vertexCount - 1 do
    begin
      theMesh^.uvs[i].x := (theMesh^.vertices[i].x / decalSize + 0.5);
      theMesh^.uvs[i].y := (theMesh^.vertices[i].y / decalSize + 0.5);
      theMesh^.vertices[i].z := theMesh^.vertices[i].z - decalOffset;
      theMesh^.vertices[i] := Vector3Transform(theMesh^.vertices[i], invProj);
    end;

    Result := BuildMesh(theMesh);
  end
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

// Free decal mesh data (static)
procedure FreeDecalMeshData;
begin
  // Убираем хак с фиктивной моделью и вызываем очистку напрямую
  FreeMeshBuilder(@meshBuilders[0]);
  FreeMeshBuilder(@meshBuilders[1]);
end;

// Button UI element
function GuiButtonCustom(rec: TRectangle; labelStr: PChar): boolean;
var
  bgColor: TColorB;
  pressed: boolean;
  fontSize: integer;
  textWidth: integer;
begin
  bgColor := GRAY;
  pressed := false;

  if CheckCollisionPointRec(GetMousePosition(), rec) then
  begin
    bgColor := LIGHTGRAY;
    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then pressed := true;
  end;

  DrawRectangleRec(rec, bgColor);
  DrawRectangleLinesEx(rec, 2.0, DARKGRAY);

  fontSize := 10;
  textWidth := MeasureText(labelStr, fontSize);
  DrawText(labelStr,
    Trunc(rec.x + rec.width * 0.5 - textWidth * 0.5),
    Trunc(rec.y + rec.height * 0.5 - fontSize * 0.5),
    fontSize, DARKGRAY);

  Result := pressed;
end;

var
  camera: TCamera3D;
  model: TModel;
  modelTexture: TTexture2D;
  modelBBox: TBoundingBox;
  modelSize: single;
  decalSize: single;
  decalOffset: single;
  placementCube: TModel;
  decalMaterial: TMaterial;
  decalImage: TImage;
  decalTexture: TTexture2D;
  showModel: boolean;
  decalModels: array[0..MAX_DECALS-1] of TModel;
  decalCount: integer;
  collision: TRayCollision;
  ray: TRay;
  boxHitInfo: TRayCollision;
  meshHitInfo: TRayCollision;
  m: integer;
  origin: TVector3;
  splat: TMatrix;
  decalMesh: TMesh;
  decalIndex: integer;
  yPos, x0, x1, x2: single;
  vertexCount, triangleCount, i: integer;
  resourcePath: string;

begin
  // Initialization
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - decals');

  // Get resource path
  resourcePath := GetApplicationDirectory();

  // Camera setup
  camera.position := Vector3Create(5.0, 5.0, 5.0);
  camera.target := Vector3Create(0.0, 1.0, 0.0);
  camera.up := Vector3Create(0.0, 1.6, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  // Load character model
  model := LoadModel(PChar(resourcePath + 'resources/models/obj/character.obj'));

  // Load texture
  modelTexture := LoadTexture(PChar(resourcePath + 'resources/models/obj/character_diffuse.png'));
  SetTextureFilter(modelTexture, TEXTURE_FILTER_BILINEAR);
  model.materials[0].maps[MATERIAL_MAP_ALBEDO].texture := modelTexture;

  // Get bounding box
  modelBBox := GetMeshBoundingBox(model.meshes[0]);

  // Setup camera
  camera.target := Vector3Lerp(modelBBox.min, modelBBox.max, 0.5);
  camera.position := Vector3Scale(modelBBox.max, 1.0);
  camera.position.x := camera.position.x * 0.1;

  modelSize := Min(
    Min(Abs(modelBBox.max.x - modelBBox.min.x), Abs(modelBBox.max.y - modelBBox.min.y)),
    Abs(modelBBox.max.z - modelBBox.min.z));

  camera.position := Vector3Create(0.0, modelBBox.max.y * 1.2, modelSize * 3.0);

  // Decal settings
  decalSize := modelSize * 0.25;
  decalOffset := 0.01;

  // Placement cube
  placementCube := LoadModelFromMesh(GenMeshCube(decalSize, decalSize, decalSize));
  placementCube.materials[0].maps[0].color := LIME;

  // Decal material
  decalMaterial := LoadMaterialDefault();
  decalMaterial.maps[0].color := YELLOW;

  // Load decal texture
  decalImage := LoadImage(PChar(resourcePath + 'resources/raylib_logo.png'));
  ImageResizeNN(@decalImage, decalImage.width div 4, decalImage.height div 4);
  decalTexture := LoadTextureFromImage(decalImage);
  UnloadImage(decalImage);

  SetTextureFilter(decalTexture, TEXTURE_FILTER_BILINEAR);
  decalMaterial.maps[MATERIAL_MAP_ALBEDO].texture := decalTexture;
  decalMaterial.maps[MATERIAL_MAP_ALBEDO].color := RAYWHITE;

  showModel := true;
  decalCount := 0;

  // Initialize mesh builders
  InitMeshBuilder(@meshBuilders[0]);
  InitMeshBuilder(@meshBuilders[1]);

  SetTargetFPS(60);

  // Main game loop
  while not WindowShouldClose() do
  begin
    // Update
    if IsMouseButtonDown(MOUSE_BUTTON_RIGHT) then
      UpdateCamera(@camera, CAMERA_THIRD_PERSON);

    // Reset collision
    collision.distance := 340282346638528859811704183484516925440.0;
    collision.hit := false;

    // Get mouse ray
    ray := GetScreenToWorldRay(GetMousePosition(), camera);
    boxHitInfo := GetRayCollisionBox(ray, modelBBox);

    if boxHitInfo.hit and (decalCount < MAX_DECALS) then
    begin
      meshHitInfo.hit := false;
      for m := 0 to model.meshCount - 1 do
      begin
        meshHitInfo := GetRayCollisionMesh(ray, model.meshes[m], model.transform);
        if meshHitInfo.hit then
        begin
          if (not collision.hit) or (collision.distance > meshHitInfo.distance) then
            collision := meshHitInfo;
        end;
      end;
    end;

    // Add decal on click
    if collision.hit and IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and (decalCount < MAX_DECALS) then
    begin
      origin := Vector3Add(collision.point, Vector3Scale(collision.normal, 1.0));
      splat := MatrixLookAt(collision.point, origin, Vector3Create(0.0, 1.0, 0.0));
      splat := MatrixMultiply(splat, MatrixRotateZ(DEG2RAD * GetRandomValue(-180, 180)));

      decalMesh := GenMeshDecal(model, splat, decalSize, decalOffset);

      if decalMesh.vertexCount > 0 then
      begin
        decalIndex := decalCount;
        Inc(decalCount);
        decalModels[decalIndex] := LoadModelFromMesh(decalMesh);
        decalModels[decalIndex].materials[0].maps[0] := decalMaterial.maps[0];
      end;
    end;

    // Draw
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        // Draw main model
        if showModel then
          DrawModel(model, Vector3Create(0.0, 0.0, 0.0), 1.0, WHITE);

        // Draw decals
        for i := 0 to decalCount - 1 do
          DrawModel(decalModels[i], Vector3Create(0, 0, 0), 1.0, WHITE);

        // Draw placement preview
        if collision.hit then
        begin
          origin := Vector3Add(collision.point, Vector3Scale(collision.normal, 1.0));
          splat := MatrixLookAt(collision.point, origin, Vector3Create(0, 1, 0));
          placementCube.transform := MatrixInvert(splat);
          DrawModel(placementCube, Vector3Create(0, 0, 0), 1.0, Fade(WHITE, 0.5));
        end;

        DrawGrid(10, 10.0);
      EndMode3D();

      // Statistics UI
      yPos := 10;
      x0 := GetScreenWidth() - 300.0;
      x1 := x0 + 100;
      x2 := x1 + 100;

      DrawText('Vertices', Trunc(x1), Trunc(yPos), 10, LIME);
      DrawText('Triangles', Trunc(x2), Trunc(yPos), 10, LIME);
      yPos := yPos + 15;

      vertexCount := 0;
      triangleCount := 0;
      for i := 0 to model.meshCount - 1 do
      begin
        vertexCount := vertexCount + model.meshes[i].vertexCount;
        triangleCount := triangleCount + model.meshes[i].triangleCount;
      end;

      DrawText('Main model', Trunc(x0), Trunc(yPos), 10, LIME);
      DrawText(PChar(IntToStr(vertexCount)), Trunc(x1), Trunc(yPos), 10, LIME);
      DrawText(PChar(IntToStr(triangleCount)), Trunc(x2), Trunc(yPos), 10, LIME);
      yPos := yPos + 15;

      for i := 0 to decalCount - 1 do
      begin
        if i = 20 then
        begin
          DrawText('...', Trunc(x0), Trunc(yPos), 10, LIME);
          yPos := yPos + 15;
        end;

        if i < 20 then
        begin
          DrawText(PChar(Format('Decal #%d', [i+1])), Trunc(x0), Trunc(yPos), 10, LIME);
          DrawText(PChar(IntToStr(decalModels[i].meshes[0].vertexCount)), Trunc(x1), Trunc(yPos), 10, LIME);
          DrawText(PChar(IntToStr(decalModels[i].meshes[0].triangleCount)), Trunc(x2), Trunc(yPos), 10, LIME);
          yPos := yPos + 15;
        end;

        vertexCount := vertexCount + decalModels[i].meshes[0].vertexCount;
        triangleCount := triangleCount + decalModels[i].meshes[0].triangleCount;
      end;

      DrawText('TOTAL', Trunc(x0), Trunc(yPos), 10, LIME);
      DrawText(PChar(IntToStr(vertexCount)), Trunc(x1), Trunc(yPos), 10, LIME);
      DrawText(PChar(IntToStr(triangleCount)), Trunc(x2), Trunc(yPos), 10, LIME);
      yPos := yPos + 15;

      // Help text
      DrawText('Hold RMB to move camera', 10, 430, 10, GRAY);
      DrawText('(c) Character model and texture from kenney.nl', screenWidth - 260, screenHeight - 20, 10, GRAY);

      // UI Buttons
      if showModel then
      begin
        if GuiButtonCustom(RectangleCreate(10, screenHeight - 100, 100, 60), 'Hide Model') then
          showModel := False;
      end
      else
      begin
        if GuiButtonCustom(RectangleCreate(10, screenHeight - 100, 100, 60), 'Show Model') then
          showModel := True;
      end;

      if GuiButtonCustom(RectangleCreate(120, screenHeight - 100, 100, 60), 'Clear Decals') then
      begin
        for i := 0 to decalCount - 1 do
          UnloadModel(decalModels[i]);
        decalCount := 0;
      end;

      DrawFPS(10, 10);
    EndDrawing();
  end;

  // De-Initialization
  UnloadModel(model);
  UnloadTexture(modelTexture);

  for i := 0 to decalCount - 1 do
    UnloadModel(decalModels[i]);

  UnloadTexture(decalTexture);

  // Free decal mesh data (static)
  FreeDecalMeshData;

  CloseWindow();
end.
