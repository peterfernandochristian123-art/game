---
baseline_commit: 2d4e165
---

# Story 4.1: Zero-G Skyscraper Platform & Arena Boundaries

Status: review

## Story

As a player,
I want to fight on an elevated platform suspended high above New Babel-01 without boundary walls,
So that arena positioning and edge awareness are essential tactical elements of the fight.

## Acceptance Criteria

1. **Scene Panggung `scenes/arena_skyscraper.tscn`**:
   - Platform baja selebar 1280 piksel (`CombatConstants.ARENA_PLATFORM_WIDTH = 1280.0`).
   - Lantai platform berbasis `StaticBody2D` pada Collision Layer 1 (World).
   - Titik tengah platform pada X = 704.0, membentang dari X = 64.0 (`CombatConstants.ARENA_LEFT_BOUND`) hingga X = 1344.0 (`CombatConstants.ARENA_RIGHT_BOUND`).
   - Sisi kiri dan kanan terbuka penuh tanpa dinding pembatas (open boundaries).

2. **Deteksi Sensor Ledge (Tubir Jurang)**:
   - Sensor tubir kiri (`LeftLedgeSensor`) mendeteksi mecha saat melayang di X < 64.
   - Sensor tubir kanan (`RightLedgeSensor`) mendeteksi mecha saat melayang di X > 1344.
   - Saat terdeteksi, memancarkan sinyal `ledge_reached(mecha, side)` dan memberitahukan `EventBus.cliffhanger_triggered(mecha_id, side)`.

3. **Background & Visual Estetika (GDD §5.5)**:
   - Pemandangan kota metropolitan neo-cyberpunk *New Babel-01* dengan siluet gedung pencakar langit megah dan awan kabut atmosfer.
   - Garis marka bahaya (Hazard Stripes) kuning di kedua ujung platform (X = 64 dan X = 1344).

4. **Automated Testing Suite**:
   - Dibuat `tests/test_arena_skyscraper.gd` dan `tests/test_arena_skyscraper.tscn`.
   - Validasi dimensi platform 1280 px pada Layer 1 World.
   - Validasi batas X = 64.0 dan X = 1344.0 serta fungsi utilitas `is_within_platform()`.
   - Validasi emisi sinyal deteksi ledge saat mecha melayang di luar batas platform.

## Tasks / Subtasks

- [x] Task 1: Arena Skyscraper Script & Boundaries Controller (AC: 1, 2)
  - [x] 1.1 Buat `scripts/arena/arena_skyscraper.gd` mewarisi `Node2D`.
  - [x] 1.2 Implementasikan monitoring petarung dan deteksi batas X < 64 dan X > 1344.
  - [x] 1.3 Sambungkan sinyal `ledge_reached` ke `EventBus.cliffhanger_triggered`.
- [x] Task 2: Panggung Arena & Desain Visual (AC: 1, 3)
  - [x] 2.1 Buat scene `scenes/arena_skyscraper.tscn`.
  - [x] 2.2 Pasang `StaticBody2D` selebar 1280 px dengan marka tepi hazard.
  - [x] 2.3 Pasang `Area2D` sensor kiri dan kanan untuk mendeteksi mecha di tubir jurang.
  - [x] 2.4 Atur background skyline New Babel-01 dan atmospheric fog.
- [x] Task 3: Automated Test Suite (AC: 4)
  - [x] 3.1 Buat `tests/test_arena_skyscraper.gd` dan `tests/test_arena_skyscraper.tscn`.
  - [x] 3.2 Uji dimensi platform, collision layer, boundary check, dan sinyal ledge cross.
