---
baseline_commit: c7c7fe5
---

# Story 11.1: Character Select Screen & Roster Selection System

Status: done

## Story

As a player starting a duel in Versus AI or Local 2P mode,
I want to select my preferred mecha from the 3-fighter roster (Apex-0 Viper, Titan-V Bulwark, Ray-X Pulsar), inspect their stats, and see live animated pixel sprite previews,
So that I can customize each combat match with contrasting combat playstyles before entering the arena.

## Acceptance Criteria

1. **Roster Metadata & Factory Spawner (`scripts/characters/fighter_factory.gd`)**:
   - Central registry for all 3 mechas: Apex-0 Viper, Titan-V Bulwark, Ray-X Pulsar.
   - Provides character stats (HP, Walk Speed, Dash Speed, Speed/Defense/Range ratings, signature move descriptions).
   - Standardized instantiation via `FighterFactory.create_fighter(character_id, player_index)`.

2. **Match Configuration State (`scripts/core/match_config.gd`)**:
   - Manages selected fighters (`p1_character`, `p2_character`) and active game mode (`&"versus_ai"`, `&"local_2p"`).
   - Determines target arena scene routing.

3. **Character Select UI & Live Animated Previews (`scenes/character_select.tscn` & `scripts/ui/character_select.gd`)**:
   - Retro 32-bit cyberpunk aesthetic matching 640x360 resolution with Neon Cyan and Amber Gold accents.
   - 3 Roster Cards for Viper, Bulwark, and Pulsar with cursor highlights.
   - Live animated pixel previews rendering `MechaPixelSprite` for P1 and P2.
   - Move list and stats inspection panels.
   - P1 and P2 lock-in confirmation and auto-transition to the arena.

4. **Dynamic Arena Spawning Integration**:
   - `VersusAIManager` (`scripts/ai/versus_ai_manager.gd`) and `LocalVersusManager` (`scripts/core/local_versus_manager.gd`) automatically spawn the selected mechas when entering the match.

5. **Automated Verification Suite (`tests/test_character_select.gd` & `.tscn`)**:
   - Verifies roster metadata and fighter instantiation.
   - Verifies scene structure, navigation wrapping, and lock-in transitions.
   - Ensures all 31 automated test suites pass 100%.

## Tasks / Subtasks

- [x] Task 1: Roster Factory & Match Config (AC: 1, 2)
  - [x] 1.1 Buat `scripts/core/match_config.gd`
  - [x] 1.2 Buat `scripts/characters/fighter_factory.gd`
- [x] Task 2: Character Select Scene & Controller (AC: 3)
  - [x] 2.1 Buat `scenes/character_select.tscn`
  - [x] 2.2 Buat `scripts/ui/character_select.gd`
- [x] Task 3: Dynamic Arena Spawning Integration (AC: 4)
  - [x] 3.1 Integrasikan di `scripts/ai/versus_ai_manager.gd`
  - [x] 3.2 Integrasikan di `scripts/core/local_versus_manager.gd`
  - [x] 3.3 Hubungkan Main Menu routing di `scripts/ui/main_menu.gd`
- [x] Task 4: Automated Testing & Verification (AC: 5)
  - [x] 4.1 Buat `tests/test_character_select.gd` dan `tests/test_character_select.tscn`
  - [x] 4.2 Daftarkan di `tests/run_all_tests.ps1` dan jalankan master suite
