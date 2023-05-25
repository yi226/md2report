@echo off

set pythonPath=%cd%\md2report
set scriptPath=%cd%\md2report\Scripts
set sourcePath=%cd%\md2report\source
set PATH=%pythonPath%;%scriptPath%;%sourcePath%;%PATH%

cd md2report\source

python md2report.py -i %1

cd ..
cd ..

echo https://github.com/yi226/md2report