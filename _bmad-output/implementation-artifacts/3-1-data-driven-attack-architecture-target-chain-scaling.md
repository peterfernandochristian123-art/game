---
baseline_commit: 737a5a4
---

# Story 3.1: Data-Driven Attack Architecture & Target Chain Scaling

Status: review

## Story

As a developer and combat designer,
I want all move parameters defined in Godot Resource `.tres` files and combos evaluated with progressive damage scaling,
so that combat balance can be adjusted rapidly without code modifications and combos remain fair.

## Acceptance Criteria

1. **Data-Driven Attack Architecture (`AttackData` Resource)**:
   - Buat class `AttackData` (`scripts/combat/resources/attack_data.gd`, `class_name AttackData extends Resource`) yang mendefinisikan:
     - `attack_name: StringName`, `startup: int`, `active: int`, `recovery: int`, `damage: int`, `hitstun: int`, `blockstun: int`, `knockback: float`, `heat_cost: float`, `is_energy: bool`, `causes_ground_bounce: bool`, `causes_wall_bounce: bool`, `chain_level: int`.
   - Sediakan file `.tres` Resource dasar di `resources/attacks/`:
     - `normal_light.tres` (5L: Normal 1, Startup 5, Active 3, Recovery 8, Damage 40, Chain Level 1)
     - `normal_heavy.tres` (5H: Normal 2, Startup 10, Active 4, Recovery 16, Damage 90, Ground Bounce, Chain Level 2)
     - `skill_slash.tres` (Skill 1: Startup 8, Active 3, Recovery 14, Damage 120, Heat Cost 25.0, Energy, Chain Level 3)
   - Kompatibilitas dengan sistem dictionary sebelumnya via `to_dict()` dan `from_dict()`.

2. **Target Chain Cancel System**:
   - Sistem kombo mendukung pembatalan frame (*Target Chain Cancel*):
     - Normal 1 (Chain Level 1) dapat di-cancel on-hit ke Normal 2 (Chain Level 2) atau Skill (Chain Level 3).
     - Normal 2 (Chain Level 2) dapat di-cancel on-hit ke Skill (Chain Level 3).
     - Serangan tidak dapat di-cancel ke tingkatan chain yang sama atau lebih rendah (mencegah loop tak terbatas).
   - Cancel hanya dapat dieksekusi saat serangan telah mengenai target lawan (`can_chain_cancel == true`).

3. **Progressive Combo Damage Scaling**:
   - Nilai pengali damage berkurang berjenjang selama rangkaian kombo tanpa jeda:
     - Hit 1: 100% damage (`1.0`)
     - Hit 2: 85% damage (`0.85`)
     - Hit 3: 70% damage (`0.70`)
     - Hit 4+: Berkurang 10% per hit (Hit 4 = 60%, Hit 5 = 50%, Hit 6 = 40%, Hit 7 = 30%)
     - Batas minimum (*Damage Floor*): 25% damage (`0.25`).
   - Formula diimplementasikan secara deterministik di `CombatConstants.calculate_combo_damage(base_dmg, hit_number)`.

4. **Bounce Limit Rule (Anti-Infinite)**:
   - Maksimal 1 kali *Ground Bounce* dalam satu rangkaian kombo (`ground_bounce_count <= 1`).
   - Maksimal 1 kali *Wall/Edge Bounce* dalam satu rangkaian kombo (`wall_bounce_count <= 1`).
   - Percobaan bounce berikutnya dalam kombo yang sama otomatis dibatasi / diabaikan.
   - Status bounce dan kombo direset ke 0 saat korban pulih dari status `Hitstun` kembali ke `Idle`.

5. **Automated Testing Suite**:
   - Buat `tests/test_attack_chain_scaling.gd` dan `tests/test_attack_chain_scaling.tscn`.
   - Uji validasi pemuatan Resource `AttackData` `.tres`.
   - Uji kalkulasi damage scaling 100% -> 85% -> 70% -> 60% -> floor 25%.
   - Uji transisi Target Chain Cancel on-hit (5L -> 5H -> Skill).
   - Uji kombo scaling pada `take_hit()` dan pemulihan status kombo.
   - Uji batasan maksimal 1 kali bounce per kombo.

## Tasks / Subtasks

- [x] Task 1: AttackData Resource & Attack Presets (AC: 1)
  - [x] 1.1 Buat `scripts/combat/resources/attack_data.gd` (`class_name AttackData extends Resource`).
  - [x] 1.2 Buat Resource files `resources/attacks/normal_light.tres`, `normal_heavy.tres`, `skill_slash.tres`.
- [x] Task 2: Combo Scaling & Bounce Limit Constants (AC: 3, 4)
  - [x] 2.1 Tambahkan konstanta scaling hit 1..3, decay, damage floor, dan bounce limits di `CombatConstants`.
  - [x] 2.2 Implementasikan fungsi statis `CombatConstants.calculate_combo_damage()`.
- [x] Task 3: Target Chain Cancel & Integrasi BaseMecha (AC: 1, 2, 4)
  - [x] 3.1 Perbarui `AttackState` untuk mengenali `chain_level`, mengaktifkan `can_chain_cancel` on-hit, dan mengeksekusi cancel rantai.
  - [x] 3.2 Tambahkan pelacakan kombo (`combo_hit_count`, `ground_bounce_count`, `wall_bounce_count`) dan scaling di `BaseMecha.take_hit()`.
  - [x] 3.3 Tambahkan metode `reset_combo_state()` dan integrasikan pemanggilan saat keluar dari `HitstunState` atau masuk `IdleState`.
- [x] Task 4: Automated Testing Suite & Validasi (AC: 5)
  - [x] 4.1 Buat `tests/test_attack_chain_scaling.gd` + `tests/test_attack_chain_scaling.tscn`.
  - [x] 4.2 Jalankan validasi pengujian otomatis seluruh acceptance criteria.
  - [x] 4.3 Verifikasi regresi suite Epic 1 & Epic 2.
