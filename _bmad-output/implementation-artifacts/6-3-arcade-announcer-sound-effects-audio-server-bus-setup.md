---
baseline_commit: 70046de
---

# Story 6.3: Arcade Announcer, Sound Effects & Audio Server Bus Setup

Status: review

## Story

As a player,
I want heavy metal clang sound effects, hydraulic hisses, and a retro arcade announcer voice over dedicated audio buses,
So that the game audio is immersive, punchy, and customizable.

## Acceptance Criteria

1. **AudioServer 5-Bus Architecture (`default_bus_layout.tres` & `scripts/audio/audio_manager.gd`)**:
   - Dikonfigurasi 5 bus audio diskrit:
     1. `Master`: Bus akar pengatur volume global.
     2. `BGM`: Musik latar belakang pertarungan & menu.
     3. `SFX`: Efek suara tumbukan logam berat, sabetan, thruster dash, dan parry.
     4. `Announcer`: Suara komentator arcade 90-an ("ENGAGE!", "ROUND 1", "CRITICAL HEAT", "K.O.").
     5. `MechaVoice`: Efek vokal / radio comms mecha tempur.
   - Volume tiap bus dapat dikontrol secara independen via desibel / linear (0.0 - 1.0) dan tersinkronisasi dengan `SettingsManager`.

2. **Sound Effects Subsystem (Procedural 32-Bit Sound Engine)**:
   - SFX Logam Berat (*Heavy Metal Clang*): Pukulan normal dan heavy.
   - SFX Percikan Elektrik (*Spark Parry Clang*): Frekuensi tinggi berpijar tajam saat parry frame-exact.
   - SFX Hidrolik & Thruster (*Hydraulic Hiss & Thruster Dash*): Suara pelepasan uap pneumatik saat dash dan jumping.
   - Mampu menghasilkan AudioStreamWAV terprogram secara otonom sehingga dapat berjalan di semua lingkungan.

3. **Arcade Announcer Voice System**:
   - Menghasilkan dan memutar audio cue arcade retro berkarakter mecha 90-an untuk momen pertandingan:
     - *Round Start*: "ROUND [N]... ENGAGE!"
     - *Critical Heat*: "WARNING: HIGH HEAT DETECTED"
     - *Meltdown*: "EMERGENCY MELTDOWN!"
     - *K.O. / Core Break*: "CORE BREAK... K.O.!"

4. **Automated Testing Suite (`tests/test_audio_system.gd` & `tests/test_audio_system.tscn`)**:
   - Validasi keberadaan 5 bus audio (`Master`, `BGM`, `SFX`, `Announcer`, `MechaVoice`) pada `AudioServer`.
   - Validasi kontrol volume independen per bus dan persistensinya.
   - Validasi pemicu pemutaran audio announcer dan sfx saat menerima sinyal event bus.
   - Validasi kompatibilitas headless runner tanpa error audio device.

## Tasks / Subtasks

- [x] Task 1: AudioServer 5-Bus Layout Setup (AC: 1)
  - [x] 1.1 Buat `default_bus_layout.tres` dengan 5 bus audio (Master, BGM, SFX, Announcer, MechaVoice).
  - [x] 1.2 Daftarkan layout audio di `project.godot`.
- [x] Task 2: Procedural Sound Engine & Audio Manager (AC: 2, 3)
  - [x] 2.1 Buat `scripts/audio/audio_synthesizer.gd` untuk menghasilkan waveform audio retro (Metal Clang, Hiss, Announcer cue).
  - [x] 2.2 Buat `scripts/audio/audio_manager.gd` untuk mengelola audio bus, pooling AudioStreamPlayer, dan menghubungkan EventBus.
- [x] Task 3: Settings & Scene Wiring (AC: 1, 3)
  - [x] 3.1 Hubungkan `SettingsManager` dengan `AudioManager` untuk pembaruan volume dinamis.
  - [x] 3.2 Pasang `AudioManager` di `scenes/arena_skyscraper.tscn`.
- [x] Task 4: Automated Testing Suite & Verification (AC: 4)
  - [x] 4.1 Buat `tests/test_audio_system.gd` dan `tests/test_audio_system.tscn`.
  - [x] 4.2 Jalankan pengujian headless (5/5 lulus, 100% pass) dan verifikasi regresi penuh.

## Dev Agent Record

- **Implemented Components**:
  - `default_bus_layout.tres`: Konfigurasi resource bus layout 5 channel (`Master`, `BGM`, `SFX`, `Announcer`, `MechaVoice`) yang terdaftar di `project.godot`.
  - `scripts/audio/audio_synthesizer.gd`: Generator audio procedural 32-bit (PCM 8-bit / 22050 Hz) untuk Heavy Metal Clang, Spark Parry, Hydraulic Hiss, dan Announcer Chime.
  - `scripts/audio/audio_manager.gd`: Coordinator audio dengan pool AudioStreamPlayer, event bus dispatch otomatis (hit, parry, round end), serta method setter/getter linear volume.
  - `scenes/arena_skyscraper.tscn`: Node `AudioManager` terintegrasi.
  - `tests/test_audio_system.gd` & `tests/test_audio_system.tscn`: Headless test suite (5 pengujian).
- **Test Results**:
  - 5/5 test cases passed headless with 0 errors.
  - Seluruh suite regresi (test_pixel_vfx, test_hitstop_screen_shake, test_versus_ai, test_local_versus, test_training_mode) lulus 100%.
