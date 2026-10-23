---
baseline_commit: d6d2a7e
---

# Story 7.1: 32-Bit Pixel Mecha Sprites, State Visuals & Architecture Hardening

Status: done

## Story

As a player,
I want distinct, highly recognizable 32-bit pixel art mecha visuals and fluid state animations for Apex-0 Viper and Titan-V Bulwark instead of placeholder colored blocks,
So that the combat feels authentic, visually punchy, readable, and true to the 90s arcade aesthetic.

## Acceptance Criteria

1. **Dedicated Pixel Art Visual Components (`scripts/visual/mecha_pixel_sprite.gd` / `scripts/visual/mecha_visual_controller.gd`)**:
   - Karakter mecha tidak lagi menggunakan placeholder kotak statis `ColorRect`, melainkan komponen visual 32-bit pixel art yang merender siluet mecha berbobot pada resolusi kanvas 640x360.
   - Karakter `ApexViper`: Siluet ramping aerodinamis warna cyan-neon (#33E6FF) dengan helm visor berpendar, rapier beam emitter, dan micro-thruster nozzle.
   - Karakter `TitanBulwark`: Siluet bodi baja industrial warna oranye-kuning (#FFA500 / #D97706) dengan pelat baja tebal, hydraulic piston arm, dan shoulder bulk guard.

2. **State-Driven Visual Poses & Micro-Animations**:
   - Komponen visual merespons transisi status `StateMachine` secara mulus:
     - `Idle`: Efek *idle bobbing* (suspensi naik-turun halus 2–3px) dan uap knalpot mikro.
     - `Walk`: Pose langkah maju/mundur dengan animasi pergeseran sendi kaki.
     - `Jump` / `Fall`: Kaki mecha terangkat, jet pendorong bawah menyala (*thruster flare*).
     - `Dash`: Badan mecha condong ke arah dorongan (*tilt angle*), thruster belakang memancar penuh dengan jejak siluet singkat.
     - `Attack` (Normal 5L/5H, Skills): Ekstensi lengan pedang beam (Viper) atau pukulan hidrolik godam (Bulwark) dengan frame startup, active, dan recovery visual yang sinkron dengan frame data `AttackData`.
     - `Hitstun`: Flash rona putih/merah (*hit flash*) selama 3 frame dan postur tubuh terhuyung ke belakang.
     - `Parry` & `Blockstun`: Postur bertahan kokoh dengan shield energy flare atau perisai baja tertutup.
     - `Cliffhanger`: Postur bergelantungan dengan satu tangan memegang bibir platform tebing.
     - `Meltdown`: Mecha tertunduk lunglai dengan ventilasi mati dan uap overheating.

3. **Collision & Physics Matrix Preservation**:
   - Dimensi `CollisionShape2D` mecha tetap terkunci pada ukuran standar 24x38 px dan posisi offset (0, 0).
   - Seluruh matriks layer tabrakan (Layer 1 World, Layer 2 Hurtbox, Layer 3 StrikeHitbox, Layer 4 GrabHitbox, Layer 5 LedgeSensor) tidak terganggu atau bergeser.
   - Orientasi `facing_direction` (1 / -1) membalikkan visual secara konsisten tanpa mendistorsi posisi hit/hurtbox.

4. **Technical Debt & Deferred Work Resolution (`_bmad-output/implementation-artifacts/deferred-work.md`)**:
   - Melakukan unifikasi single-source-of-truth untuk konstanta heat maksimum mecha: menghapus redundansi antara `BaseMecha.max_heat` dan `CombatConstants.MAX_HEAT` (menjadikan `CombatConstants.MAX_HEAT` sebagai acuan default, dengan `max_heat` membaca dari konstanta tersebut).
   - Memperbarui `.gitignore` proyek untuk mengabaikan artefak dump test (`test_*_results.txt`) dan cache runtime internal Godot agar repositori git tetap bersih dan higienis.

5. **Regression & Automated Verification Suite (`tests/test_pixel_sprites_visual.gd` & `tests/test_pixel_sprites_visual.tscn`)**:
   - Pengujian otomatis headless memvalidasi node visual mecha terpasang dengan benar pada ApexViper dan TitanBulwark.
   - Validasi bahwa transisi state memicu perubahan pose visual / frame modulasi yang sesuai.
   - Validasi bahwa ukuran collision box mecha tidak mengalami regresi dan tetap deterministik 60 FPS.
   - Seluruh 25 test suite yang ada sebelumnya (Epic 1 s/d Epic 6) tetap lulus 100% tanpa regresi.

## Tasks / Subtasks

- [x] Task 1: Architecture Hardening & Deferred Item Resolution (AC: 4)
  - [x] 1.1 Unifikasi `BaseMecha.max_heat` agar default merujuk ke `CombatConstants.MAX_HEAT`.
  - [x] 1.2 Perbarui `.gitignore` untuk mengabaikan file hasil pengujian `test_*_results.txt` dan artefak sementara.
  - [x] 1.3 Perbarui catatan di `_bmad-output/implementation-artifacts/deferred-work.md`.
- [x] Task 2: 32-Bit Pixel Mecha Visual Node Architecture (AC: 1, 3)
  - [x] 2.1 Buat controller visual `scripts/visual/mecha_visual_controller.gd` yang mengelola sprite partikel/prosedural/pixel art 32-bit.
  - [x] 2.2 Desain siluet pixel khas untuk Apex-0 Viper (cyan aerodinamis) dan Titan-V Bulwark (oranye industrial kokoh).
  - [x] 2.3 Pastikan integrasi dengan `facing_direction` dan layer kolisi 24x38 px.
- [x] Task 3: State-Driven Animation & Pose Synchronization (AC: 2)
  - [x] 3.1 Sambungkan listener sinyal state change dari `StateMachine` (Idle, Walk, Jump, Fall, Dash, Attack, Hitstun, Cliffhanger, Meltdown).
  - [x] 3.2 Implementasikan mikro-animasi (thruster flare saat dash/jump, idle bobbing, hit flash, dan cliffhanger hang pose).
  - [x] 3.3 Integrasikan pose serangan visual yang sinkron dengan frame data `AttackData` (startup, active, recovery).
- [x] Task 4: Scene & Character Integration (AC: 1, 2, 3)
  - [x] 4.1 Update `scenes/versus_ai_mode.tscn`, `scenes/local_versus_mode.tscn`, dan `scenes/training_mode.tscn` agar menggunakan komponen visual baru secara otomatis via `BaseMecha._setup_visual_node()`.
  - [x] 4.2 Pastikan fallback visual bekerja mulus pada karakter yang di-instantiate via script.
- [x] Task 5: Automated Testing Suite & Verification (AC: 5)
  - [x] 5.1 Buat `tests/test_pixel_sprites_visual.gd` dan `tests/test_pixel_sprites_visual.tscn`.
  - [x] 5.2 Jalankan seluruh pengujian otomatis melalui `tests/run_all_tests.ps1` dan pastikan 26/26 test suites lulus 100%.

## Dev Notes

- **Architecture Patterns**:
  - Menggunakan sistem visual canvas 2D modular `MechaPixelSprite` (`Node2D` dengan drawing procedurally styled pixel art) yang render tajam pada kanvas 640x360 dengan integer scaling.
  - Node visual diletakkan di bawah `MechaVisual` bernama `Sprite` sehingga method `_find_visual_node()` dan modulasi warna di `BaseMecha`, `ApexViper`, dan `TitanBulwark` tetap kompatibel 100%.
  - Animasi visual terikat pada frame FSM tanpa memblokir atau mengubah timer deterministik `_physics_process(delta)`.

- **Collision & Matrix**:
  - Ukuran mecha: 24x38 px (Layer 1: World).
  - Hurtbox: 24x38 px (Layer 2: Hurtbox).
  - StrikeHitbox: Layer 3.
  - GrabHitbox: Layer 4.
  - LedgeSensor: Layer 5.

- **Testing Standards**:
  - Headless Godot runner: `.godot_bin\Godot_v4.7.2-stable_win64_console.exe --headless --path . <scene>`.
  - Hasil uji: 26/26 test suites LULUS 100%.

### Project Context Rules

- **Platform Target**: PC & Mobile (Compatibility Renderer / GL Compatibility).
- **Pixel Art Resolution**: 640x360 internal canvas resolution.
- **Autoload Singletons**: `EventBus`, `InputBuffer`.
- **FSM Pattern**: State transition melalui `state_machine.change_state(new_state_name)`.

### References

- GDD §1.3 (Neo-Retro 32-Bit Aesthetics)
- GDD §5.1 & §5.2 (Character Archetypes & Visual Identity)
- Architecture §6 (Visual & Juice Subsystem)
- Deferred Work Item: `_bmad-output/implementation-artifacts/deferred-work.md`

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Task 245 run_all_tests log: 26/26 test suites PASS (100% success).

### Completion Notes List

- Implemented `MechaPixelSprite` (`scripts/visual/mecha_pixel_sprite.gd`): 32-bit pixel art procedural renderer with bespoke silhouettes for Apex-0 Viper (aerodynamic cyan rushdown) and Titan-V Bulwark (heavy industrial orange grappler), dynamic thruster jet flames, idle bobbing, attack pose extensions, hitstun flashes, and cliffhanger hand grip.
- Implemented `MechaVisualController` (`scripts/visual/mecha_visual_controller.gd`): controller wrapper for mecha visuals.
- Updated `BaseMecha` (`scripts/characters/base_mecha.gd`):
  - Unified `max_heat` to `CombatConstants.MAX_HEAT`.
  - Added `_setup_visual_node()` which automatically upgrades placeholder `ColorRect` to `MechaPixelSprite`.
  - Added safe `get_node_or_null("StateMachine")` and auto-creation of root `CollisionShape2D` (24x38 px) if absent.
  - Added `trigger_hit_flash()` on damage intake.
- Resolved deferred work items: untracked `test_*results.txt` from git tracking, updated `.gitignore`, and updated `deferred-work.md`.
- Added test suite `tests/test_pixel_sprites_visual.gd` and `.tscn` (5/5 tests passed).
- Updated `tests/run_all_tests.ps1` to execute all 26 test suites; regression verification confirmed 100% pass across all suites.

### File List

- `scripts/visual/mecha_pixel_sprite.gd` (NEW)
- `scripts/visual/mecha_visual_controller.gd` (NEW)
- `tests/test_pixel_sprites_visual.gd` (NEW)
- `tests/test_pixel_sprites_visual.tscn` (NEW)
- `scripts/characters/base_mecha.gd` (MODIFIED)
- `scripts/characters/apex_viper.gd` (MODIFIED)
- `scripts/characters/titan_bulwark.gd` (MODIFIED)
- `.gitignore` (MODIFIED)
- `tests/run_all_tests.ps1` (MODIFIED)
- `_bmad-output/implementation-artifacts/deferred-work.md` (MODIFIED)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (MODIFIED)
- `_bmad-output/planning-artifacts/epics.md` (MODIFIED)
- `_bmad-output/implementation-artifacts/7-1-32-bit-pixel-mecha-sprites-and-state-animations.md` (MODIFIED)

