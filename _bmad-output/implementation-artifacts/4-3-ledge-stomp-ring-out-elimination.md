---
baseline_commit: 742b211
---

# Story 4.3: Ledge Stomp & Ring-Out Elimination

Status: review

## Story

As an aggressive player controlling the center stage,
I want to perform a downward ledge stomp on an opponent hanging from the platform edge,
So that I can score an instant Ring-Out victory.

## Acceptance Criteria

1. **Jurus Ledge Stomp (Down + Heavy/Attack)**:
   - Resource: `resources/attacks/ledge_stomp.tres` (Startup 15 frame, Active 4 frame, Recovery 20 frame, Damage 120, Knockback 400.0, `is_ledge_stomp = true`, `is_unblockable = true`).
   - Tersedia di `BaseMecha.attack_resources[&"LedgeStomp"]`.

2. **Instant Ring-Out pada Lawan Bergelantungan (Cliffhanger)**:
   - Jika serangan `is_ledge_stomp` mengenai lawan yang sedang berada dalam status `CliffhangerState`, lawan seketika kehilangan cengkeraman, HP diset ke 0, dan tereliminasi dengan status *Ring-Out* (`eliminate_by_ring_out()`).
   - Sinyal `ring_out_eliminated` dipancarkan ke sistem dan diteruskan ke `EventBus.round_ended`.

3. **Eliminasi Jatuh Bebas (Fall Off Arena Boundaries)**:
   - Jika mecha mana pun jatuh melewati batas bawah Y arena (`global_position.y > CombatConstants.RING_OUT_KILL_Y` atau Y > 600 px), mecha langsung tereliminasi via Ring-Out.
   - Terintegrasi baik di `BaseMecha._physics_process()` maupun di loop pemantau `ArenaSkyscraper`.

4. **Automated Testing Suite**:
   - Dibuat `tests/test_ledge_stomp_ring_out.gd` dan `tests/test_ledge_stomp_ring_out.tscn`.
   - Validasi parameter frame data `ledge_stomp.tres` (Startup 15f, Active 4f, Recovery 20f).
   - Validasi eksekusi instant kill Ledge Stomp terhadap korban di `CliffhangerState`.
   - Validasi deteksi Ring-Out otomatis saat koordinat Y melampaui 600 px.
   - Validasi bahwa serangan biasa (non-stomp) pada musuh di tebing tidak memicu instant kill.

## Tasks / Subtasks

- [x] Task 1: Resource Setup & Attack Definition (AC: 1)
  - [x] 1.1 Tambahkan flag `is_ledge_stomp` pada `scripts/combat/resources/attack_data.gd`.
  - [x] 1.2 Buat Resource `resources/attacks/ledge_stomp.tres`.
- [x] Task 2: Implementasi Eliminasi Ring-Out & Ledge Stomp (AC: 2, 3)
  - [x] 2.1 Tambahkan `eliminate_by_ring_out()`, `is_eliminated`, dan `signal ring_out_eliminated` di `BaseMecha`.
  - [x] 2.2 Tangani logika instant kill saat terkena Ledge Stomp di `take_hit()` saat dalam `CliffhangerState`.
  - [x] 2.3 Tambahkan evaluasi posisi Y > 600.0 pada `BaseMecha` dan `ArenaSkyscraper`.
- [x] Task 3: Automated Testing Suite (AC: 4)
  - [x] 3.1 Buat `tests/test_ledge_stomp_ring_out.gd` dan `tests/test_ledge_stomp_ring_out.tscn`.
  - [x] 3.2 Uji frame data, instant kill pada cliffhanger, fall kill Y, dan toleransi hit biasa.
