---
baseline_commit: 527f438
---

# Story 4.2: Cliffhanger Struggle State Machine & Actions

Status: review

## Story

As a player knocked off the platform edge,
I want my mecha to grab the ledge for 2 seconds and choose between climbing back or sweeping the opponent,
So that I have a thrilling last-second chance to recover or reverse the momentum.

## Acceptance Criteria

1. **Aktivasi Otomatis & Batasan Ronde**:
   - Mecha yang terhempas ke luar platform (sensor tebing X < 64 atau X > 1344) dan memiliki HP > 0 otomatis mencengkeram bibir tebing dan memasuki `CliffhangerState`.
   - Dibatasi maksimal 1 kali aktivasi per ronde (`CombatConstants.CLIFFHANGER_MAX_GRAB_COUNT = 1`).
   - Mecha diorientasikan menghadap ke dalam arena:
     - Tebing kiri (X = 64): Hadap kanan (`facing_direction = 1`).
     - Tebing kanan (X = 1344): Hadap kiri (`facing_direction = -1`).
   - Mecha berhenti meluncur (`velocity = Vector2.ZERO`).

2. **Jendela Waktu Bergelantungan (120 Frame / 2.0 Detik)**:
   - Timer gantung berjalan selama 120 frame (`CombatConstants.CLIFFHANGER_HANG_TIME_FRAMES = 120`).
   - Mecha dapat memilih salah satu dari 3 aksi strategis.

3. **Aksi 1: Climb-Up Jump**:
   - Dipicu oleh tombol `jump`, `ui_up`, atau `move_up`.
   - Durasi startup 18 frame (`CombatConstants.CLIFFHANGER_CLIMB_STARTUP_FRAMES = 18`).
   - Setelah 18 frame, mecha melompat kembali ke atas panggung (X bergeser ke dalam arena sejauh 80 px) dan beralih ke `IdleState`.

4. **Aksi 2: Ledge Sweep Attack**:
   - Dipicu oleh tombol `attack_light` atau `attack_heavy`.
   - Durasi: Startup 12 frame, Active 4 frame, Recovery 16 frame.
   - Mengaktifkan hitbox berdamage 10% (`CombatConstants.CLIFFHANGER_SWEEP_DAMAGE = 100`) dengan keunggulan -2 frame on block.
   - Setelah siklus selesai, mecha meluncur ke atas panggung dan beralih ke `IdleState`.

5. **Aksi 3: Drop Fall (Manual / Timeout)**:
   - Dipicu oleh tombol bawah (`ui_down` / `move_down`) atau saat timer 120 frame habis.
   - Mecha melepaskan cengkeraman dari tebing dan memasuki `FallState` menuju batas Ring Out.

6. **Automated Testing Suite**:
   - Dibuat `tests/test_cliffhanger_system.gd` dan `tests/test_cliffhanger_system.tscn`.
   - Validasi aktivasi dan orientasi arah hadap bibir tebing.
   - Validasi limit maksimal 1 kali aktivasi per ronde.
   - Validasi transisi Climb-Up Jump (18 frame startup).
   - Validasi transisi Ledge Sweep Attack (12 frame startup, hitbox aktif).
   - Validasi transisi Drop Fall (manual input dan timer habis).

## Tasks / Subtasks

- [x] Task 1: CliffhangerState FSM & Constants (AC: 1, 2)
  - [x] 1.1 Definisikan konstanta CLIFFHANGER di `combat_constants.gd`.
  - [x] 1.2 Buat `scripts/combat/fsm/cliffhanger_state.gd` mewarisi `BaseState`.
  - [x] 1.3 Implementasikan snap posisi ke X=64 (kiri) dan X=1344 (kanan) dengan orientasi hadap ke arena.
- [x] Task 2: Implementasi 3 Pilihan Aksi (AC: 3, 4, 5)
  - [x] 2.1 Implementasikan *Climb-Up Jump* (Startup 18f -> Idle di panggung).
  - [x] 2.2 Implementasikan *Ledge Sweep Attack* (Startup 12f, hitbox 4f, damage 100 -> Idle di panggung).
  - [x] 2.3 Implementasikan *Drop Fall* (Input bawah / timeout 120f -> FallState).
- [x] Task 3: Integrasi BaseMecha & Skyscraper Arena (AC: 1)
  - [x] 3.1 Tambahkan `cliffhanger_grabs_used`, `can_cliffhanger()`, `trigger_cliffhanger()` di `BaseMecha`.
  - [x] 3.2 Sambungkan `ArenaSkyscraper.notify_ledge_cross()` untuk memanggil `trigger_cliffhanger()`.
- [x] Task 4: Automated Testing Suite (AC: 6)
  - [x] 4.1 Buat `tests/test_cliffhanger_system.gd` dan `tests/test_cliffhanger_system.tscn`.
  - [x] 4.2 Uji seluruh skenario transisi dan batas maksimal per ronde.
