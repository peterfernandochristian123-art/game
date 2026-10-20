---
baseline_commit: 51bb3f1
---

# Story 6.1: Local Frame-Hitstop & Dynamic Screen Shake

Status: review

## Story

As a player landing a heavy punch or parrying an attack,
I want a momentary freeze frame (hitstop) and screen shake on impact,
So that every strike feels visceral, heavy, and satisfying.

## Acceptance Criteria

1. **Local Hitstop Subsystem (`scripts/combat/components/hitstop_component.gd`)**:
   - Mendengarkan sinyal `EventBus.hitstop_requested` dan `EventBus.hit_confirmed`.
   - Mengaplikasikan pembekuan logika frame lokal (`hitstop_frames`) pada karakter yang terlibat tanpa membekukan thread engine global atau rendering partikel latar belakang:
     - Light Attack: 4 frame hitstop.
     - Heavy Attack: 8 frame hitstop.
     - Skill / Overclock Attack: 10 frame hitstop.
     - Spark Parry: 12 frame hitstop pada penyerang.
     - Ultimate Attack: 16 frame hitstop dengan cinematic freeze.
   - Mendukung pengganda hitstop (`hitstop_multiplier`) dari preferensi pemain di `SettingsManager`.

2. **Dynamic Screen Shake Camera Component (`scripts/visual/combat_camera.gd`)**:
   - Terpasang pada `Camera2D` di arena pertarungan (`scenes/arena_skyscraper.tscn`).
   - Mendengarkan sinyal `EventBus.screen_shake_requested(intensity: float, duration_frames: int)`:
     - Getaran dinamis dengan decay eksponensial/linear halus pada 60 FPS.
     - Intensitas terkalibrasi proporsional:
       - Light impact: intensitas ~2.5px, durasi ~6 frame.
       - Heavy impact: intensitas ~6.0px, durasi ~12 frame.
       - Spark Parry / Ultimate: intensitas ~10.0px, durasi ~18 frame.
   - Menghormati pengaturan aksesibilitas `display/screen_shake` dari `SettingsManager` (jika disabled, tidak ada goyangan kamera).

3. **Arena Integration**:
   - Memasang `CombatCamera` ke `scenes/arena_skyscraper.tscn`.
   - Mengintegrasikan `HitstopComponent` ke `scenes/arena_skyscraper.tscn`.

4. **Automated Testing Suite (`tests/test_hitstop_screen_shake.gd` & `tests/test_hitstop_screen_shake.tscn`)**:
   - Validasi `HitstopComponent` mengaplikasikan durasi frame yang tepat pada `apply_hitstop` karakter penyerang dan korban.
   - Validasi `CombatCamera` memproses screen shake dan mereset offset kembali ke (0, 0) setelah durasi selesai.
   - Validasi bahwa screen shake tidak aktif jika `screen_shake = false` di `SettingsManager`.
   - Validasi parry sukses memicu 12 frame hitstop dan screen shake intensif.

## Tasks / Subtasks

- [x] Task 1: Hitstop Component Implementation (AC: 1)
  - [x] 1.1 Buat `scripts/combat/components/hitstop_component.gd` yang mengikat `EventBus` dan mengaplikasikan hitstop terkalibrasi.
- [x] Task 2: Dynamic Screen Shake Camera Component (AC: 2)
  - [x] 2.1 Buat `scripts/visual/combat_camera.gd` untuk `Camera2D` dengan dukungan decay shake dan pembacaan konfigurasi `SettingsManager`.
  - [x] 2.2 Pasang `CombatCamera` di `scenes/arena_skyscraper.tscn`.
- [x] Task 3: Combat Pipeline Integration (AC: 1, 2, 3)
  - [x] 3.1 Sambungkan emisi `screen_shake_requested` dan `hitstop_requested` pada kontak serangan di `scripts/combat/fsm/attack_state.gd` dan `parry_state.gd`.
  - [x] 3.2 Pasang `HitstopComponent` ke scene `scenes/arena_skyscraper.tscn`.
- [x] Task 4: Automated Testing Suite & Verification (AC: 4)
  - [x] 4.1 Buat `tests/test_hitstop_screen_shake.gd` dan `tests/test_hitstop_screen_shake.tscn`.
  - [x] 4.2 Jalankan pengujian headless (5/5 lulus, 100% pass) dan verifikasi regresi seluruh suite.

## Dev Agent Record

- **Implemented Components**:
  - `scripts/combat/components/hitstop_component.gd`: Komponen local freeze-frame berbasis event (Light: 4f, Heavy: 8f, Skill: 10f, Parry: 12f, Ultimate: 16f) yang memicu `screen_shake_requested` proporsional.
  - `scripts/visual/combat_camera.gd`: Custom Camera2D controller dengan smooth exponential decay shake, boundaries clamping (400-1000px), fighter mid-point tracking, dan integrasi preferensi SettingsManager.
  - `scenes/arena_skyscraper.tscn`: Penambahan `CombatCamera` dan `HitstopComponent` langsung ke arena panggung.
  - `tests/test_hitstop_screen_shake.gd` & `tests/test_hitstop_screen_shake.tscn`: Headless test suite (5 pengujian).
- **Test Results**:
  - 5/5 test cases passed headless with 0 errors.
  - Seluruh suite regresi (test_versus_ai, test_local_versus, test_training_mode, test_match_rules) lulus 100%.
