---
baseline_commit: c438df6
---

# Story 5.1: Main Menu & Navigation Flow

Status: review

## Story

As a player,
I want a clean 32-bit styled main menu to select between Versus AI, Training Mode, Local Versus, and Settings,
So that I can seamlessly navigate the game's features.

## Acceptance Criteria

1. **Scene Utama Main Menu (`scenes/main_menu.tscn`)**:
   - Tampilan visual bergaya retro 32-bit pixel arcade bertema cyberpunk New Babel-01 pada kanvas internal 640x360.
   - Judul game "FIGHTING TO ZERO" dengan aksen pendar neon cyber dan ornamen mecha.
   - Terdaftar sebagai scene peluncuran utama di `project.godot` (`run/main_scene="res://scenes/main_menu.tscn"`).

2. **Opsi Menu Navigasi**:
   - Memiliki 5 opsi navigasi utama:
     1. `VERSUS AI`: Melawan bot mecha dengan opsi profil kesulitan.
     2. `TRAINING MODE`: Laboratorium latihan frame data dan kombo.
     3. `LOCAL 2P VERSUS`: Duel lokal 2 pemain di arena panggung.
     4. `SETTINGS`: Panel konfigurasi audio dan tampilan.
     5. `EXIT`: Keluar dari permainan (dengan konfirmasi).

3. **Dukungan Multi-Input Responsif**:
   - Navigasi penuh melalui **Gamepad** (D-Pad Atas/Bawah, Joypad Stick Atas/Bawah, Tombol Konfirmasi / A, Tombol Kembali / B).
   - Navigasi penuh melalui **Keyboard** (Arrow Keys, W/S, Enter / Space untuk memilih, Escape untuk kembali).
   - Dukungan **Touchscreen & Mouse** (hover highlight, tap/click langsung pada tombol menu).

4. **Visual Focus Highlight & Audio Feedback (SFX)**:
   - Tombol aktif mendapatkan visual focus highlight (perubahan warna neon, pembesaran skala halus, dan indikator cursor `> [ OPTION ] <`).
   - Efek suara sintesis prosedural / SFX konfirmasi dan SFX perpindahan navigasi diputar saat kursor berpindah dan saat opsi ditekan.

5. **Transisi Scene (< 3.0 Detik)**:
   - Transisi fade-out/fade-in yang mulus (< 0.5 detik, memenuhi kriteria < 3.0 detik) saat berpindah dari Main Menu menuju scene gameplay arena (`res://scenes/arena_skyscraper.tscn`) atau scene target lainnya.

6. **Automated Testing Suite**:
   - Dibuat `tests/test_main_menu.gd` dan `tests/test_main_menu.tscn`.
   - Validasi inisialisasi scene dan ketersediaan 5 opsi menu.
   - Validasi fokus awal berada pada opsi pertama (`VERSUS AI`).
   - Validasi pergerakan fokus navigasi ke bawah, ke atas, dan siklus wrap-around.
   - Validasi pemilihan opsi memicu sinyal / penanganan yang sesuai.
   - Validasi transisi scene berjalan di bawah ambang 3.0 detik.

## Tasks / Subtasks

- [x] Task 1: UI Theme, Sound Effects & Audio Synthesizer (AC: 1, 4)
  - [x] 1.1 Buat generator suara prosedural ringan (`scripts/ui/menu_audio.gd`) untuk nada navigasi (beep) dan konfirmasi (chime).
- [x] Task 2: Main Menu Controller & Script (AC: 2, 3, 4, 5)
  - [x] 2.1 Buat `scripts/ui/main_menu.gd` mengelola state menu, indeks navigasi, input event (Gamepad/Keyboard/Touch), focus highlights, dan transisi layar.
  - [x] 2.2 Hubungkan sinyal ke `EventBus.game_mode_selected` dan transisi scene.
- [x] Task 3: Desain Scene Visual 32-bit `scenes/main_menu.tscn` (AC: 1, 2, 3, 5)
  - [x] 3.1 Bangun struktur UI kanvas 640x360 dengan latar belakang skyscraper fog, logo pendar neon, dan daftar tombol navigasi.
  - [x] 3.2 Tambahkan overlay transisi layar ColorRect (Fade CanvasLayer).
  - [x] 3.3 Set `run/main_scene` di `project.godot` ke `res://scenes/main_menu.tscn`.
- [x] Task 4: Automated Testing Suite (AC: 6)
  - [x] 4.1 Buat `tests/test_main_menu.gd` dan `tests/test_main_menu.tscn`.
  - [x] 4.2 Uji seluruh skenario inisialisasi, pergerakan fokus, aktivasi opsi, input handling, dan kecepatan transisi.

## Dev Agent Record

### Debug Log
- Terdeteksi bahwa lambda closures pada GDScript 4 menangkap variabel tipe primitif (`int`, `StringName`, `bool`) secara copy/value. Masalah diselesaikan menggunakan container referensi `Dictionary` pada callback signal assertions.
- Diidentifikasi fungsi duplikat `get_horizontal_axis()` pada `scripts/characters/base_mecha.gd:563` dari session sebelumnya; digabungkan dan dibersihkan sehingga seluruh suite regresi lulus tanpa error.

### Completion Notes List
- Dibuat scene utama `scenes/main_menu.tscn` dengan estetika arcade mecha 32-bit retro pada resolusi 640x360.
- Dibuat script pengendali `scripts/ui/main_menu.gd` yang mendukung navigasi Gamepad, Keyboard (Arrow/WASD/Enter/Escape), serta Layar Sentuh / Mouse.
- Ditambahkan 5 opsi menu utama: VERSUS AI, TRAINING MODE, LOCAL 2P VERSUS, SETTINGS, dan EXIT.
- Diimplementasikan generator audio prosedural 32-bit retro `scripts/ui/menu_audio.gd` (nav beep, confirm chime, cancel buzz) yang mandiri tanpa dependensi aset eksternal.
- Ditambahkan sinyal game flow global di `EventBus` (`game_mode_selected`, `menu_navigated`).
- Dikonfigurasi transisi layar mulus (< 0.5s) dan didaftarkan sebagai `run/main_scene` di `project.godot`.
- Suite automated test `tests/test_main_menu.gd` lulus 7/7 (100%).

### File List
- scripts/ui/menu_audio.gd (baru)
- scripts/ui/main_menu.gd (baru)
- scenes/main_menu.tscn (baru)
- scripts/core/event_bus.gd (diperbarui)
- scripts/characters/base_mecha.gd (dibersihkan duplikat fungsi)
- project.godot (diperbarui main_scene)
- tests/test_main_menu.gd (baru)
- tests/test_main_menu.tscn (baru)
- tests/test_match_rules.gd (diperbarui closure assertions)
- _bmad-output/implementation-artifacts/5-1-main-menu-navigation-flow.md (baru)
- _bmad-output/implementation-artifacts/sprint-status.yaml (diperbarui)

### Change Log
- 2026-10-20: Implementasi Story 5.1 Main Menu & Navigation Flow selesai dan lulus validasi 7/7, status review.
