@echo off

setlocal enableDelayedExpansion

set MAME_DEBUG=
set MAME_GAME=aburner2

rem Parse the command line. If we find something that's not 'debug', assume it's the rom name, eg. 'outrun'.

for %%i in (%*) do (
  if /i "%%i"=="debug" (
    set MAME_DEBUG=1
  ) else (
    set MAME_GAME=%%i
  )
)

rem ROMs needed per game. The first two of ROMS1 are required, the rest is optional.
rem Out Run (original)
set MAME_aburner2_ROMS1=epr-11107.58 epr-11108.63
set MAME_aburner2_ROMS2=epr-11109.20 epr-11110.29


set MAME_ROMS1_NAME=^^!MAME_!MAME_GAME!_ROMS1^^!
set "MAME_ROMS1=%MAME_ROMS1_NAME%"
set MAME_ROMS2_NAME=^^!MAME_!MAME_GAME!_ROMS2^^!
set "MAME_ROMS2=%MAME_ROMS2_NAME%"

if "%MAME_ROMS1%"=="" (
  echo No known ROMs configured for '!MAME_GAME!'. Aborting.
  exit /b 1
)

rem Add possible MAME paths here. Don't be too picky.

for %%i in (%MAME_PATH% c:\coding\mame c:\mame) do (
  for %%j in (mame64.exe mame.exe) do (
    if exist "%%i\%%j" ( 
      set MAME_EXE=%%j
      set MAME_PATH=%%i
      goto found_mame
    )
  )
)

echo MAME executable not found. Aborting.
echo You can set the MAME_PATH variable to your MAME directory, or add it directly to run.bat
exit /b 1

:found_mame

echo Running '%MAME_GAME%' with %MAME_EXE% from %MAME_PATH%.

rem check whether the binaries are present.
set /a count=0
for %%i in (%MAME_ROMS1%) do (
  if not exist "output\%%i" (
    echo Required ROM file %%i not found, aborting.
	exit /b 1
  )
  set /A count += 1
  if !count! equ 2 goto enough_roms
)
:enough_roms

rem copy binaries to MAME roms folder.

if not exist "%MAME_PATH%\roms\%MAME_GAME%" mkdir "%MAME_PATH%\roms\%MAME_GAME%"

for %%i in (%MAME_ROMS1% %MAME_ROMS2%) do (
  if exist "output\%%i" (
    echo Copying %%i
    copy /Y "output\%%i" "%MAME_PATH%\roms\%MAME_GAME%\%%i" > NUL
  )
)

pushd %MAME_PATH%
if !MAME_DEBUG! equ 1 (
	%MAME_EXE% !MAME_GAME! -debug -window -skip_gameinfo
) else (
	%MAME_EXE% !MAME_GAME! -skip_gameinfo
)
popd

:error
:end
