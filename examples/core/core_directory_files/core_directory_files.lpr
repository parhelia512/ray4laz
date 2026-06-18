program core_directory_files;

{$mode objfpc}{$H+}

uses cmem, raylib, raygui, sysutils;

const
  screenWidth = 800;
  screenHeight = 450;
  MAX_FILEPATH_SIZE = 1024;
  FILE_FILTER = 'DIRS*;.png;.c';

var
  directory: array[0..MAX_FILEPATH_SIZE - 1] of Char;
  files: TFilePathList;
  btnBackPressed: Boolean;
  listScrollIndex: Integer;
  listItemActive: Integer;
  listItemFocused: Integer;
  i: Integer;
begin
  InitWindow(screenWidth, screenHeight, 'raylib [core] example - directory files');

  StrLCopy(directory, PChar(GetWorkingDirectory), MAX_FILEPATH_SIZE - 1);
  files := LoadDirectoryFilesEx(directory, FILE_FILTER, False);

  btnBackPressed := False;
  listScrollIndex := 0;
  listItemActive := -1;
  listItemFocused := -1;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    if btnBackPressed then
    begin
      StrLCopy(directory, PChar(GetPrevDirectoryPath(directory)), MAX_FILEPATH_SIZE - 1);
      UnloadDirectoryFiles(files);
      files := LoadDirectoryFilesEx(directory, FILE_FILTER, False);
      listScrollIndex := 0;
      listItemActive := -1;
      listItemFocused := -1;
    end;

    if (listItemActive >= 0) and (listItemActive < Integer(files.count)) and
       DirectoryExists(files.paths[listItemActive]) then
    begin
      StrLCopy(directory, files.paths[listItemActive], MAX_FILEPATH_SIZE - 1);
      UnloadDirectoryFiles(files);
      files := LoadDirectoryFilesEx(directory, FILE_FILTER, False);
      listScrollIndex := 0;
      listItemActive := -1;
      listItemFocused := -1;
    end;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      btnBackPressed := GuiButton(RectangleCreate(40, 10, 48, 28), '<') <> 0;

      GuiSetStyle(DEFAULT, TEXT_SIZE, GuiGetFont.baseSize * 2);
      GuiLabel(RectangleCreate(40 + 48 + 10, 10, 700, 28), directory);
      GuiSetStyle(DEFAULT, TEXT_SIZE, GuiGetFont.baseSize);

      GuiSetStyle(LISTVIEW, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
      GuiSetStyle(LISTVIEW, TEXT_PADDING, 40);
      GuiListViewEx(RectangleCreate(0, 50, GetScreenWidth, GetScreenHeight - 50),
        files.paths, Integer(files.count), @listScrollIndex, @listItemActive, @listItemFocused);

    EndDrawing();
  end;

  UnloadDirectoryFiles(files);
  CloseWindow();
end.
