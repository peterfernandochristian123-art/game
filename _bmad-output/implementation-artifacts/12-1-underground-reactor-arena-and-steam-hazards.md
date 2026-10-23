---
baseline_commit: d60db7b
---

# Story 12.1: Underground Reactor Stage with Boundary Walls & Steam Hazards

Status: done

## Story

As a player competing in Versus AI, Local 2P, or Training mode,
I want to battle in the Underground Reactor stage featuring enclosed boundary walls that bounce knocked-back fighters and active steam vents that periodically erupt with heat hazards,
So that I can experience tactical corner pressure, wall-bounce combos, and environmental risk management distinct from the open skyscraper arena.

## Acceptance Criteria

1. **Underground Reactor Scene Architecture (`scenes/arena_underground_reactor.tscn`)**:
   - Enclosed combat platform with floor width matching 1280 px (X=64 to X=1344) and solid boundary walls at Left (X=64) and Right (X=1344) on Layer 1 World Collision.
   - Distinct 32-bit cyberpunk industrial aesthetic: massive geothermal conduit pipes, warm orange/amber warning lights, and reactor core glow.
   - Camera boundaries configured to pan smoothly within arena margins without revealing out-of-bounds space.

2. **Corner Wall-Bounce Combat Integration**:
   - Attacks causing heavy knockback against the boundary walls trigger a visceral wall-bounce reaction.
   - Governed by the 1-wall-bounce limit per target chain sequence (FR9) to maintain combo fairness.

3. **Geothermal Steam Vent Hazard System (`scripts/hazards/steam_vent_hazard.gd`)**:
   - Stage features 2 industrial floor vents situated at tactical spacing (e.g. X=420 and X=988).
   - Hazard State Cycle:
     - **Dormant State**: Inactive warning beacon.
     - **Warning State (3.0s)**: Flashing yellow/red hazard beacon + audio hiss warning.
     - **Eruption State (1.5s)**: High-pressure vertical thermal steam jet (`GPUParticles2D`).
   - Hazard Damage & Heat Penalty:
     - Fighters standing in or jumping through active steam receive chip damage (e.g. 15 damage) and an instant +20% Heat increase.
     - Respects fighter i-frames and shields accordingly.

4. **Arena Selection Routing in Match Configuration**:
   - `MatchConfig` (`scripts/core/match_config.gd`) tracks `selected_arena` with options `&"skyscraper"` (default) and `&"reactor"`.
   - `CharacterSelect` (`scenes/character_select.tscn` & `scripts/ui/character_select.gd`) provides an interactive Stage Selector toggle with preview thumbnail/text.
   - `VersusAIManager` and `LocalVersusManager` instantiate and route to `arena_underground_reactor.tscn` when selected.

5. **Automated Verification Suite (`tests/test_underground_reactor.gd` & `.tscn`)**:
   - Verifies scene structure, boundary wall collisions, and camera clamps.
   - Verifies steam vent hazard state cycle (Dormant -> Warning -> Eruption) and heat injection.
   - Verifies stage routing through `MatchConfig`.
   - All tests pass 100%.

## Tasks / Subtasks

- [x] Task 1: Steam Vent Hazard Component (AC: 3)
  - [x] 1.1 Buat `scripts/hazards/steam_vent_hazard.gd`
- [x] Task 2: Underground Reactor Scene & Boundaries (AC: 1, 2)
  - [x] 2.1 Buat `scenes/arena_underground_reactor.tscn`
  - [x] 2.2 Konfigurasikan boundary walls, ground platform, dan visual industrial
- [x] Task 3: Match Config & Stage Selection Integration (AC: 4)
  - [x] 3.1 Perbarui `scripts/core/match_config.gd` dengan arena routing
  - [x] 3.2 Tambahkan toggle Stage Selection pada `scenes/character_select.tscn` & `scripts/ui/character_select.gd`
  - [x] 3.3 Pastikan `versus_ai_manager.gd` dan `local_versus_manager.gd` memuat arena terpilih
- [x] Task 4: Automated Testing & Master Runner Integration (AC: 5)
  - [x] 4.1 Buat `tests/test_underground_reactor.gd` dan `tests/test_underground_reactor.tscn`
  - [x] 4.2 Daftarkan ke `tests/run_all_tests.ps1` dan jalankan verifikasi
