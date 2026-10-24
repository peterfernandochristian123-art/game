@echo off
cd /d "%~dp0"
echo Opening Fighting to Zero in Godot Editor...
start "" ".godot_bin\Godot_v4.7.2-stable_win64.exe" -e --path .
