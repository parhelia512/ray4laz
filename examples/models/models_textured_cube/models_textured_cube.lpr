program models_textured_cube;

{$mode objfpc}{$H+}

uses cmem, raylib, rlgl;

const
  screenWidth = 800;
  screenHeight = 450;

procedure DrawCubeTexture(texture: TTexture2D; position: TVector3; width, height, length: single; color: TColorB);
var
  x, y, z: single;
begin
  x := position.x;
  y := position.y;
  z := position.z;

  rlSetTexture(texture.id);

  rlBegin(RL_QUADS);
    rlColor4ub(color.r, color.g, color.b, color.a);
    // Front Face
    rlNormal3f(0.0, 0.0, 1.0);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x - width/2, y - height/2, z + length/2);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x + width/2, y - height/2, z + length/2);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x - width/2, y + height/2, z + length/2);
    // Back Face
    rlNormal3f(0.0, 0.0, -1.0);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x - width/2, y + height/2, z - length/2);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x + width/2, y + height/2, z - length/2);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x + width/2, y - height/2, z - length/2);
    // Top Face
    rlNormal3f(0.0, 1.0, 0.0);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x - width/2, y + height/2, z - length/2);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x - width/2, y + height/2, z + length/2);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x + width/2, y + height/2, z - length/2);
    // Bottom Face
    rlNormal3f(0.0, -1.0, 0.0);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x + width/2, y - height/2, z - length/2);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x + width/2, y - height/2, z + length/2);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x - width/2, y - height/2, z + length/2);
    // Right Face
    rlNormal3f(1.0, 0.0, 0.0);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x + width/2, y - height/2, z - length/2);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x + width/2, y + height/2, z - length/2);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x + width/2, y - height/2, z + length/2);
    // Left Face
    rlNormal3f(-1.0, 0.0, 0.0);
    rlTexCoord2f(0.0, 0.0); rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f(1.0, 0.0); rlVertex3f(x - width/2, y - height/2, z + length/2);
    rlTexCoord2f(1.0, 1.0); rlVertex3f(x - width/2, y + height/2, z + length/2);
    rlTexCoord2f(0.0, 1.0); rlVertex3f(x - width/2, y + height/2, z - length/2);
  rlEnd();

  rlSetTexture(0);
end;

procedure DrawCubeTextureRec(texture: TTexture2D; source: TRectangle; position: TVector3;
  width, height, length: single; color: TColorB);
var
  x, y, z, texWidth, texHeight: single;
begin
  x := position.x;
  y := position.y;
  z := position.z;
  texWidth := texture.width;
  texHeight := texture.height;

  rlSetTexture(texture.id);

  rlBegin(RL_QUADS);
    rlColor4ub(color.r, color.g, color.b, color.a);

    // Front face
    rlNormal3f(0.0, 0.0, 1.0);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y - height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y - height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y + height/2, z + length/2);

    // Back face
    rlNormal3f(0.0, 0.0, -1.0);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y + height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y + height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y - height/2, z - length/2);

    // Top face
    rlNormal3f(0.0, 1.0, 0.0);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y + height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y + height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y + height/2, z - length/2);

    // Bottom face
    rlNormal3f(0.0, -1.0, 0.0);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y - height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y - height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y - height/2, z + length/2);

    // Right face
    rlNormal3f(1.0, 0.0, 0.0);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y - height/2, z - length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y + height/2, z - length/2);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x + width/2, y + height/2, z + length/2);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x + width/2, y - height/2, z + length/2);

    // Left face
    rlNormal3f(-1.0, 0.0, 0.0);
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y - height/2, z - length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
    rlVertex3f(x - width/2, y - height/2, z + length/2);
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y + height/2, z + length/2);
    rlTexCoord2f(source.x/texWidth, source.y/texHeight);
    rlVertex3f(x - width/2, y + height/2, z - length/2);

  rlEnd();

  rlSetTexture(0);
end;

var
  camera: TCamera3D;
  texture: TTexture2D;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [models] example - textured cube');

  camera.position := Vector3Create(0.0, 10.0, 10.0);
  camera.target := Vector3Create(0.0, 0.0, 0.0);
  camera.up := Vector3Create(0.0, 1.0, 0.0);
  camera.fovy := 45.0;
  camera.projection := CAMERA_PERSPECTIVE;

  texture := LoadTexture(PChar(GetApplicationDirectory + 'resources/cubicmap_atlas.png'));

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    BeginDrawing();
      ClearBackground(RAYWHITE);

      BeginMode3D(camera);
        DrawCubeTexture(texture, Vector3Create(-2.0, 2.0, 0.0), 2.0, 4.0, 2.0, WHITE);

        DrawCubeTextureRec(texture,
          RectangleCreate(0.0, texture.height/2.0, texture.width/2.0, texture.height/2.0),
          Vector3Create(2.0, 1.0, 0.0), 2.0, 2.0, 2.0, WHITE);

        DrawGrid(10, 1.0);
      EndMode3D();

      DrawFPS(10, 10);
    EndDrawing();
  end;

  UnloadTexture(texture);
  CloseWindow();
end.
