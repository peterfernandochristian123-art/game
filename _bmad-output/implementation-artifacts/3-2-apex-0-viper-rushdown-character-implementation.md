---
baseline_commit: fe074a8
---

# Story 3.2: Apex-0 "Viper" Rushdown Character Implementation

Status: review

## Story

As a player preferring speed and aerial dominance,
I want to play as Apex-0 Viper with rapid rapier strikes, teleport slash, deflection matrix, and cryogenic mode,
so that I can out-maneuver heavy opponents with agile hit-and-run tactics.

## Acceptance Criteria

1. **Karakteristik & Base Stats Viper**:
   - Subclass `ApexViper` (`scripts/characters/apex_viper.gd`, `class_name ApexViper extends BaseMecha`).
   - Stats awal: `max_hp = 900`, `walk_speed = 350.0` px/s, `dash_speed = 820.0` px/s. Durasi dash 12 frame.
   - Pembeda visual mecha: visual cyan/neon-blue beraksen rapier lincah.

2. **3-Hit Rapier Beam Combo (Normal String Target Chain)**:
   - Dibuat Resource:
     - `resources/attacks/viper_jab.tres`: 5L1 (Startup 3f, Active 2f, Recovery 6f, Damage 30, Chain Level 1, On-Hit +4f).
     - `resources/attacks/viper_thrust.tres`: 5L2 (Startup 6f, Active 3f, Recovery 8f, Damage 40, Chain Level 2).
     - `resources/attacks/viper_cleave.tres`: 5H (Startup 11f, Active 4f, Recovery 14f, Damage 70, Chain Level 3).
   - Mendukung Target Chain Cancel penuh: 5L1 → 5L2 → 5H.

3. **Skill 1: Blink Slash (Teleport Slash)**:
   - Resource: `resources/attacks/viper_blink_slash.tres` (Startup 10f, Active 4f, Recovery 18f, Damage 110, Heat Cost +25.0%).
   - Mekanik: Menembus garis musuh seketika sejauh hingga 400 px dan menebas dari arah belakang korban.
   - Mengubah orientasi `facing_direction` ke arah musuh setelah teleport.
   - Menambahkan +25% Heat pada `HeatComponent`.

4. **Skill 2: Deflection Matrix**:
   - Resource: `resources/attacks/viper_deflection_matrix.tres` (Startup 4f, Active 30f, Recovery 10f, Heat Cost +20.0%).
   - Memasang jaring energi selama 30 frame (0.5 detik).
   - Menangkis/menghalau proyektil dan memperlambat musuh di dalam radius area (speed penalty 50%).
   - Menambahkan +20% Heat pada `HeatComponent`.

5. **Ultimate: Absolute Zero Protocol**:
   - Mengonsumsi 100% bar Ultimate (`current_ultimate >= 100.0`).
   - Mengaktifkan status *Cryogenic Mode* selama 8 detik (480 physics frame):
     - Heat terkunci pada 0.0% (tidak bertambah dari aksi apa pun).
     - Kecepatan dash meningkat +30% (dari 820 px/s menjadi 1066 px/s).
     - Dash udara tidak terbatas (`can_air_dash` tidak habis).
     - Efek aura visual kriogenik (Cyan glow).
     - Setelah 480 frame, mode berakhir dan stats kembali normal.

6. **Automated Testing Suite**:
   - Buat `tests/test_apex_viper.gd` dan `tests/test_apex_viper.tscn`.
   - Validasi base stats (HP 900, jalan 350, dash 820).
   - Validasi 3-hit rapier chain cancel (Jab 3f -> Thrust 6f -> Cleave 11f).
   - Validasi Blink Slash (teleportasi 400 px, rotasi arah hadap, +25% heat).
   - Validasi Deflection Matrix (durasi 30 frame, +20% heat).
   - Validasi Absolute Zero Protocol (lock heat 0%, dash +30%, unlimited air dash, timer 8 detik).

## Tasks / Subtasks

- [x] Task 1: Resource Setup Serangan Viper (AC: 2, 3, 4)
  - [x] 1.1 Buat Resource `viper_jab.tres`, `viper_thrust.tres`, `viper_cleave.tres`.
  - [x] 1.2 Buat Resource `viper_blink_slash.tres` dan `viper_deflection_matrix.tres`.
- [x] Task 2: Implementasi ApexViper Controller (AC: 1, 3, 4, 5)
  - [x] 2.1 Buat `scripts/characters/apex_viper.gd` mewarisi `BaseMecha`.
  - [x] 2.2 Terapkan statistik khusus Viper (HP 900, Walk 350, Dash 820/12f).
  - [x] 2.3 Implementasikan logika teleportasi *Blink Slash* sejauh 400 px menembus musuh.
  - [x] 2.4 Implementasikan *Deflection Matrix* (jaring energi 30 frame).
  - [x] 2.5 Implementasikan *Absolute Zero Protocol* (Cryogenic mode 480 frame: heat 0%, dash +30%, air dash tak terbatas).
- [x] Task 3: Integrasi Kontrol & State Transitions (AC: 2, 3, 4, 5)
  - [x] 3.1 Sambungkan input skill 1 (Blink Slash), skill 2 (Deflection Matrix), dan Ultimate ke FSM.
  - [x] 3.2 Integrasikan rantai 3-hit rapier combo ke sistem Target Chain Cancel.
- [x] Task 4: Automated Testing Suite & Validasi (AC: 6)
  - [x] 4.1 Buat `tests/test_apex_viper.gd` + `tests/test_apex_viper.tscn`.
  - [x] 4.2 Jalankan validasi pengujian otomatis seluruh acceptance criteria.
  - [x] 4.3 Verifikasi regresi suite Epic 1, 2, dan 3.1.
