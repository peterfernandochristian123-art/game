---
title: "Test Design Specification: Fighting to Zero"
status: complete
created: '2026-10-23'
---

# Test Design Specification: Fighting to Zero

## 1. Quality Gates & Objectives

Test design ini memetakan seluruh matriks verifikasi terhadap fungsionalitas dan performa game *Fighting to Zero*, menjamin kepatuhan pada GDD, Arsitektur, dan Epics.

### Metrik Keberhasilan (Quality Gates):
- **Unit & Integration Pass Rate**: 100% (32 dari 32 test suites lulus).
- **Physics Determinism**: 60 FPS deterministik pada `_physics_process()`.
- **Memory Boundary**: RAM < 600 MB (Baseline pengujian: ~27–32 MB).
- **Crash Rate**: 0 crash selama 100 siklus pertarungan berkelanjutan.

---

## 2. Test Catalog Matrix (32 Test Suites)

| ID | Test Suite Scene | Scope Verifikasi | Kategori | Hasil |
| :--- | :--- | :--- | :--- | :--- |
| **TS-01** | `test_movement_fsm.tscn` | Transisi status FSM (Idle, Walk, Jump, Fall) & kecepatan | Core Physics | **LULUS** |
| **TS-02** | `test_input_buffer_coyote.tscn` | Circular buffer 5 frame (83.3 ms) & coyote time 5f | Input Engine | **LULUS** |
| **TS-03** | `test_vector_dash.tscn` | 8-way dash 750 px/s, durasi 14f, cooldown 18f | Movement | **LULUS** |
| **TS-04** | `test_combat_attacks.tscn` | Startup, active frames hitbox (Layer 3), hurtbox (Layer 2) | Combat Base | **LULUS** |
| **TS-05** | `test_heat_component.tscn` | Pertambahan panas aksi & pendinginan pasif -12%/s | Thermal System | **LULUS** |
| **TS-06** | `test_overclock_meltdown.tscn` | Overclock buff (+20% dmg, armor) & Meltdown shutdown 90f | Thermal System | **LULUS** |
| **TS-07** | `test_blocking_chip.tscn` | Normal blocking 100% & chip damage skill energi 20% | Defense | **LULUS** |
| **TS-08** | `test_spark_parry.tscn` | Window parry aktif f2-f5, hitstop 12f, -20% heat, +15% ulti | Defense | **LULUS** |
| **TS-09** | `test_attack_chain_scaling.tscn` | Target chain cancel, damage scaling (100%->25%), max 1 bounce | Combo System | **LULUS** |
| **TS-10** | `test_apex_viper.tscn` | Archetype Rushdown, Blink Slash, Deflection Matrix, Ulti | Roster Kit | **LULUS** |
| **TS-11** | `test_titan_bulwark.tscn` | Archetype Grappler, Hydraulic Piledriver, Riot Shield, Ulti | Roster Kit | **LULUS** |
| **TS-12** | `test_dual_input_system.tscn` | Floating touch joystick mobile & gamepad autodetect | Input Engine | **LULUS** |
| **TS-13** | `test_arena_skyscraper.tscn` | Platform 1280px & sensor batas tubir tebing (X<64, X>1344) | Arena | **LULUS** |
| **TS-14** | `test_cliffhanger_system.tscn` | Cliffhanger struggle 120f, Climb-Up, Ledge Sweep, Drop | Edge Tension | **LULUS** |
| **TS-15** | `test_ledge_stomp_ring_out.tscn` | Injakan Ledge Stomp (Startup 15f) pemicu instan Ring-Out | Edge Tension | **LULUS** |
| **TS-16** | `test_match_rules.tscn` | Format Best of 3 rounds, timer 90s, sudden death 30s | Match Rules | **LULUS** |
| **TS-17** | `test_combat_hud.tscn` | HP bar, Heat dynamic color (Nominal/Overclock/Meltdown) | UI/UX | **LULUS** |
| **TS-18** | `test_main_menu.tscn` | Navigasi menu utama, focus wraparound, transisi <3.0s | UI/UX | **LULUS** |
| **TS-19** | `test_local_versus.tscn` | Dukungan 2-Player lokal tanpa konflik input controller | Game Modes | **LULUS** |
| **TS-20** | `test_versus_ai.tscn` | Bot AI profil Novice, Veteran, dan Ace (parry frame 6) | Artificial Intel | **LULUS** |
| **TS-21** | `test_training_mode.tscn` | Overlay hitbox/hurtbox (F1) & dummy mode controller (F2) | Training Mode | **LULUS** |
| **TS-22** | `test_hitstop_screen_shake.tscn` | Freeze frame hitstop lokal & guncangan trauma kamera | Juice / Feel | **LULUS** |
| **TS-23** | `test_pixel_vfx.tscn` | Partikel las percikan api, jejak neon, & distorsi uap | Visual VFX | **LULUS** |
| **TS-24** | `test_audio_system.tscn` | 5 AudioServer bus (Master, BGM, SFX, Announcer, Voice) | Audio System | **LULUS** |
| **TS-25** | `test_performance_stress.tscn` | Memory audit & 100 siklus benturan beban kerja berkelanjutan | Performance | **LULUS** |
| **TS-26** | `test_pixel_sprites_visual.tscn` | Sprite visual petarung, pose animasi, & hit flash | Visual Art | **LULUS** |
| **TS-27** | `test_ghost_trail_and_stage_vfx.tscn`| Dash ghost shadow trails & dynamic cyber-city background | Visual VFX | **LULUS** |
| **TS-28** | `test_synthwave_ost.tscn` | Synthwave BGM loop, crossfade audio, & volume persisten | Audio OST | **LULUS** |
| **TS-29** | `test_mecha_combat_sfx.tscn` | Jet thruster dash SFX, heat warning sirens, impact pool | Audio SFX | **LULUS** |
| **TS-30** | `test_ray_pulsar.tscn` | Ray-X Pulsar Zoner, Photon Railgun, Drone, Supernova | Roster Kit | **LULUS** |
| **TS-31** | `test_character_select.tscn` | Character Select Screen, roster cards, & factory spawner | Selection UI | **LULUS** |
| **TS-32** | `test_underground_reactor.tscn` | Arena Underground Reactor, boundary walls, & steam vents | Arena & Hazards| **LULUS** |
| **TS-33** | `test_phantom_kage.tscn` | Phantom-9 Kage Stance Switcher, Iaido, Shuriken, & Blossom | Roster Kit | **LULUS** |

---

## 3. Kesimpulan Verifikasi

Seluruh 33 test suites terverifikasi otomatis dengan status kelulusan **100% (Zero Failures)**, menjamin kesiapan rilis game pada target platform Windows Desktop dan Mobile.

