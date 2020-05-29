@echo off
setlocal enabledelayedexpansion

rem for now we'll just pushd the folder in which make.bat resides. useful for visual studio.
pushd %~dp0

set CLEAN_OUTPUT=
set MAME_GAME=aburner2
set MAME_ROM_SIZE=131072

rem Parse the command line. If we find something that's not 'debug', assume it's the rom name, eg. 'outrun'.
for %%i in (%*) do (
  if /i "%%i"=="clean" (
    set CLEAN_OUTPUT=1
  ) else (
    set MAME_GAME=%%i
  )
)

set OUTPUT_PATH=%~dp0\output\!MAME_GAME!
set OUTPUT_PATH_POSIX=output/!MAME_GAME!
set ROMS_PATH=output

rem Todo: make this a parameter and change the output folder. For now you can choose your target game here.
rem Afterburner II, Sega X-board
if /i "!MAME_GAME!"=="aburner2" (
  set "MAME_ROMS1=epr-11107.58 epr-11108.63"
  set "MAME_ROMS2=epr-11109.20 epr-11110.29"
)

if "%MAME_ROMS1%"=="" (
  echo No output ROMs configured for '!MAME_GAME!'!
  goto error
)

if "%CLEAN_OUTPUT%"=="1" goto clean

if not defined OUTRUN_GCC_PATH (
  if exist ..\..\setupenv.bat call "..\..\setupenv.bat"
)

if not defined OUTRUN_GCC_PATH ( 
  echo OUTRUN_GCC_PATH environment variable not set. Please run setenv.bat!
  exit /b 1
)
set OUTRUN_GCC_PREFIX=m68k-elf-

if not exist !OUTPUT_PATH! mkdir !OUTPUT_PATH!

rem clean out linker scripts.
if exist "!OUTPUT_PATH!\main.link.in" del "!OUTPUT_PATH!\main.link.in"
if exist "!OUTPUT_PATH!\sub.link.in" del "!OUTPUT_PATH!\sub.link.in"

rem compile our files.
echo Compiling using GCC version %OUTRUN_GCC_VERSION%...
echo Building for '!MAME_GAME!'.

for %%i in (*.c *.cpp *.s !MAME_GAME!\*.c !MAME_GAME!\*.cpp !MAME_GAME!\*.s) do (
  set inputfile=%%i
  set substr=!inputfile:sub=!
  set cpudef=CPU0
  set skipfile=0
  if not "x!substr!"=="x!inputfile!" (
    set cpudef=CPU1
	if "%MAME_ROMS2%"=="" set skipfile=1
  )
  
  if not !skipfile! equ 1 (
  
	  echo %%i

	  if %%~xi? == .c? (
		%OUTRUN_GCC_PREFIX%gcc -c %%i -std=gnu11 -m68000 -o !OUTPUT_PATH!/%%~ni.o -Os -D!CPUDEF! -I. -I!MAME_GAME!
	  )
	  if %%~xi? == .cpp? (
		%OUTRUN_GCC_PREFIX%g++ -c %%i --no-rtti -m68000 -o !OUTPUT_PATH!/%%~ni.o -Os -D!CPUDEF! -I. -I!MAME_GAME!
	  )
	  if %%~xi? == .s? (
		%OUTRUN_GCC_PREFIX%as %%i -m68000 -o !OUTPUT_PATH!/%%~ni.o --defsym !CPUDEF!=1 -I!MAME_GAME!
	  )

	  if ERRORLEVEL 1 goto error

	  rem append to linker input list
	  if !cpudef!==CPU1 echo !OUTPUT_PATH_POSIX!/%%~ni.o >> "!OUTPUT_PATH!\sub.link.in"
	  if !cpudef!==CPU0 echo !OUTPUT_PATH_POSIX!/%%~ni.o >> "!OUTPUT_PATH!\main.link.in"
  )
  
)

rem link
echo Linking...
echo maincpu_rom.bin
%OUTRUN_GCC_PREFIX%ld @!OUTPUT_PATH!/main.link.in --script=memtest.ld -o !OUTPUT_PATH!/maincpu_rom.bin --Map=!OUTPUT_PATH!/maincpu_rom.map
if ERRORLEVEL 1 goto error

if exist "!OUTPUT_PATH!\sub.link.in" (
  echo subcpu_rom.bin
  %OUTRUN_GCC_PREFIX%ld @!OUTPUT_PATH!/sub.link.in --script=memtest-sub.ld -o !OUTPUT_PATH!/subcpu_rom.bin --Map=!OUTPUT_PATH!/subcpu_rom.map
  if ERRORLEVEL 1 goto error
)

rem delete linker input lists
if exist "!OUTPUT_PATH!\main.link.in" del "!OUTPUT_PATH!\main.link.in"
if exist "!OUTPUT_PATH!\sub.link.in" del "!OUTPUT_PATH!\sub.link.in"

rem build rom images.
echo Building ROM images...

pushd !ROMS_PATH!
splitbin.exe "!OUTPUT_PATH!\maincpu_rom.bin" !MAME_ROM_SIZE! 2 %MAME_ROMS1%
if ERRORLEVEL 1 ( 
  popd
  goto error
)

if exist "!OUTPUT_PATH!\subcpu_rom.bin" (
  splitbin.exe "!OUTPUT_PATH!\subcpu_rom.bin" !MAME_ROM_SIZE! 2 %MAME_ROMS2%
  if ERRORLEVEL 1 ( 
    popd
    goto error 
  )
)

popd

echo Done.
goto end

:clean
rem object files
for %%i in (*.c *.cpp *.s !MAME_GAME!\*.c !MAME_GAME!\*.cpp !MAME_GAME!\*.s) do (
  if exist "!OUTPUT_PATH!\%%~ni.o" del "!OUTPUT_PATH!\%%~ni.o"
)

rem rom files
for %%i in (%MAME_ROMS1% %MAME_ROMS2%) do (
  if exist "!ROMS_PATH!\%%i" del "!ROMS_PATH!\%%i"
)

for %%i in (main.link.in sub.link.in maincpu_ram.bin maincpu_ram.map maincpu_rom.bin maincpu_rom.map subcpu_ram.bin subcpu_ram.map subcpu_rom.bin subcpu_rom.map) do (
  if exist "!OUTPUT_PATH!\%%i" del "!OUTPUT_PATH!\%%i"
)
goto end

:error
echo Build aborted.
exit /b 1

:end

popd
