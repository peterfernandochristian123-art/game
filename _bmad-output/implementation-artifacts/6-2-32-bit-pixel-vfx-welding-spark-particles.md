---
baseline_commit: 4b5f686
---

# Story 6.2: 32-Bit Pixel VFX & Welding Spark Particles

Status: review

## Story

As a player engaged in intense mecha combat,
I want dynamic sparks, glowing energy slashes, and steam venting during high heat,
So that the combat is visually spectacular in authentic 90s neo-retro 32-bit aesthetics.

## Acceptance Criteria

1. **Welding Sparks Particle System (`scripts/visual/vfx_sparks.gd` / `scenes/vfx/vfx_welding_sparks.tscn`)**:
   - Memancarkan partikel percikan api las logam berwarna oranye-kuning berpijar tajam (color ramp: putih -> kuning terang -> oranye menyala -> abu-abu dingin).
   - Memiliki kecepatan lontaran tinggi, gravitasi, dan masa hidup singkat (~0.25 - 0.4 detik).
   - Dipancarkan secara instan pada koordinat titik kontak tumbukan saat serangan mendarat atau ditangkis.

2. **Energy Slash Trail VFX (`scripts/visual/vfx_slash.gd` / `scenes/vfx/vfx_energy_slash.tscn`)**:
   - Menghasilkan busur tebasan energi berpendar neon tajam (Cyan untuk Apex Viper, Crimson/Amber untuk Titan Bulwark) pada resolusi pixel 640x360.
   - Menggunakan animasi frame atau shader busur tebasan 32-bit retro dengan durasi selaras window frame aktif serangan (~4-8 frame).

3. **Overclock Steam / Heat Venting VFX (`scripts/visual/vfx_steam_vent.gd` / `scenes/vfx/vfx_steam_vent.tscn`)**:
   - Partikel asap/uap panas memancar dari exhaust / ventilasi mecha saat suhu berada di Overclock Zone (80% - 99%).
   - Berubah menjadi semburan uap merah kritis saat mecha mendekati 100% atau memasuki Meltdown.

4. **Global VFX Manager (`scripts/visual/vfx_manager.gd`)**:
   - Mendengarkan `EventBus.hit_confirmed`, `EventBus.parry_triggered`, dan `EventBus.state_changed`.
   - Mengatur pooling partikel dan instansiasi efek visual tanpa lag atau overhead memori.

5. **Automated Testing Suite (`tests/test_pixel_vfx.gd` & `tests/test_pixel_vfx.tscn`)**:
   - Validasi instansiasi dan emisi partikel percikan las saat dipanggil pada titik kontak tertentu.
   - Validasi siklus hidup partikel (one-shot, auto-cleanup atau pooling).
   - Validasi pemancaran uap ventilasi panas pada mecha saat heat gauge >= 80%.
   - Validasi kompatibilitas headless runner tanpa error.

## Tasks / Subtasks

- [x] Task 1: Welding Sparks & Slash VFX Scenes (AC: 1, 2)
  - [x] 1.1 Buat scene `scenes/vfx/vfx_welding_sparks.tscn` dan scriptnya `scripts/visual/vfx_sparks.gd`.
  - [x] 1.2 Buat scene `scenes/vfx/vfx_energy_slash.tscn` dan scriptnya `scripts/visual/vfx_slash.gd`.
- [x] Task 2: Heat Steam Venting Component (AC: 3)
  - [x] 2.1 Buat `scenes/vfx/vfx_steam_vent.tscn` dan scriptnya `scripts/visual/vfx_steam_vent.gd`.
  - [x] 2.2 Pasang `_setup_steam_vent()` pada `scripts/characters/base_mecha.gd` untuk memantau status Overclock/Meltdown.
- [x] Task 3: VFX Manager Subsystem (AC: 4)
  - [x] 3.1 Buat `scripts/visual/vfx_manager.gd` untuk mendengarkan EventBus dan memancarkan efek di arena.
  - [x] 3.2 Pasang `VFXManager` di `scenes/arena_skyscraper.tscn`.
- [x] Task 4: Automated Testing Suite & Verification (AC: 5)
  - [x] 4.1 Buat `tests/test_pixel_vfx.gd` dan `tests/test_pixel_vfx.tscn`.
  - [x] 4.2 Jalankan pengujian headless (5/5 lulus, 100% pass) dan verifikasi regresi penuh.

## Dev Agent Record

- **Implemented Components**:
  - `scripts/visual/vfx_sparks.gd` & `scenes/vfx/vfx_welding_sparks.tscn`: Sistem partikel CPUParticles2D percikan api las berkecepatan tinggi dengan color ramp (putih -> kuning -> oranye) dan mode amplifikasi Spark Parry.
  - `scripts/visual/vfx_slash.gd` & `scenes/vfx/vfx_energy_slash.tscn`: Busur tebasan energi neon 32-bit (Cyan/Amber) dengan fade-out 6-8 frame pixel art.
  - `scripts/visual/vfx_steam_vent.gd` & `scenes/vfx/vfx_steam_vent.tscn`: Ventilasi uap panas otomatis saat mecha mencapai Overclock Zone (>= 80%) dan uap merah saat Meltdown Kritis (>= 95%).
  - `scripts/characters/base_mecha.gd`: Terintegrasi dengan `VFXSteamVent` otomatis di `_ready()`.
  - `scripts/visual/vfx_manager.gd`: Coordinator instansiasi efek visual di arena berbasis `EventBus.hit_confirmed` dan `EventBus.parry_triggered`.
  - `scenes/arena_skyscraper.tscn`: Terpasang node `VFXManager`.
  - `tests/test_pixel_vfx.gd` & `tests/test_pixel_vfx.tscn`: Headless test suite (5 pengujian).
- **Test Results**:
  - 5/5 test cases passed headless with 0 errors.
  - Seluruh suite regresi (test_hitstop_screen_shake, test_versus_ai, test_local_versus, test_training_mode) lulus 100%.
