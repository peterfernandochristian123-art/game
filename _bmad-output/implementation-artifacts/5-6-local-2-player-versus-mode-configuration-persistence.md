---
baseline_commit: 4c7031a
---

# Story 5.6: Local 2-Player Versus Mode & Configuration Persistence

Status: review

## Story

As two local players on PC,
I want to connect two separate controllers (or split keyboard) and compete head-to-head with saved player preferences,
So that we can play offline versus matches with our preferred volume and control bindings.

## Acceptance Criteria

1. **Independent 2-Player Input Routing**:
   - Pemain 1 dan Pemain 2 mengendalikan karakter masing-masing tanpa konflik input:
     - Player 1: Gamepad Device 0 atau Keyboard Set A (WASD, J, K, U, I, O, Space).
     - Player 2: Gamepad Device 1 atau Keyboard Set B (Arrow Keys, Numpad 1-6).
   - BaseMecha mendukung pemisahan input ID (`player_index = 1` vs `player_index = 2`) melalui pemetaan `get_player_action()`.

2. **Configuration Persistence Manager (`scripts/core/settings_manager.gd`)**:
   - Menyimpan dan memuat konfigurasi menggunakan `ConfigFile` pada `user://settings.cfg`:
     - Volume Audio: Master (0-100%), BGM (0-100%), SFX (0-100%).
     - Binding tombol input dan preferensi tampilan.
   - Menyediakan fallback default yang aman jika file konfigurasi belum ada atau rusak.

3. **Scene Mode Local 2-Player (`scenes/local_versus_mode.tscn`)**:
   - P1 dan P2 ditempatkan di Arena Skyscraper.
   - Terintegrasi dengan `MatchManager` (Best of 3, 90s timer, Sudden Death) dan `CombatHUD`.
   - P1 dan P2 dikendalikan oleh pemain manusia secara independen.

4. **Main Menu Integration**:
   - Opsi "LOCAL 2P VERSUS" di Main Menu memuat `scenes/local_versus_mode.tscn`.

5. **Automated Testing Suite (`tests/test_local_versus.gd` & `tests/test_local_versus.tscn`)**:
   - Validasi pembacaan dan penulisan `ConfigFile` ke `user://settings.cfg` (save/load/reset default).
   - Validasi pemisahan input per player (P1 input tidak menggerakkan P2, P2 input tidak menggerakkan P1).
   - Validasi struktur scene Local Versus Mode dan integrasi MatchManager.

## Tasks / Subtasks

- [x] Task 1: Configuration & Settings Manager Component (AC: 2)
  - [x] 1.1 Buat `scripts/core/settings_manager.gd` untuk mengelola persistensi `user://settings.cfg`.
- [x] Task 2: Multi-Player Input Mapping & Separation (AC: 1)
  - [x] 2.1 Perbarui `scripts/characters/base_mecha.gd` untuk mendukung `player_index` (P1 vs P2 input actions).
  - [x] 2.2 Daftarkan input map terpisah untuk P2 (`p2_*` via `_setup_p2_input_fallbacks()`).
- [x] Task 3: Local 2P Versus Scene Assembly & Main Menu Wiring (AC: 3, 4)
  - [x] 3.1 Buat `scripts/core/local_versus_manager.gd` untuk mengoordinasi pertandingan 2 pemain.
  - [x] 3.2 Buat `scenes/local_versus_mode.tscn`.
  - [x] 3.3 Hubungkan rute tombol `LOCAL 2P VERSUS` di `scripts/ui/main_menu.gd`.
- [x] Task 4: Automated Testing Suite & Verification (AC: 5)
  - [x] 4.1 Buat `tests/test_local_versus.gd` dan `tests/test_local_versus.tscn`.
  - [x] 4.2 Jalankan pengujian headless (5/5 lulus, 100% pass) dan verifikasi regresi penuh.

## Dev Agent Record

- **Implemented Components**:
  - `scripts/core/settings_manager.gd`: Modul persistensi preferensi user berbasis Godot `ConfigFile` (`user://settings.cfg`) dengan dukungan audio, display, dan kontrol input serta default safe fallbacks.
  - `scripts/characters/base_mecha.gd`: Penambahan properti `player_index`, method perutean `get_player_action(action_name)`, isolasi simulated input per mecha, dan pendaftaran otomatis aksi input Player 2 (`p2_*`).
  - `scripts/core/local_versus_manager.gd`: Coordinator duel 2 pemain lokal pada satu layar terintegrasi dengan MatchManager (BO3, 90s round timer) dan CombatHUD.
  - `scenes/local_versus_mode.tscn`: Scene lengkap Local 2P Versus Mode.
  - `scripts/ui/main_menu.gd`: Perutean opsi "LOCAL 2P VERSUS" ke `scenes/local_versus_mode.tscn`.
  - `tests/test_local_versus.gd` & `tests/test_local_versus.tscn`: Headless test suite (5 pengujian).
- **Test Results**:
  - 5/5 test cases passed headless with 0 errors.
  - Seluruh suite Epic 5 (Story 5.1, 5.2, 5.3, 5.4, 5.5, 5.6) dan regresi core (test_match_rules) lulus 100%.
