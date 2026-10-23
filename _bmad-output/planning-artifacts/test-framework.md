---
title: "Test Framework Specification: Fighting to Zero"
status: complete
engine: "Godot 4.7.2"
created: '2026-10-23'
---

# Test Framework Specification: Fighting to Zero

## 1. Overview & Architecture

Fighting to Zero menerapkan arsitektur pengujian otomatis headless berbasis native Godot 4 Engine yang terintegrasi penuh ke dalam Continuous Verification pipeline proyek. Seluruh logika permainan diuji secara deterministik pada cycle `_physics_process()` (60 FPS) tanpa memerlukan driver eksternal atau window GUI yang terbuka.

### Arsitektur Test Framework:

```
[Master Test Runner: tests/run_all_tests.ps1]
          │
          ├──> Godot Console CLI: Godot_v4.7.2-stable_win64_console.exe --headless
          │         │
          │         ├── Autoload Global Singletons (EventBus, InputBuffer)
          │         │
          │         ├── Isolated Test Suite Scenes (res://tests/test_*.tscn)
          │         │         │
          │         │         ├── Unit Tests (Components, Math, Data Resources)
          │         │         ├── State Machine Tests (Mecha HSM Transitions)
          │         │         ├── Combat & Collision Tests (Area2D Layer Matrix)
          │         │         └── Performance Profiler (RAM & 60 FPS Determinism)
          │         │
          │         └── Exit Code Assertion (0 = PASS, 1 = FAIL)
          │
          └──> Final Report & Diagnostic Telemetry (32/32 Passed)
```

---

## 2. Testing Layers & Directory Structure

Framework pengujian terbagi ke dalam 6 tingkatan verifikasi:

```
tests/
├── run_all_tests.ps1                  # Master test runner PowerShell script
├── test_movement_fsm.gd/.tscn         # Epic 1: Movement & HSM transitions
├── test_input_buffer_coyote.gd/.tscn  # Epic 1: Circular input buffer (5f) & coyote time (5f)
├── test_vector_dash.gd/.tscn          # Epic 1: 8-way jet thruster dash (750 px/s)
├── test_combat_attacks.gd/.tscn       # Epic 1: Normal attacks & hit/hurtbox detection
├── test_heat_component.gd/.tscn       # Epic 2: Heat generation & passive cooling (-12%/s)
├── test_overclock_meltdown.gd/.tscn   # Epic 2: Overclock super armor & Meltdown lockout (90f)
├── test_blocking_chip.gd/.tscn        # Epic 2: Normal blocking & 20% energy chip damage
├── test_spark_parry.gd/.tscn          # Epic 2: Frame-exact parry window (f2-f5) & meter steal
├── test_attack_chain_scaling.gd/.tscn # Epic 3: Target chain damage scaling & bounce limits
├── test_apex_viper.gd/.tscn           # Epic 3: Apex-0 Viper moveset & parameters
├── test_titan_bulwark.gd/.tscn        # Epic 3: Titan-V Bulwark moveset & parameters
├── test_dual_input_system.gd/.tscn    # Epic 3/5: Dual-input autodetect & virtual joystick
├── test_arena_skyscraper.gd/.tscn     # Epic 4: 1280px platform & open boundary detection
├── test_cliffhanger_system.gd/.tscn   # Epic 4: Cliffhanger struggle (120f) & recovery actions
├── test_ledge_stomp_ring_out.gd/.tscn # Epic 4: Downward stomp & instant ring-out
├── test_match_rules.gd/.tscn          # Epic 4: Best of 3 rounds, timers, & sudden death
├── test_combat_hud.gd/.tscn           # Epic 5: Health bars, dynamic heat, & round win counters
├── test_main_menu.gd/.tscn            # Epic 5: Menu navigation, wraps, & scene transitions
├── test_local_versus.gd/.tscn         # Epic 5: Local 2-Player input independence
├── test_versus_ai.gd/.tscn            # Epic 5: Novice/Veteran/Ace difficulty controller
├── test_training_mode.gd/.tscn        # Epic 5: Hitbox overlays & dummy state configurations
├── test_hitstop_screen_shake.gd/.tscn # Epic 6: Local frame-hitstop & camera trauma decay
├── test_pixel_vfx.gd/.tscn            # Epic 6: GPUParticles2D welding sparks & laser glow
├── test_audio_system.gd/.tscn         # Epic 6: 5 AudioServer buses & announcer audio
├── test_performance_stress.gd/.tscn   # Epic 6: Memory baseline & 100-cycle stress profiling
├── test_pixel_sprites_visual.gd/.tscn # Epic 7: 32-bit pixel sprites & visual state syncing
├── test_ghost_trail_and_stage_vfx.gd  # Epic 7: Dash afterimages & dynamic cyber-city background
├── test_synthwave_ost.gd/.tscn        # Epic 8: Synthwave dynamic BGM engine & bus transitions
├── test_mecha_combat_sfx.gd/.tscn     # Epic 8: Thruster dash, alarms, & impact audio pooling
├── test_ray_pulsar.gd/.tscn           # Epic 10: Ray-X Pulsar moveset & photon particles
├── test_character_select.gd/.tscn     # Epic 11: Character Select Screen & factory spawner
└── test_underground_reactor.gd/.tscn  # Epic 12: Underground Reactor & steam vent hazards
```

---

## 3. Test Runner Execution Protocol

Semua suite pengujian dijalankan melalui script `run_all_tests.ps1`:
```powershell
powershell.exe -ExecutionPolicy Bypass -File tests/run_all_tests.ps1
```

Setiap test runner scene:
1. Memuat global `EventBus` dan `InputBuffer` autoload secara otomatis.
2. Menjalankan array `Callable` unit test.
3. Mencatat log diagnosa ke output console dan file hasil pengujian lokal.
4. Memanggil `get_tree().quit(0)` jika seluruh test lulus, atau `get_tree().quit(1)` jika terjadi kegagalan asersi.

Framework ini memastikan **zero-regression** dan stabilitas 60 FPS deterministik sepanjang siklus pengembangan.
