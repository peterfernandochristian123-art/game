---
baseline_commit: 42ed460
---

# Story 3.3: Titan-V "Bulwark" Heavy Grappler Implementation

Status: review

## Story

As a player preferring raw power and space control,
I want to play as Titan-V Bulwark with heavy punches, unblockable piledriver, riot shield, and siege cannon,
So that I can dominate close-quarters combat and punish aggressive opponents with massive damage.

## Acceptance Criteria

1. **Karakteristik & Base Stats Bulwark**:
   - Subclass `TitanBulwark` (`scripts/characters/titan_bulwark.gd`, `class_name TitanBulwark extends BaseMecha`).
   - Stats awal: `max_hp = 1200`, `passive_damage_reduction = 0.05` (5% passive armor reduction), `walk_speed = 260.0` px/s, `dash_speed = 650.0` px/s. Durasi dash 16 frame.
   - Pembeda visual mecha: visual heavy metallic bronze/dark industrial armor.

2. **2-Hit Heavy Impact Normal String (GDD §5.1 & §5.2)**:
   - Dibuat Resource:
     - `resources/attacks/bulwark_punch.tres`: 5L Normal 1 (Startup 7f, Active 3f, Recovery 14f, Damage 75, Hitstun 20f, Blockstun 13f [-4 on block], Knockback 180.0, Chain Level 1).
     - `resources/attacks/bulwark_slam.tres`: 5H Normal 2 (Startup 14f, Active 4f, Recovery 18f, Damage 120, Hitstun 28f, Blockstun 16f, Knockback 300.0, Causes Ground Bounce = true, Causes Wall Bounce = true, Chain Level 2).
   - Mendukung Target Chain Cancel: 5L → 5H.

3. **Skill 1: Hydraulic Piledriver (Command Grab)**:
   - Resource: `resources/attacks/bulwark_piledriver.tres` (Startup 6f, Active 2f, Recovery 22f, Damage 220, Heat Cost +35.0%, `is_unblockable = true`, `is_grab = true`, Chain Level 3).
   - Mekanik: Mengabaikan normal blocking musuh, membanting korban dengan damage masif 220, dan menambah +35% Heat.

4. **Skill 2: Riot Shield Deploy**:
   - Resource: `resources/attacks/bulwark_riot_shield.tres` (Startup 4f, Active 45f, Recovery 15f, Damage 40, Heat Cost +15.0%, Chain Level 3).
   - Memberikan status *Full Super Armor* selama 45 frame terhadap serangan non-grab (`super_armor_frames = 45`).
   - Menyerap hitstun serangan fisik biasa tanpa terganggu atau terdorong ke `HitstunState`. Serangan grab tetap menembus super armor.
   - Menambah +15% Heat.

5. **Ultimate: Orbital Siege Cannon**:
   - Resource: `resources/attacks/bulwark_orbital_cannon.tres` (Startup 24f, Active 12f, Recovery 30f, Damage 450, is_energy = true, causes_ground_bounce = true, causes_wall_bounce = true, Knockback 550.0, Chain Level 4).
   - Mengonsumsi 100% bar Ultimate (`current_ultimate >= 100.0`).
   - Menembakkan meriam laser partikel layar penuh berdamage 450 HP.

6. **Automated Testing Suite**:
   - Buat `tests/test_titan_bulwark.gd` dan `tests/test_titan_bulwark.tscn`.
   - Validasi base stats (HP 1200, jalan 260, dash 650/16f, passive armor -5%).
   - Validasi reduksi pasif 5% saat menerima hit.
   - Validasi 2-hit impact frame data & resources (Punch 7f, Slam 14f dengan ground/wall bounce).
   - Validasi Hydraulic Piledriver (unblockable command grab, menembus guard musuh, damage 220, +35% heat).
   - Validasi Riot Shield Deploy (Full Super Armor 45 frame menyerap serangan fisik biasa, rentan terhadap grab).
   - Validasi Orbital Siege Cannon (syarat gauge 100%, startup 24f, damage 450).

## Tasks / Subtasks

- [x] Task 1: Resource Setup Serangan Bulwark (AC: 2, 3, 4, 5)
  - [x] 1.1 Buat Resource `bulwark_punch.tres` dan `bulwark_slam.tres`.
  - [x] 1.2 Buat Resource `bulwark_piledriver.tres` (unblockable grab, damage 220, +35% heat).
  - [x] 1.3 Buat Resource `bulwark_riot_shield.tres` (Full super armor 45 frame, +15% heat).
  - [x] 1.4 Buat Resource `bulwark_orbital_cannon.tres` (Ultimate 450 damage, startup 24f).
- [x] Task 2: Implementasi TitanBulwark Controller & Core Armor Hooks (AC: 1, 3, 4)
  - [x] 2.1 Tambahkan dukungan `passive_damage_reduction`, `super_armor_frames`, dan `is_unblockable` di `BaseMecha`.
  - [x] 2.2 Buat `scripts/characters/titan_bulwark.gd` mewarisi `BaseMecha`.
  - [x] 2.3 Terapkan statistik khusus Bulwark (HP 1200, Walk 260, Dash 650/16f, Armor 5%).
  - [x] 2.4 Implementasikan `execute_hydraulic_piledriver()` command grab.
  - [x] 2.5 Implementasikan `execute_riot_shield_deploy()` super armor 45 frame.
  - [x] 2.6 Implementasikan `activate_orbital_siege_cannon()` ultimate laser.
- [x] Task 3: Automated Test Suite (AC: 6)
  - [x] 3.1 Buat `tests/test_titan_bulwark.gd` dan `tests/test_titan_bulwark.tscn`.
  - [x] 3.2 Uji base stats, passive armor, 2-hit string, unblockable grab, super armor, dan ultimate.
