---
baseline_commit: 9c56190
---

# Story 5.5: Versus AI Controller with 3 Difficulty Profiles

Status: review

## Story

As a solo player,
I want to fight against an AI bot with Novice, Veteran, and Ace difficulty levels,
So that I can enjoy a satisfying single-player challenge adapted to my skill level.

## Acceptance Criteria

1. **AI Controller Architecture (`scripts/ai/ai_controller.gd`)**:
   - Beroperasi sebagai komponen otonom yang memproses evaluasi frame-by-frame pada 60 FPS:
     - Jarak (*spacing*) terhadap pemain (dekati jika jauh, spacing di neutral, retreat jika ditekan).
     - Status lawan (apakah dalam startup, active, recovery, atau hitstun).
     - Pemantauan Heat Gauge diri sendiri dan lawan.
   - Mengendalikan mecha melalui antarmuka simulasi input (`simulated_horizontal_input`, input triggers untuk Normal, Heavy, Skill, Dash, Parry).

2. **Tiga Profil Tingkat Kesulitan**:
   - **Novice**:
     - Waktu reaksi lambat (~24 frame delay).
     - Agresivitas rendah, pergerakan lambat tanpa dash udara agresif.
     - Pertahanan pasif: 20% kesempatan block, 5% kesempatan parry.
     - Hanya melancarkan serangan tunggal dasar tanpa target chain scaling yang diperpanjang.
   - **Veteran**:
     - Waktu reaksi moderat (~12 frame delay).
     - Spacing aktif: menjaga jarak serangan efektif (~90-150px) dan melakukan dash punish.
     - Pertahanan terkoordinasi: 70% kesempatan block saat diserang, 35% kesempatan parry.
     - Mampu mengeksekusi rantai kombo dasar (Normal 1 -> Normal 2 / Skill).
   - **Ace**:
     - Waktu reaksi kilat (~6 frame delay).
     - Spacing adaptif presisi tinggi: mengantisipasi whiff dan mengeksekusi counter-hit punish.
     - Pertahanan presisi: 95% kesempatan block, 85% Spark Parry frame-exact pada serangan terdeteksi.
     - Manajemen Heat agresif: memaksimalkan Overclock Zone (80-99%) dan kombo penuh hingga Ultimate.

3. **Integrasi Scene Versus AI (`scenes/versus_ai_mode.tscn`)**:
   - Arena Skyscraper dengan P1 (pemain manusia dengan touch/gamepad overlay), P2 (BaseMecha dikontrol oleh AIController).
   - Terintegrasi penuh dengan `MatchManager` (timer 90 detik, BO3 round format, Ring-Out detection) dan `CombatHUD`.
   - Selector / konfigurasi difficulty yang dapat diakses dari menu atau sebelum ronde dimulai.

4. **Integrasi Main Menu Flow**:
   - Tombol "Versus AI" di Main Menu mengarah ke `scenes/versus_ai_mode.tscn` dengan profil default (Veteran) dan pilihan runtime (Novice / Veteran / Ace).

5. **Automated Testing Suite (`tests/test_versus_ai.gd` & `tests/test_versus_ai.tscn`)**:
   - Validasi konfigurasi parameter untuk ketiga profil (Novice, Veteran, Ace).
   - Validasi perilaku spacing (AI mendekati target saat di luar jangkauan serangan).
   - Validasi respons defensif (peningkatan laju block/parry dari Novice ke Ace saat lawan menyerang).
   - Validasi punish opportunist (AI memicu serangan saat lawan berada dalam recovery/whiff).
   - Validasi kompatibilitas loop 60 FPS tanpa error di mode headless.

## Tasks / Subtasks

- [x] Task 1: AI Controller Core Engine (AC: 1, 2)
  - [x] 1.1 Buat `scripts/ai/ai_controller.gd` dengan FSM AI internal (Spacing, Approach, Attack, Block, Parry, Punish).
  - [x] 1.2 Implementasikan profile loading untuk Novice, Veteran, dan Ace.
- [x] Task 2: Combat & Input Execution Engine (AC: 1, 2)
  - [x] 2.1 Hubungkan deteksi status musuh (FSM state, attack data, jarak X/Y).
  - [x] 2.2 Implementasikan sistem reaction delay queue berbasis frame counter dan flag defensif.
  - [x] 2.3 Implementasikan eksekusi jurus, combo chaining, dan Spark Parry frame-exact.
- [x] Task 3: Scene Versus AI Assembly (AC: 3, 4)
  - [x] 3.1 Buat `scenes/versus_ai_mode.tscn` menggabungkan Arena, P1, P2 AI, HUD, MatchManager, dan UI Difficulty Selector.
  - [x] 3.2 Buat `scripts/ai/versus_ai_manager.gd` untuk mengoordinasi alur pertandingan Versus AI.
  - [x] 3.3 Hubungkan tombol Versus AI pada `scripts/ui/main_menu.gd` agar membuka Versus AI scene.
- [x] Task 4: Automated Testing Suite & Verification (AC: 5)
  - [x] 4.1 Buat `tests/test_versus_ai.gd` dan `tests/test_versus_ai.tscn`.
  - [x] 4.2 Jalankan pengujian headless (6/6 lulus, 100% pass) dan verifikasi regresi penuh.

## Dev Agent Record

- **Implemented Components**:
  - `scripts/characters/base_mecha.gd`: Penambahan dukungan simulasi input terpadu (`simulated_vertical_input`, `simulated_actions`, `trigger_simulated_action()`, dan integrasi dengan `is_simulated_action_pressed()`).
  - `scripts/ai/ai_controller.gd`: Autonomous AI decision engine 60 FPS dengan 3 level kesulitan (NOVICE, VETERAN, ACE), evaluasi jarak spacing, deteksi whiff punish, combo chaining, dan frame-exact defense reaction.
  - `scripts/ai/versus_ai_manager.gd`: Coordinator scene duel P1 vs AI bot dengan integrasi MatchManager (BO3, 90s timer), CombatHUD, Difficulty Selector, dan Match Result Overlay.
  - `scenes/versus_ai_mode.tscn`: Scene lengkap Versus AI Mode.
  - `scripts/ui/main_menu.gd`: Perutean opsi "VERSUS AI" ke `scenes/versus_ai_mode.tscn`.
  - `tests/test_versus_ai.gd` & `tests/test_versus_ai.tscn`: Headless test suite (6 pengujian).
- **Test Results**:
  - 6/6 test cases passed headless with 0 errors.
  - All regression suites (test_training_mode, test_combat_hud, test_dual_input_system, test_main_menu, test_match_rules) passed 100%.
