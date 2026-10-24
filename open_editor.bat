@echo off
title Buka Godot Editor - Project Retro Zero
cd /d "%~dp0"
echo Membuka Godot 4 Editor...
start "" ".godot_bin\Godot_v4.7.2-stable_win64.exe" -e --path .
