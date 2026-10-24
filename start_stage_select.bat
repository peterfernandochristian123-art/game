@echo off
title Stage Select - Project Retro Zero
cd /d "%~dp0"
echo Membuka Stage Select Menu...
start "" ".godot_bin\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/menus/stage_select.tscn
