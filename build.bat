@echo off

pushd %~dp0

set exe_name=raytracing
set collections=
rem -collection:externals=externals

rem Release build config
set level=0
set dir=release
set debug_flag=""

if "%1"=="debug" (
    rem Debug build config
    set level=0
    set dir=debug
    set exe_name=%exe_name%_d
    set debug_flag=-debug
)

echo Building %dir% binary...
if not exist "build\%dir%\" mkdir "build\%dir%\"

odin build main.odin %collections% -out:"build\%dir%\%exe_name%.exe" %debug_flag% -opt:%level% -vet -show-timings

popd
