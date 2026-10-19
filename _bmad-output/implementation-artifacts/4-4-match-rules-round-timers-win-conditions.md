---
baseline_commit: ea75254
---

# Story 4.4: Match Rules, Round Timers & Win Conditions

Status: review

## Story

As a competitive player,
I want matches conducted under a Best of 3 Rounds format with 90-second timers and sudden death resolution,
So that rounds conclude decisively with clear winner declarations.

## Acceptance Criteria

1. **Format Pertandingan Best of 3 Rounds**:
   - Pertandingan dimulai dengan skor ronde 0 - 0 dan ronde awal 1.
   - Mecha pertama yang mengamankan 2 kemenangan ronde dinyatakan sebagai *MATCH WINNER* (`CombatConstants.ROUNDS_TO_WIN = 2`).

2. **Timer Ronde & Time-Out (90 Detik)**:
   - Durasi default tiap ronde adalah 90 detik (`CombatConstants.ROUND_TIME_SECONDS = 90.0`).
   - Sinyal `timer_updated(seconds_left)` diperbarui setiap frame.
   - Saat timer mencapai 0.0, pemenang ronde ditentukan oleh mecha dengan sisa persentase HP tertinggi.

3. **Kondisi Kemenangan Ronde**:
   - **K.O.**: HP lawan mencapai 0 (atau mecha hancur).
   - **Ring-Out**: Lawan jatuh di bawah batas arena Y > 600 px atau tereliminasi via Ledge Stomp di tubir tebing.
   - **Time-Out**: Sisa persentase HP tertinggi saat waktu habis.

4. **Sudden Death Resolution (Babak Penentuan Seri)**:
   - Jika ronde berakhir seri (Double K.O. atau HP persis identik saat waktu habis), sistem mengaktifkan babak *Sudden Death*.
   - Timer Sudden Death diset ke 30 detik (`CombatConstants.SUDDEN_DEATH_SECONDS = 30.0`).
   - Kedua petarung langsung memulai babak dengan 90% Heat (`CombatConstants.SUDDEN_DEATH_STARTING_HEAT = 90.0`), memicu Overclock Zone seketika.

5. **Reset & Transisi Antar Ronde**:
   - `reset_fighters_for_round()` mengembalikan HP ke status penuh, mereset cengkeraman cliffhanger (`cliffhanger_grabs_used = 0`), mereset kombo, dan memposisikan ulang kedua mecha pada titik spawn masing-masing.

6. **Automated Testing Suite**:
   - Dibuat `tests/test_match_rules.gd` dan `tests/test_match_rules.tscn`.
   - Validasi inisialisasi match (Ronde 1, skor 0-0, timer 90s).
   - Validasi kemenangan ronde via K.O.
   - Validasi kemenangan ronde via Ring-Out.
   - Validasi penentuan Match Winner (2 ronde menang).
   - Validasi evaluasi Time-Out berdasarkan perbandingan % HP.
   - Validasi babak Sudden Death (30 detik, 90% Heat aktif).

## Tasks / Subtasks

- [x] Task 1: Definisi Konstanta Pertandingan (AC: 1, 2, 4)
  - [x] 1.1 Tambahkan konstanta ROUND_TIME_SECONDS (90.0), SUDDEN_DEATH_SECONDS (30.0), ROUNDS_TO_WIN (2), dan SUDDEN_DEATH_STARTING_HEAT (90.0) di `combat_constants.gd`.
- [x] Task 2: Implementasi MatchManager Controller (AC: 1, 2, 3, 4, 5)
  - [x] 2.1 Buat `scripts/core/match_manager.gd` mewarisi `Node`.
  - [x] 2.2 Kelola state `MatchState` (IDLE, ROUND_ACTIVE, ROUND_OVER, SUDDEN_DEATH, MATCH_OVER).
  - [x] 2.3 Implementasikan evaluasi K.O., Ring-Out, dan Time-Out.
  - [x] 2.4 Implementasikan babak Sudden Death 30 detik dengan Heat 90%.
  - [x] 2.5 Implementasikan reset posisi dan stats mecha antar ronde.
- [x] Task 3: Automated Testing Suite (AC: 6)
  - [x] 3.1 Buat `tests/test_match_rules.gd` dan `tests/test_match_rules.tscn`.
  - [x] 3.2 Uji seluruh skenario transisi ronde, scoring, dan penentuan juara pertandingan.
