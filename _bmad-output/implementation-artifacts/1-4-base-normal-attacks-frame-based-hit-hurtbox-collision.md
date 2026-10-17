---
baseline_commit: NO_VCS
---

# Story 1.4: Base Normal Attacks & Frame-Based Hit/Hurtbox Collision

Status: done

## Story

As a player,
I want to perform light and heavy normal attacks with precise hit detection against the opponent's hurtbox,
So that I can engage in close-range footsies and start basic offensive pressure.

## Acceptance Criteria

1. **Light & Heavy Normal Attack Frame Data**:
   - Menambahkan attack definition deterministik di `CombatConstants`:
     - **Light Normal (5L)**: Startup 5 frame, Active 3 frame, Recovery 8 frame (Total 16 frame), Damage 40, Hitstun 14 frame, Knockback 120 px/s.
     - **Heavy Normal (5H)**: Startup 10 frame, Active 4 frame, Recovery 16 frame (Total 30 frame), Damage 90, Hitstun 22 frame, Knockback 260 px/s.
   - Serangan dipicu dari `IdleState` atau `WalkState` melalui tombol aksi `attack_light` (Key J / Key Z) dan `attack_heavy` (Key K / Key C).

2. **Frame-Accurate Hitbox & Hurtbox Collision (Layer 2 & Layer 3)**:
   - Komponen `Hurtbox` (`Area2D`) pada mecha terkonfigurasi di `collision_layer = CombatConstants.LAYER_HURTBOX` (Layer 2) dan `collision_mask = 0`.
   - Komponen `Hitbox` (`Area2D`) pada mecha terkonfigurasi di `collision_layer = CombatConstants.LAYER_STRIKE_HITBOX` (Layer 3) dan `collision_mask = 1 << (CombatConstants.LAYER_HURTBOX - 1)` (Layer 2).
   - Pemantauan `monitoring` / `monitorable` pada node Hitbox **hanya diaktifkan secara eksklusif** selama jendela `active_frames` serangan berjalan, dan otomatis dinonaktifkan pada fase startup dan recovery.

3. **Hit Confirmation & EventBus Dispatch**:
   - Saat node Hitbox mendeteksi kontak dengan Hurtbox lawan:
     - Memancarkan sinyal global `EventBus.hit_confirmed.emit(attacker, victim, hit_data)`.
     - Mecha lawan menerima pengurangan HP sesuai nilai damage serangan.
     - Satu serangan hanya dapat mengenai lawan maksimal 1 kali per aktivasi (*hit registration lock*).

4. **HitstunState & FSM Integration**:
   - Menambahkan state `AttackState` (`scripts/combat/fsm/attack_state.gd`) dan `HitstunState` (`scripts/combat/fsm/hitstun_state.gd`).
   - Saat terkena pukulan, lawan dipaksa bertransisi seketika ke `HitstunState`.
   - Selama durasi `hitstun_frames`, lawan terkunci (tidak dapat bergerak, menyerang, atau dash) dan menerima dorongan *knockback*.
   - Begitu durasi hitstun selesai, mecha otomatis kembali ke `IdleState` (jika di lantai) atau `FallState` (jika di udara).

5. **Testing & Validasi Headless Otomatis**:
   - Membuat script pengujian headless `tests/test_combat_attacks.gd`.
   - Menguji keakuratan fase startup, active, dan recovery pada frame rate 60 FPS.
   - Menguji bahwa hitbox tidak memicu damage pada fase startup maupun recovery.
   - Menguji kontak Hitbox -> Hurtbox, pengurangan HP, emisi sinyal `EventBus`, transisi lawan ke `HitstunState`, dan pemulihan kembali ke `IdleState`.

---

## Tasks / Subtasks

- [x] Task 1: Frame Data & Hitbox/Hurtbox Components (AC: 1, 2)
  - [x] 1.1 Definisikan parameter frame data `LIGHT_ATTACK` dan `HEAVY_ATTACK` di `CombatConstants`.
  - [x] 1.2 Buat node komponen `Hitbox` dan `Hurtbox` pada `BaseMecha` dengan layer 2D physics Layer 2 dan Layer 3.
  - [x] 1.3 Daftarkan keybinding `attack_light` (Key J, Key Z) dan `attack_heavy` (Key K, Key C) di `BaseMecha._setup_input_fallbacks()`.

- [x] Task 2: Implementasi AttackState & Jendela Frame Aktif (AC: 1, 2, 3)
  - [x] 2.1 Buat script `scripts/combat/fsm/attack_state.gd` (`class_name AttackState extends BaseState`).
  - [x] 2.2 Pada `enter()`: reset frame counter dan hit list, nonaktifkan hitbox.
  - [x] 2.3 Pada `physics_update()`: aktifkan hitbox tepat pada jendela `startup <= frame < startup + active`, lalu nonaktifkan pada fase recovery.
  - [x] 2.4 Saat frame mencapai total durasi: transisi kembali ke `IdleState` (atau `FallState`).

- [x] Task 3: Implementasi HitstunState & Reaksi Kena Pukulan (AC: 3, 4)
  - [x] 3.1 Buat script `scripts/combat/fsm/hitstun_state.gd` (`class_name HitstunState extends BaseState`).
  - [x] 3.2 Implementasikan method `take_hit(attacker: Node2D, hit_data: Dictionary)` pada `BaseMecha`.
  - [x] 3.3 Pada `take_hit()`: kurangi HP, terapkan knockback, transisi FSM ke `HitstunState`, dan pancarkan `EventBus.hit_confirmed`.
  - [x] 3.4 Pada `HitstunState.physics_update()`: hitung mundur durasi hitstun dan redam knockback horizontal.

- [x] Task 4: Integrasi FSM & Scene Arena (AC: 1, 4)
  - [x] 4.1 Tambahkan pengecekan input `attack_light` dan `attack_heavy` pada `IdleState` dan `WalkState`.
  - [x] 4.2 Tambahkan dummy target mecha / opponent node di `scenes/test_arena.tscn` untuk pengujian footsies langsung.
  - [x] 4.3 Daftarkan node `Attack` dan `Hitstun` ke dalam `StateMachine`.

- [x] Task 5: Testing Otomatis & Regresi Suite (AC: 1, 2, 3, 4, 5)
  - [x] 5.1 Buat test runner `tests/test_combat_attacks.gd` dan `tests/test_combat_attacks.tscn`.
  - [x] 5.2 Uji akurasi frame data startup/active/recovery.
  - [x] 5.3 Uji deteksi tabrakan hitbox -> hurtbox dan transisi hitstun.
  - [x] 5.4 Jalankan seluruh test suite Story 1.1, 1.2, 1.3, dan 1.4 dan pastikan 100% lulus.

---

## Dev Notes

### Relevant Architecture Patterns and Constraints

1. **Matrix Collision Layer**:
   - `Layer 2 (Hurtbox)`: area tubuh mecha yang dapat menerima serangan.
   - `Layer 3 (StrikeHitbox)`: volume tebasan/pukulan fisik.
   - Hitbox mask menargetkan Layer 2 secara presisi.

2. **Pencegahan Multi-Hit Tak Sengaja**:
   - Hitbox menyimpan daftar target yang sudah dikenai (`hit_targets: Array[Node2D]`) selama satu kali masa serang aktif agar tidak terjadi pukulan berkali-kali di setiap frame aktif.

---

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Semua test suite Story 1.4 (`test_combat_attacks.tscn`) lulus 5/5.
- Regresi suite Story 1.1, 1.2, dan 1.3 berjalan sukses 100%.

### Completion Notes List

- `CombatConstants` memuat frame data `LIGHT_ATTACK` (5/3/8) dan `HEAVY_ATTACK` (10/4/16) dengan hitstun dan knockback presisi.
- `AttackState` mengelola aktivasi hitbox eksklusif pada frame aktif dan mencegah multi-hit registration.
- `HitstunState` mengunci aksi karakter, menerapkan redaman horizontal knockback, dan memulihkan karakter ke Idle/Fall.
- `BaseMecha` dilengkapi komponen Hurtbox (Layer 2) dan Hitbox (Layer 3), handler `take_hit()`, `request_attack()`, serta keybinding J/Z (Light) dan K/C (Heavy).
- `scenes/test_arena.tscn` diperbarui dengan node `Attack`, `Hitstun`, dummy mecha opponent untuk uji coba pukulan, dan HUD instruction.

### File List

- `scripts/combat/combat_constants.gd`
- `scripts/characters/base_mecha.gd`
- `scripts/combat/fsm/attack_state.gd`
- `scripts/combat/fsm/hitstun_state.gd`
- `scripts/combat/fsm/idle_state.gd`
- `scripts/combat/fsm/walk_state.gd`
- `project.godot`
- `scenes/test_arena.tscn`
- `tests/test_combat_attacks.gd`
- `tests/test_combat_attacks.tscn`

### Change Log

- 2026-10-17: Story 1.4 diimplementasikan, diverifikasi 5/5, dan ditandai `done`.

