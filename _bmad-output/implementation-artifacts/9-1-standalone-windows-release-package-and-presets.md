---
baseline_commit: a5f69ea
---

# Story 9.1: Standalone Windows Release Package & Presets

Status: done

## Story

As a player or distributor,
I want a standalone Windows executable (`FightingToZero.exe`) and package (`FightingToZero.pck`) that runs independently without opening the Godot Editor,
So that anyone can easily install and play the full game on PC.

## Acceptance Criteria

1. **Godot Export Configuration (`export_presets.cfg`)**:
   - Berkas konfigurasi [export_presets.cfg](file:///c:/Users/game/export_presets.cfg) mendefinisikan preset `Windows Desktop` dengan opsi kompresi tekstur, metadata versi `1.0.0`, nama produk `Fighting to Zero`, dan ikon aplikasi `res://icon.svg`.
2. **Encapsulated Binary Pack Generation**:
   - Perintah ekspor `--export-pack "Windows Desktop" builds/windows/FightingToZero.pck` mengompilasi dan mengemas seluruh scene, script, asset visual, dan audio ke dalam format paket mandiri.
3. **Standalone Windows Executable**:
   - Binary [builds/windows/FightingToZero.exe](file:///c:/Users/game/builds/windows/FightingToZero.exe) dapat dijalankan langsung dan otomatis memuat `FightingToZero.pck` pada folder yang sama.
4. **Convenience Batch Launcher**:
   - Disediakan berkas [run_standalone_build.bat](file:///c:/Users/game/run_standalone_build.bat) di root folder proyek untuk menjalankan build standalone secara langsung.

## Tasks / Subtasks

- [x] Task 1: Konfigurasi Export Presets (AC: 1)
  - [x] 1.1 Buat `export_presets.cfg` dengan konfigurasi preset "Windows Desktop"
  - [x] 1.2 Atur metadata versi, ikon, dan filter resource
- [x] Task 2: Ekspor Paket Game PCK & Binary (AC: 2, 3)
  - [x] 2.1 Jalankan `--export-pack` untuk menghasilkan `builds/windows/FightingToZero.pck`
  - [x] 2.2 Sediakan binary Windows `builds/windows/FightingToZero.exe`
  - [x] 2.3 Uji eksekusi runtime standalone (`--quit-after 60`) untuk memastikan kelancaran loading
- [x] Task 3: Launcher Script & Git Hygiene (AC: 4)
  - [x] 3.1 Buat `run_standalone_build.bat` di root direktori
  - [x] 3.2 Tambahkan `builds/` ke `.gitignore` untuk mencegah penyimpanan binary bervolume besar di git
