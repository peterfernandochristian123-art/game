---
baseline_commit: 18a5729
---

# Story 5.4: Training Mode Suite with Real-Time Frame Inspector

Status: review

## Story

As a competitive player or lab enthusiast,
I want an interactive Training Mode with visual hitbox overlays, dummy behavior toggles, and real-time frame data inspection,
So that I can practice combos, study frame advantage, and master parry timing.

## Acceptance Criteria

1. **Collision Debug Overlay (F1 / Touch Toggle)**:
   - Menampilkan visualisasi kotak tumbukan akurat dengan kode warna standar fighting game:
     - **Merah (Red)**: Strike & Grab Hitbox (Area2D Layer 3/4).
     - **Hijau (Green)**: Hurtbox karakter (Area2D Layer 2).
     - **Biru (Blue)**: Pushbox fisik (CollisionShape2D Layer 1) dan Ledge Sensors (Layer 5).
   - Dapat diaktifkan/dinonaktifkan secara instan menggunakan tombol **F1** (atau tombol toggle sentuh pada UI).

2. **On-Screen Real-Time Frame Inspector**:
   - Menampilkan metrik frame data serangan pemain saat mengeksekusi jurus:
     - *Move Name* (misal: "5L Light Rapier", "5H Heavy Beam", "Blink Slash").
     - *Startup Frames* (durasi sebelum hitbox aktif).
     - *Active Frames* (durasi hitbox aktif memberi damage).
     - *Recovery Frames* (durasi pemulihan sebelum mecha kembali actionable).
     - *Frame Advantage on Hit* (keuntungan frame saat serangan mendarat).
     - *Frame Advantage on Block* (keuntungan frame saat serangan ditahan lawan).
     - *Damage & Heat Generated*.

3. **Menu Konfigurasi Dummy & Kontrol Perilaku (F2 Menu)**:
   - Memungkinkan pemain memilih status perilaku target dummy mecha:
     1. `STAND`: Dummy berdiri diam (idle), menerima kombo penuh untuk latihan hit-confirm.
     2. `CROUCH`: Dummy berada dalam status jongkok.
     3. `BLOCK_ALL`: Dummy selalu bertahan (auto-block) saat diserang, memicu blockstun dan chip damage.
     4. `RANDOM_PARRY`: Dummy mengeksekusi Spark Parry secara berkala/acak untuk menguji parry baiting.
   - Menu dapat dibuka/ditutup menggunakan tombol **F2** atau toolbar GUI interaktif.

4. **Reset Posisi Seketika (F3 Shortcut)**:
   - Tombol **F3** (atau tombol Reset GUI) memposisikan ulang kedua mecha seketika ke titik awal panggung (P1 di X=500, P2 di X=900), memulihkan HP ke 100%, mereset kombo, dan mengembalikan suhu Heat ke 0%.

5. **Scene Mode Latihan (`scenes/training_mode.tscn`)**:
   - Mengintegrasikan panggung arena skyscraper, mecha petarung, dummy controller, HUD pertarungan, panel Frame Inspector, dan overlay debug hitbox.

6. **Automated Testing Suite**:
   - Dibuat `tests/test_training_mode.gd` dan `tests/test_training_mode.tscn`.
   - Validasi inisialisasi scene Training Mode dan komponen-komponennya.
   - Validasi toggle F1 mengaktifkan/menonaktifkan overlay visual kotak tumbukan.
   - Validasi pencatatan dan display Frame Inspector saat jurus dieksekusi.
   - Validasi pergantian mode dummy (STAND, CROUCH, BLOCK_ALL, RANDOM_PARRY).
   - Validasi shortcut Reset F3 memulihkan HP, Heat, dan posisi petarung.

## Tasks / Subtasks

- [x] Task 1: Hitbox & Collision Visualizer Component (AC: 1)
  - [x] 1.1 Buat `scripts/training/collision_debug_overlay.gd` untuk menggambar kotak bounding box berwarna (Merah, Hijau, Biru).
- [x] Task 2: Real-Time Frame Inspector Component (AC: 2)
  - [x] 2.1 Buat `scripts/training/frame_inspector.gd` untuk menangkap dan menampilkan data frame jurus (startup, active, recovery, advantage).
- [x] Task 3: Dummy Controller & Behavior States (AC: 3, 4)
  - [x] 3.1 Buat `scripts/training/training_dummy_controller.gd` mendukung Stand, Crouch, Block All, Random Parry, dan Quick Reset (F3).
- [x] Task 4: Training Mode Scene Assembly & Main Menu Wiring (AC: 5)
  - [x] 4.1 Buat `scenes/training_mode.tscn` menggabungkan Arena, P1, Dummy, HUD, Inspector, dan Collision Overlay.
  - [x] 4.2 Hubungkan rute tombol Training Mode di `scripts/ui/main_menu.gd` ke `scenes/training_mode.tscn`.
- [x] Task 5: Automated Testing Suite & Verification (AC: 6)
  - [x] 5.1 Buat `tests/test_training_mode.gd` dan `tests/test_training_mode.tscn`.
  - [x] 5.2 Jalankan pengujian headless (5/5 lulus, 100% pass).

## Dev Agent Record

- **Implemented Components**:
  - `scripts/training/collision_debug_overlay.gd`: CanvasItem custom drawing visualizer untuk Hitbox (Merah), Hurtbox (Hijau), dan Pushbox/Ledge (Biru). Menggunakan shortcut F1 dan API `toggle_overlay()`.
  - `scripts/training/frame_inspector.gd`: Real-time GUI panel yang mengkalkulasi startup, active, recovery, advantage on hit/block, damage, dan heat gain.
  - `scripts/training/training_dummy_controller.gd`: Pengontrol status latihan dummy (STAND, CROUCH, BLOCK_ALL, RANDOM_PARRY) dan quick reset F3.
  - `scripts/training/training_manager.gd`: Coordinator scene lab yang mengikat P1, Dummy, HUD, Inspector, dan toolbar input sentuh / shortcut keyboard.
  - `scenes/training_mode.tscn`: Scene lengkap Training Mode.
  - `tests/test_training_mode.gd` & `tests/test_training_mode.tscn`: Headless test suite (5 pengujian).
- **Test Results**:
  - 5/5 test cases passed headless with 0 errors.
  - All regression suites (test_combat_hud, test_dual_input_system, test_main_menu, test_match_rules) passed 100%.
