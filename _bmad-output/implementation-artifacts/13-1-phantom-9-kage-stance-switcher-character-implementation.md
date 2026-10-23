---
baseline_commit: 37cc001
---

# Story 13.1: Phantom-9 "Kage" Stance Switcher Character Implementation

Status: done

## Story

As a player who enjoys agile dual-style hybrid fighters and mind-game mixups,
I want to play as Phantom-9 Kage with dynamic Stance Switching between close-range Kenjutsu Katana and ranged Shinobi Shurikens,
So that I can confuse opponents with evasive feints and fluidly adapt my combat range in mid-battle.

## Acceptance Criteria

1. **Character Constants & Baseline Stats (`scripts/combat/combat_constants.gd`)**:
   - `KAGE_MAX_HP = 920`
   - `KAGE_WALK_SPEED = 320.0`
   - `KAGE_DASH_SPEED = 780.0`
   - `KAGE_DASH_DURATION_FRAMES = 14`
   - `KAGE_STANCE_FEINT_FRAMES = 12`
   - `KAGE_IAIDO_DAMAGE = 120`
   - `KAGE_IAIDO_HEAT_COST = 25.0`
   - `KAGE_SHURIKEN_STORM_DAMAGE = 105` (35 x 3)
   - `KAGE_SHURIKEN_STORM_HEAT_COST = 20.0`
   - `KAGE_SHADOW_BLOSSOM_DAMAGE = 420`

2. **Attack Resources (`resources/attacks/`)**:
   - `resources/attacks/kage_slash.tres`: Kenjutsu Light Draw (Startup 4f, Active 3f, Recovery 8f, Damage 60, Heat +8%)
   - `resources/attacks/kage_cleave.tres`: Kenjutsu Heavy Cleave (Startup 8f, Active 4f, Recovery 14f, Damage 90, Heat +14%)
   - `resources/attacks/kage_kunai.tres`: Shinobi Light Poke (Startup 5f, Active 3f, Recovery 9f, Damage 50, Heat +8%)
   - `resources/attacks/kage_kunai_flurry.tres`: Shinobi Heavy Flurry (Startup 9f, Active 4f, Recovery 13f, Damage 85, Heat +14%)
   - `resources/attacks/kage_stance_shift.tres`: Stance Shift Feint (Startup 2f, Active 10f, Recovery 2f, Damage 0, Heat +15%, Evasive/Invuln Startup)
   - `resources/attacks/kage_iaido_strike.tres`: Kenjutsu Skill 2 Iaido Crescent (Startup 10f, Active 4f, Recovery 16f, Damage 120, Heat +25%)
   - `resources/attacks/kage_shuriken_storm.tres`: Shinobi Skill 2 Shuriken Storm (Startup 12f, Active 6f, Recovery 15f, Damage 105, Heat +20%)
   - `resources/attacks/kage_shadow_blossom.tres`: Ultimate Tsukuyomi Shadow Blossom (Startup 16f, Active 8f, Recovery 26f, Damage 420, Invulnerable Startup)

3. **Character Controller (`scripts/characters/phantom_kage.gd`)**:
   - Extends `BaseMecha`, binds move resources, sets archetype `&"kage"`.
   - Melacak kuda-kuda aktif: `current_stance` (`&"kenjutsu"` vs `&"shinobi"`).
   - Menangani pergantian jurus otomatis pada 5L, 5H, dan Skill 2 saat berganti stance.
   - Sinyal: `stance_changed(new_stance)`, `iaido_strike_executed()`, `shuriken_storm_thrown()`, `shadow_blossom_executed()`.

4. **Visual & Sprites Integration (`scripts/visual/mecha_pixel_sprite.gd` & `scripts/visual/vfx_ghost_trail.gd`)**:
   - Warna palet 32-bit: Midnight charcoal chassis (#0F141A), Crimson armor (#F22640), Neon red visor (#FF334B), Pale ivory skin, Dark shinobi cowl, dan Syal ninja (#E61F38).
   - Afterimage dash warna ruby crimson glowing trail (#FF1A35).

5. **Roster Integration (`scripts/characters/fighter_factory.gd`)**:
   - Mendaftarkan Phantom-9 Kage ke `FighterFactory.ROSTER` dengan ID `&"kage"`.
   - Spawner `create_fighter` mendukung pembuatan instance Kage.

6. **Automated Verification Suite (`tests/test_phantom_kage.gd` & `.tscn`)**:
   - Memvalidasi inisialisasi stats Kage (HP: 920, Walk: 320, Dash: 780).
   - Memvalidasi seluruh AttackData resources.
   - Memvalidasi mekanisme Stance Switcher dan perubahan kit jurus.
   - Memvalidasi eksekusi Iaido Strike, Shuriken Storm, dan Shadow Blossom.
   - Memvalidasi registrasi Roster & Factory instantiation.
   - Menjamin seluruh 32 test suites sebelumnya tetap 100% lulus (total 33 suites).

## Tasks / Subtasks

- [x] Task 1: Constants & Attack Resources (AC: 1, 2)
  - [x] 1.1 Tambahkan konstanta KAGE di `scripts/combat/combat_constants.gd`
  - [x] 1.2 Buat file `.tres` serangan Kage di `resources/attacks/`
- [x] Task 2: Character Implementation (AC: 3)
  - [x] 2.1 Buat `scripts/characters/phantom_kage.gd`
- [x] Task 3: Visual & Roster Integration (AC: 4, 5)
  - [x] 3.1 Tambahkan palet & persona Kage di `scripts/visual/mecha_pixel_sprite.gd`
  - [x] 3.2 Tambahkan trail color Kage di `scripts/visual/vfx_ghost_trail.gd`
  - [x] 3.3 Daftarkan ke `scripts/characters/fighter_factory.gd`
- [x] Task 4: Automated Testing & Verification (AC: 6)
  - [x] 4.1 Buat `tests/test_phantom_kage.gd` dan `tests/test_phantom_kage.tscn`
  - [x] 4.2 Daftarkan di `tests/run_all_tests.ps1` dan jalankan master suite
