---
baseline_commit: 941d0ea
---

# Story 2.4: Normal Blocking & Chip Damage Mechanics

Status: review

## Story

As a defensive player,
I want to guard against enemy attacks by holding the direction away from the opponent,
so that I can safely mitigate normal physical damage and survive offensive strings.

## Acceptance Criteria

1. **Deteksi Input Blok Mundur (Backward Guard / Holding Away)**:
   - Mecha mendeteksi input arah horizontal pemain berlawanan dari posisi relatif lawan (Backward Block):
     - Jika penyerang berada di sebelah kiri mecha (`attacker.x < mecha.x`), menahan kanan (`input_x > 0.2`).
     - Jika penyerang berada di sebelah kanan mecha (`attacker.x > mecha.x`), menahan kiri (`input_x < -0.2`).
   - Blocking hanya valid saat mecha dapat bertahan (status netral di tanah `Idle`, `Walk`, atau sedang dalam `Blockstun` menghadapi kombo beruntun/block-string).
   - Mecha tidak dapat melakukan block saat sedang menyerang (`Attack`), dash (`Dash`/`AirDash`), whiff parry (`Parry`), atau `Meltdown`.

2. **Mitigasi Kerusakan (100% Fisik vs 20% Chip Energi)**:
   - **Serangan Fisik Normal:** Kerusakan diredam 100% (`damage = 0`). HP mecha tidak berkurang sama sekali.
   - **Serangan Energi / Skill:** Mecha menerima 20% chip damage dari total nilai damage serangan (`damage = int(round(float(base_damage) * CombatConstants.CHIP_DAMAGE_RATIO))`).

3. **Status Blockstun (BlockstunState)**:
   - Saat serangan berhasil ditangkis dengan block, mecha beralih ke `BlockstunState` (`scripts/combat/fsm/blockstun_state.gd`).
   - Durasi blockstun ditentukan oleh parameter serangan (`hit_data.get("blockstun", 10)` frame data, contoh: 5L = 10 frame, 5H = 16 frame).
   - Selama durasi blockstun, mecha terkunci dari aksi lain namun tetap dapat menerima input buffer untuk aksi berikutnya saat blockstun berakhir.
   - Mecha menerima dorongan knockback teredam (60% dari knockback unblocked normal).
   - Setelah durasi frame blockstun selesai, mecha otomatis kembali ke `Idle` (atau `Fall` jika di udara).

4. **Konstanta & Integrasi Arsitektur**:
   - Di `CombatConstants`:
     - `CHIP_DAMAGE_RATIO: float = 0.20`
     - `DEFAULT_BLOCKSTUN_FRAMES: int = 10`
     - `BLOCK_KNOCKBACK_MULTIPLIER: float = 0.60`
   - Di `BaseMecha`:
     - `can_block() -> bool`
     - `is_holding_block(attacker: Node2D) -> bool`
     - `take_hit(attacker: Node2D, hit_data: Dictionary)` mengecek kondisi block sebelum mengaplikasikan full damage & hitstun.
     - Daftarkan `BlockstunState` di `_setup_fsm_states()`.
     - Update HUD status label saat di `Blockstun`.

5. **Automated Testing Suite**:
   - Buat `tests/test_blocking_chip.gd` dan `tests/test_blocking_chip.tscn`.
   - Uji mitigasi 100% serangan fisik normal.
   - Uji kalkulasi 20% chip damage pada serangan berbasis energi.
   - Uji arah input blok (holding away berhasil block, holding toward gagal block).
   - Uji durasi blockstun dan pemulihan deterministik ke `Idle`.
   - Uji block-string (bertahan saat sudah dalam `Blockstun`).
   - Uji pembatasan (tidak dapat block saat sedang menyerang atau dash).

## Tasks / Subtasks

- [x] Task 1: Konstanta & Logika Blocking (AC: 1, 2, 4)
  - [x] 1.1 Tambahkan konstanta blocking & chip damage di `CombatConstants`.
  - [x] 1.2 Implementasikan helper `can_block()` dan `is_holding_block(attacker: Node2D)` di `BaseMecha`.
- [x] Task 2: Implementasi BlockstunState (AC: 3)
  - [x] 2.1 Buat `scripts/combat/fsm/blockstun_state.gd` (`class_name BlockstunState extends BaseState`).
  - [x] 2.2 Kelola durasi blockstun deterministik dan peluruhan knockback horizontal.
  - [x] 2.3 Daftarkan `BlockstunState` di `BaseMecha._setup_fsm_states()`.
- [x] Task 3: Integrasi Combat & Damage Mitigation (AC: 2, 3, 4)
  - [x] 3.1 Perbarui `BaseMecha.take_hit()` untuk mengalihkan ke blocking jika pemain menahan block.
  - [x] 3.2 Terapkan mitigasi damage 100% untuk fisik dan 20% chip damage untuk energi.
  - [x] 3.3 Terapkan knockback teredam (60%) dan transisi ke `BlockstunState`.
  - [x] 3.4 Perbarui visual status HUD saat mecha berada di `Blockstun`.
- [x] Task 4: Automated Testing Suite & Validasi (AC: 5)
  - [x] 4.1 Buat `tests/test_blocking_chip.gd` + `tests/test_blocking_chip.tscn`.
  - [x] 4.2 Jalankan validasi pengujian otomatis seluruh acceptance criteria.
  - [x] 4.3 Verifikasi regresi suite Story 1.1–2.3.
