@echo off
cd md2report
call .\Scripts\activate.bat

cd source
python md2report.py -i %1
cd ..

call .\Scripts\deactivate.bat
cd ..

echo https://github.com/yi226/md2report