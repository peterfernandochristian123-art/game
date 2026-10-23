---
baseline_commit: 332713a
---

# Story 8.1: Cyberpunk Synthwave OST System (Menu & Arena BGM)

Status: done

## Story

As a player navigating menus or engaging in intense mecha combat,
I want dynamic, looped 90s cyberpunk synthwave background music playing through the BGM audio bus with smooth transitions,
So that every battle feels energetic, stylish, and retro-arcade authentic.

## Acceptance Criteria

1. **Procedural Synthwave Music Engine (`scripts/audio/music_synthesizer.gd`)**:
   - Menghasilkan dua trek musik BGM arcade synthwave 90-an mandiri berformat `AudioStreamWAV` dengan loop points aktif (`loop_mode = LOOP_FORWARD`):
     - **Title Theme ("Neon Horizon")**: Tempo santai 105 BPM, tangga nada D Minor, synth arpeggio halus, bassline FM 90-an hangat, beat kick-snare retro.
     - **Arena Battle Theme ("Skyscraper Meltdown")**: Tempo energetik 128 BPM, tangga nada A Minor, driving 16th-note synth bassline, arcade drum beat tegas (punchy kick & snare), neon lead motif.
   - Seluruh buffer audio dihasilkan secara deterministik dalam memori dengan sample rate optimal (22.05 kHz) tanpa ketergantungan file MP3/OGG eksternal.

2. **AudioManager BGM Crossfade Subsystem (`scripts/audio/audio_manager.gd`)**:
   - Menambahkan dual audio stream players (`_bgm_player_a`, `_bgm_player_b`) yang terpasang permanen pada audio bus `BGM`.
   - Menyediakan fungsi `play_bgm(theme_name: StringName, fade_time: float = 0.5)` dan `stop_bgm(fade_time: float = 0.5)`.
   - Transisi antar trek musik (Title Theme <-> Arena Theme) menggunakan interpolasi volume halus (*linear crossfade*) tanpa distorsi, audio clipping, atau popping.
   - Menghormati pengaturan volume bus `BGM` di `AudioManager.set_bus_volume(&"BGM", value)`.

3. **Scene Integration (Main Menu, Arena Skyscraper, Training Mode)**:
   - `scenes/main_menu.tscn`: Secara otomatis mengaktifkan BGM Title Theme saat menu utama dimuat.
   - `scenes/arena_skyscraper.tscn`: Secara otomatis mengaktifkan BGM Arena Battle Theme saat arena dimuat.
   - `scenes/training_mode.tscn`: Mengaktifkan BGM Arena Battle Theme saat mode latihan aktif.

4. **Automated Verification Suite (`tests/test_synthwave_ost.gd`)**:
   - Memvalidasi pembentukan buffer WAV Title Theme dan Arena Theme dengan `loop_mode` aktif.
   - Memvalidasi transisi `play_bgm` dan pengaturan volume bus `BGM`.
   - Menjamin seluruh 27 test suite yang ada tetap 100% lulus tanpa regresi.

## Tasks / Subtasks

- [x] Task 1: Procedural Synthwave Music Generator (`scripts/audio/music_synthesizer.gd`) (AC: 1)
  - [x] 1.1 Implementasikan synthesizer drum kick, snare, hi-hat, synth bass, dan lead arpeggio.
  - [x] 1.2 Buat generator Title Theme "Neon Horizon" (105 BPM, looping).
  - [x] 1.3 Buat generator Arena Battle Theme "Skyscraper Meltdown" (128 BPM, looping).
- [x] Task 2: AudioManager Dual-Player BGM Engine (`scripts/audio/audio_manager.gd`) (AC: 2)
  - [x] 2.1 Tambahkan dual `AudioStreamPlayer` pada bus `BGM` untuk crossfade bebas glitch.
  - [x] 2.2 Implementasikan logika `play_bgm` dan `stop_bgm` dengan crossfade halus.
- [x] Task 3: Scene Integration (AC: 3)
  - [x] 3.1 Sambungkan BGM Title pada `scenes/main_menu.gd` / `main_menu.tscn`.
  - [x] 3.2 Sambungkan BGM Arena pada `scripts/arena/arena_skyscraper.gd`.
  - [x] 3.3 Sambungkan BGM pada `scripts/training/training_mode.gd`.
- [x] Task 4: Automated Testing & Verification (AC: 4)
  - [x] 4.1 Buat `tests/test_synthwave_ost.gd` dan `tests/test_synthwave_ost.tscn`.
  - [x] 4.2 Jalankan seluruh automated test suite Godot untuk menjamin kelulusan 100%.
