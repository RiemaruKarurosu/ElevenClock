@echo off
setlocal EnableDelayedExpansion

set "option="
for %%a in (%*) do (
   if not defined option (
      set arg=%%a
      echo %arg%
      if "!arg:~0,2!" equ "--" (
        set "option!arg!=1"
        set "option="
      ) else (
        if "!arg:~0,1!" equ "-" set "option=!arg!"
      )
   ) else (
      set "option!option!=%%a"
      set "option="
   )
)

set option

python -m pip install -r requirements.txt
python -m pip install packaging
if defined option--only-requirements (
    goto :end
)

python check_python_version.py --min-version "3.11.0"
if %errorlevel% neq 0 (
    exit /b %errorlevel%
)

@echo on

python apply_version.py
xcopy elevenclock elevenclock_bin /E /H /C /I /Y
cd elevenclock_bin
python -m compileall -b .
del /S *.py
rmdir /Q /S __pycache__
rmdir /Q /S external\__pycache__
rmdir /Q /S lang\__pycache__
rmdir /Q /S build
rmdir /Q /S dist
python -m PyInstaller ../elevenclock/__init__.py --icon "resources/icon.ico" --add-binary "*.pyc;." --add-data "resources;resources" --add-data "lang;lang" --clean --exclude-module PySide2 --exclude-module numpy --windowed --version-file ../elevenclock-version-info --name ElevenClock
cd dist
rename ElevenClock ElevenClockBin
cd ..
cd ..
rmdir /Q /S ElevenClockBin
cd elevenclock_bin
cd dist
move ElevenClockBin ../../
cd ..
rmdir /Q /S build
rmdir /Q /S dist
del ElevenClock.spec
cd ..
rmdir /Q /S elevenclock_bin
cd ElevenClockBin
cd tcl
rmdir /Q /S tzdata
cd ..
cd lang
del APIKEY.txt
del download_translations.pyc
cd ..
copy "%localappdata%\Programs\Python\Python310\pythoncom*.dll" .\
cd PySide6
del opengl32sw.dll
del Qt6Quick.dll
del Qt6Qml.dll
del Qt6OpenGL.dll
del Qt6QmlModels.dll
del Qt6Network.dll
del Qt6DataVisualization.dll
del Qt6VirtualKeyboard.dll
del QtDataVisualization.pyd
del QtOpenGL.pyd
cd ..
cd ..

if defined option--no-installer (
    goto :skip-installer
)

set INSTALLATOR="%SYSTEMDRIVE%\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist %INSTALLATOR% (
    %INSTALLATOR% "ElevenClock.iss"
    ElevenClock.Installer.exe
) else (
    echo "Make installer is skipped, because installator missing."
    echo "Running app..."
    start /b ElevenClockBin/ElevenClock.exe
)
:skip-installer

if defined option--release (
    python generate_release.py
)

:end
pause
