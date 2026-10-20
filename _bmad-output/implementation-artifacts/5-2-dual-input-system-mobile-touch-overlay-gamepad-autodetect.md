---
baseline_commit: 2dfdcd9
---

# Story 5.2: Dual-Input System (Mobile Touch Overlay & Gamepad Autodetect)

Status: review

## Story

As a player on PC or mobile,
I want native support for keyboard, Xbox/PlayStation controllers, and a dynamic floating virtual touch joystick with 6 ergonomic action buttons,
So that I enjoy an equally responsive, tournament-ready control experience on any device.

## Acceptance Criteria

1. **Dynamic Floating Virtual Joystick (`scripts/ui/virtual_joystick.gd`)**:
   - Area deteksi sentuhan mencakup sisi kiri layar (X <= 50% lebar layar).
   - Saat jempol pertama kali menyentuh layar di area kiri, dasar joystick (*base*) otomatis berpindah ke posisi sentuhan tersebut (*dynamic floating*).
   - Handle joystick mengikuti pergerakan seret jempol (*drag*) dalam radius maksimum 48–60 piksel, dan menghitung vektor arah 8-arah ternormalisasi.
   - Memicu pembaruan aksi pergerakan `move_left`, `move_right`, `move_up`, `move_down` secara analog/deterministik.
   - Saat sentuhan dilepas, handle kembali ke titik pusat.

2. **Tata Letak 6-Tombol Sentuh Ergonomis Mobile (`scenes/touch_controls_overlay.tscn`)**:
   - Area kontrol kanan memuat 6 tombol aksi sentuh yang nyaman untuk jempol kanan:
     1. `NORMAL`: Serangan biasa mecha (memetakan ke aksi `attack_light`).
     2. `DASH`: Dorongan jet 8-arah (memetakan ke aksi `dash`).
     3. `SKILL 1`: Serangan spesial mecha 1 (memetakan ke aksi `skill1`).
     4. `SKILL 2`: Serangan spesial mecha 2 (memetakan ke aksi `skill2`).
     5. `PARRY`: Tangkisan presisi Spark Parry (memetakan ke aksi `parry`).
     6. `ULTIMATE`: Protokol serangan puncak Overclock/Ultimate (memetakan ke aksi `ultimate`).
   - Setiap tombol memiliki umpan balik visual sentuh (modulasi pendar neon dan reduksi skala saat ditekan).

3. **Autodeteksi Gamepad & Manajemen Mode Input (`scripts/core/input_mode_manager.gd`)**:
   - Sistem memantau event koneksi gamepad (`Input.joy_connection_changed`) dan aktivitas event masukan (`InputEventJoypadButton`, `InputEventJoypadMotion`, `InputEventKey`, `InputEventScreenTouch`).
   - Saat kontroler fisik terdeteksi aktif pada PC, overlay sentuh disembunyikan secara otomatis (`visible = false`).
   - Saat event layar sentuh terjadi (atau berjalan di platform Android/iOS), overlay sentuh otomatis dimunculkan (`visible = true`).
   - Sinyal `input_mode_changed(mode: StringName)` dipancarkan saat berganti antara mode `&"touch"` dan `&"gamepad_keyboard"`.

4. **Konfigurasi Input Actions di `project.godot`**:
   - Ditambahkan mapping lengkap untuk aksi `skill1`, `skill2`, `parry`, dan `ultimate` baik pada keyboard maupun controller joypad standar (Xbox/PS).

5. **Automated Testing Suite**:
   - Dibuat `tests/test_dual_input_system.gd` dan `tests/test_dual_input_system.tscn`.
   - Validasi instansiasi overlay sentuh dan ketersediaan floating joystick serta 6 tombol aksi.
   - Validasi aktivasi floating joystick pada zona kiri layar dan perpindahan titik jangkar (*anchor reposition*).
   - Validasi kalkulasi vektor drag dan emisi arah input.
   - Validasi emisi event aksi dari ke-6 tombol sentuh (`attack_light`, `dash`, `skill1`, `skill2`, `parry`, `ultimate`).
   - Validasi autodeteksi switching mode input (Touch vs Gamepad/Keyboard).

## Tasks / Subtasks

- [x] Task 1: Pemetaan Input Actions Lengkap di `project.godot` (AC: 4)
  - [x] 1.1 Daftarkan action `skill1`, `skill2`, `parry`, dan `ultimate` dengan mapping Keyboard dan Joypad.
- [x] Task 2: Implementasi Dynamic Floating Virtual Joystick (AC: 1)
  - [x] 2.1 Buat `scripts/ui/virtual_joystick.gd` mengelola touch down, drag radius, vektor arah, dan pelepasan sentuhan.
- [x] Task 3: Implementasi 6-Button Ergonomic Mobile Touch Overlay (AC: 2, 3)
  - [x] 3.1 Buat scene `scenes/touch_controls_overlay.tscn` dan script pengendali `scripts/ui/touch_controls_overlay.gd`.
  - [x] 3.2 Pasang 6 tombol aksi dengan visual style cyberpunk retro.
  - [x] 3.3 Integrasikan autodeteksi gamepad dan auto-hide pada kontroler PC.
- [x] Task 4: Automated Testing Suite (AC: 5)
  - [x] 4.1 Buat `tests/test_dual_input_system.gd` dan `tests/test_dual_input_system.tscn`.
  - [x] 4.2 Uji seluruh skenario joystick drag, pemetaan 6 tombol sentuh, dan autodeteksi gamepad.

## Dev Agent Record

### Debug Log
- Teridentifikasi bahwa identifier `VirtualJoystick` membayangi native class internal pada Godot Engine 4.7+, sehingga nama kelas diganti menjadi `FloatingVirtualJoystick` untuk stabilitas kompilasi.
- Seluruh assertions sinyal dan mode switching menggunakan preloaded script constants untuk menghindari parse dependency resolution delay.

### Completion Notes List
- Dibuat komponen `FloatingVirtualJoystick` (`scripts/ui/virtual_joystick.gd`) dengan kemampuan *dynamic floating* saat pertama kali disentuh pada separuh kiri layar (X <= 50%).
- Menghitung vektor seret 8-arah ternormalisasi dalam radius 48px dan memicu pembaruan aksi pergerakan `move_left`, `move_right`, `move_up`, `move_down`.
- Dibuat scene `scenes/touch_controls_overlay.tscn` dan pengendali `scripts/ui/touch_controls_overlay.gd` dengan 6 tombol aksi ergonomis: `ATK` (attack_light), `DASH` (dash), `SKL 1` (skill1), `SKL 2` (skill2), `PARRY` (parry), dan `ULTI` (ultimate).
- Diimplementasikan autodeteksi gamepad/keyboard di PC dengan auto-hide overlay sentuh, serta auto-show saat event layar sentuh terdeteksi atau di mobile.
- Dikonfigurasi mapping action baru di `project.godot` (`skill1`, `skill2`, `parry`, `ultimate`).
- Suite automated test `tests/test_dual_input_system.gd` lulus 5/5 (100%), dan regresi `test_main_menu.gd` & `test_match_rules.gd` lulus 100%.

### File List
- scripts/ui/virtual_joystick.gd (baru)
- scripts/ui/touch_controls_overlay.gd (baru)
- scenes/touch_controls_overlay.tscn (baru)
- project.godot (diperbarui input actions)
- tests/test_dual_input_system.gd (baru)
- tests/test_dual_input_system.tscn (baru)
- _bmad-output/implementation-artifacts/5-2-dual-input-system-mobile-touch-overlay-gamepad-autodetect.md (baru)
- _bmad-output/implementation-artifacts/sprint-status.yaml (diperbarui)

### Change Log
- 2026-10-20: Implementasi Story 5.2 Dual-Input System selesai dan lulus validasi 5/5, status review.
