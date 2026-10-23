---
baseline_commit: 3e47c77
---

# Story 10.1: Ray-X "Pulsar" Zoner Character Implementation

Status: done

## Story

As a player who prefers long-range zoning, spatial traps, and beam artillery,
I want to play as Ray-X Pulsar with photon railguns, floating disrupter drone pods, and the 360-degree Supernova shockwave,
So that I can control arena space, deny aggressive rushes, and control the edge from a safe distance.

## Acceptance Criteria

1. **Character Constants & Baseline Stats (`scripts/combat/combat_constants.gd`)**:
   - `PULSAR_MAX_HP = 950`
   - `PULSAR_WALK_SPEED = 300.0`
   - `PULSAR_DASH_SPEED = 720.0`
   - `PULSAR_DASH_DURATION_FRAMES = 14`
   - `PULSAR_RAILGUN_DAMAGE = 110`
   - `PULSAR_RAILGUN_HEAT_COST = 25.0`
   - `PULSAR_DRONE_DURATION_FRAMES = 120`
   - `PULSAR_DRONE_HEAT_COST = 20.0`
   - `PULSAR_SUPERNOVA_DAMAGE = 380`

2. **Attack Resources (`resources/attacks/`)**:
   - `resources/attacks/pulsar_pulse.tres`: Light Plasma Burst (Startup 5f, Active 3f, Recovery 10f, Damage 55, Heat +8%)
   - `resources/attacks/pulsar_lance.tres`: Long-reach Beam Lance (Startup 10f, Active 4f, Recovery 15f, Damage 95, Heat +14%)
   - `resources/attacks/pulsar_photon_railgun.tres`: Linear Beam (Startup 12f, Active 6f, Recovery 18f, Damage 110, Heat +25%)
   - `resources/attacks/pulsar_disrupter_drone.tres`: Drone Deploy (Startup 14f, Active 10f, Recovery 16f, Damage 70, Heat +20%)
   - `resources/attacks/pulsar_supernova.tres`: 360° Shockwave (Startup 18f, Active 8f, Recovery 24f, Damage 380, Invulnerable Startup)

3. **Character Controller (`scripts/characters/ray_pulsar.gd`)**:
   - Extends `BaseMecha`, binds move resources, sets archetype `&"pulsar"`.
   - Menangani eksekusi Photon Railgun, Drone Deploy, dan Supernova.

4. **Visual & Sprites Integration (`scripts/visual/mecha_pixel_sprite.gd` & `scripts/visual/vfx_ghost_trail.gd`)**:
   - Warna palet 32-bit: Obsidian chassis (#1F1433), Violet armor (#A64DFF), Lavender highlight (#D9A6FF), Golden amber visor (#FFE633).
   - Afterimage dash warna ungu/magenta glowing trail.

5. **Automated Verification Suite (`tests/test_ray_pulsar.gd` & `.tscn`)**:
   - Memvalidasi inisialisasi Ray-X Pulsar (HP: 950, Walk: 300, Dash: 720).
   - Memvalidasi seluruh AttackData resources.
   - Memvalidasi eksekusi normal attacks, Photon Railgun, Disrupter Drone, dan Supernova.
   - Menjamin 29 test suites sebelumnya tetap 100% lulus.

## Tasks / Subtasks

- [x] Task 1: Constants & Attack Resources (AC: 1, 2)
  - [x] 1.1 Tambahkan konstanta PULSAR di `scripts/combat/combat_constants.gd`
  - [x] 1.2 Buat file `.tres` serangan Pulsar di `resources/attacks/`
- [x] Task 2: Visual Integration (AC: 4)
  - [x] 2.1 Tambahkan palet & siluet Pulsar di `scripts/visual/mecha_pixel_sprite.gd`
  - [x] 2.2 Tambahkan trail color Pulsar di `scripts/visual/vfx_ghost_trail.gd`
- [x] Task 3: Character Implementation (AC: 3)
  - [x] 3.1 Buat `scripts/characters/ray_pulsar.gd`
- [x] Task 4: Automated Testing & Verification (AC: 5)
  - [x] 4.1 Buat `tests/test_ray_pulsar.gd` dan `tests/test_ray_pulsar.tscn`
  - [x] 4.2 Daftarkan di `tests/run_all_tests.ps1` dan jalankan master suite
