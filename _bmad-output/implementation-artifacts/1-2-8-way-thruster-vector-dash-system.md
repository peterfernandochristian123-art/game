---
baseline_commit: NO_VCS
---

# Story 1.2: 8-Way Thruster Vector Dash System

Status: done

## Story

As a player,
I want to execute an instant thruster dash in any of the 8 directions on the ground or in mid-air,
So that I can quickly reposition, dodge attacks, and close the distance with my opponent.

## Acceptance Criteria

1. **8-Way Directional Vector Resolution**:
   - Sistem membaca input arah joystick / D-Pad (WASD / Panah) saat tombol Dash ditekan.
   - Vektor arah dinormalisasi ke salah satu dari 8 arah kardinal / diagonal:
     - Kanan (`Vector2(1, 0)`), Kiri (`Vector2(-1, 0)`), Atas (`Vector2(0, -1)`), Bawah (`Vector2(0, 1)`),
     - Kanan-Atas (`Vector2(1, -1).normalized()`), Kanan-Bawah (`Vector2(1, 1).normalized()`),
     - Kiri-Atas (`Vector2(-1, -1).normalized()`), Kiri-Bawah (`Vector2(-1, 1).normalized()`).
   - Jika tombol Dash ditekan tanpa arah input stik/tombol (vektor nol), arah dash otomatis default mengarah ke arah hadap mecha saat itu (`facing_direction`, horizontal maju).
   - Di darat, dash bawah murni (`Vector2(0, 1)`) tidak memicu pergerakan tembus lantai (dibatasi horizontal atau dicegah).

2. **Dash Execution & Speed (14 Frame Duration)**:
   - Mecha meluncur dengan kecepatan tetap `DASH_SPEED = 750.0 px/s` (didefinisikan di `CombatConstants.DASH_SPEED`).
   - Durasi dash berlangsung tepat selama 14 frame fisika (`DASH_DURATION_FRAMES = 14`, setara ~233 ms pada 60 FPS).
   - Selama durasi 14 frame aktif dash, gravitasi dinonaktifkan sementara sehingga lintasan vektor dash tetap lurus dan presisi (termasuk dash udara diagonal/atas).
   - Begitu timer 14 frame berakhir, mecha bertransisi otomatis:
     - Jika berada di tanah: kembali ke `IdleState` (atau `WalkState` jika arah masih ditekan).
     - Jika berada di udara: kembali ke `FallState`.

3. **Air Dash Constraint (Maksimal 1 Kali di Udara)**:
   - Mecha dibatasi maksimal 1 kali Vector Dash di udara (`can_air_dash = false`) sebelum menyentuh tanah kembali.
   - Hak air dash di-reset (`can_air_dash = true`) secara otomatis begitu mecha mendarat di atas platform (`is_on_floor() == true`).

4. **Dash Cooldown (18 Frame Window)**:
   - Setelah dash selesai (frame ke-14), sistem menerapkan cooldown selama 18 frame fisika (`DASH_COOLDOWN_FRAMES = 18`, setara 300 ms).
   - Mecha tidak dapat mengeksekusi dash berikutnya hingga timer cooldown 18 frame selesai dihitung pada `_physics_process()`.

5. **State Machine Integration**:
   - Menambahkan state `DashState` (`res://scripts/combat/fsm/dash_state.gd`) dan `AirDashState` (`res://scripts/combat/fsm/air_dash_state.gd`) yang mewarisi `BaseState`.
   - Menghubungkan state baru ke node `StateMachine` di [scenes/test_arena.tscn](file:///c:/game/scenes/test_arena.tscn).
   - Logging diagnostik `[STATE][%s] Transisi ke Dash` / `AirDash` tercetak saat debug build.

---

## Tasks / Subtasks

- [x] Task 1: Vector Dash Direction & Input Handling (AC: 1)
  - [x] 1.1 Buat method helper `get_dash_vector() -> Vector2` pada `BaseMecha` yang membaca sumbu horizontal dan vertikal lalu mengembalikan vektor 8-arah ternormalisasi.
  - [x] 1.2 Implementasikan fallback arah hadap: jika input vector adalah `Vector2.ZERO`, gunakan `Vector2(facing_direction, 0.0)`.
  - [x] 1.3 Pastikan input mapping `dash` (tombol `Shift`, `Key X`, atau tombol gamepad) terdaftar di `BaseMecha._setup_input_fallbacks()`.

- [x] Task 2: Implementasi DashState (Ground Dash) (AC: 2, 4, 5)
  - [x] 2.1 Buat script `res://scripts/combat/fsm/dash_state.gd` (`class_name DashState extends "res://scripts/combat/fsm/base_state.gd"`).
  - [x] 2.2 Pada `enter()`: hitung arah dash, set `character.velocity = dash_direction * CombatConstants.DASH_SPEED`, reset frame counter `current_dash_frame = 0`.
  - [x] 2.3 Pada `physics_update(delta)`: inkremen `current_dash_frame`, pertahankan kecepatan konstan, dan transisi ke `IdleState` (atau `WalkState`) saat `current_dash_frame >= CombatConstants.DASH_DURATION_FRAMES`.
  - [x] 2.4 Pada `exit()`: mulai cooldown timer 18 frame pada mecha (`dash_cooldown_timer = CombatConstants.DASH_COOLDOWN_FRAMES`).

- [x] Task 3: Implementasi AirDashState & Batasan Udara (AC: 2, 3, 4, 5)
  - [x] 3.1 Buat script `res://scripts/combat/fsm/air_dash_state.gd` (`class_name AirDashState extends "res://scripts/combat/fsm/base_state.gd"`).
  - [x] 3.2 Pada `enter()`: tandai `character.can_air_dash = false`, set `character.velocity = dash_direction * CombatConstants.DASH_SPEED`, abaikan gravitasi.
  - [x] 3.3 Pada `physics_update(delta)`: inkremen frame counter, transisi ke `FallState` setelah 14 frame atau jika mecha menabrak lantai lebih awal.
  - [x] 3.4 Di `BaseMecha`, reset `can_air_dash = true` setiap kali `is_on_floor() == true`.

- [x] Task 4: Integrasi FSM & Transisi Input Dash (AC: 1, 5)
  - [x] 4.1 Tambahkan pengecekan input `is_dash_requested()` dan cooldown check di `idle_state.gd` dan `walk_state.gd` untuk transisi ke `DashState`.
  - [x] 4.2 Tambahkan pengecekan input `is_dash_requested()` dan kondisi `character.can_air_dash` di `jump_state.gd` dan `fall_state.gd` untuk transisi ke `AirDashState`.
  - [x] 4.3 Daftarkan node `Dash` dan `AirDash` di dalam `StateMachine` pada scene `scenes/test_arena.tscn`.

- [x] Task 5: Testing & Validasi Otomatis (AC: 1, 2, 3, 4, 5)
  - [x] 5.1 Buat script pengujian otomatis headless `tests/test_vector_dash.gd`.
  - [x] 5.2 Uji 8 arah vektor dash (kardinal & diagonal) serta fallback arah hadap.
  - [x] 5.3 Uji durasi dash 14 frame dan kecepatan 750 px/s.
  - [x] 5.4 Uji batasan 1x air dash dan reset saat menyentuh lantai.
  - [x] 5.5 Uji cooldown 18 frame (dash baru tidak bisa dipicu sebelum 18 frame).
  - [x] 5.6 Jalankan suite tes headless pada Godot 4 dan pastikan 100% lulus.

---

## Dev Notes

### Relevant Architecture Patterns and Constraints

1. **Konstanta Baku dari CombatConstants**:
   - `CombatConstants.DASH_SPEED = 750.0`
   - `CombatConstants.DASH_DURATION_FRAMES = 14`
   - `CombatConstants.DASH_COOLDOWN_FRAMES = 18`
   - Gunakan nilai dari `CombatConstants`, dilarang menaruh magic numbers langsung di dalam logika FSM.

2. **Isolasi Gravitasi saat Dash**:
   - Selama `DashState` dan `AirDashState` aktif, mecha **tidak boleh** dipengaruhi oleh percepatan gravitasi (`character.velocity.y += gravity * delta` dinonaktifkan). Kecepatan mecha harus murni ditentukan oleh `dash_direction * DASH_SPEED` agar lintasan dorongan jet lurus sempurna.

3. **Penanganan Cooldown Deterministik**:
   - Cooldown dash harus dihitung berbasis frame integer di `_physics_process()` (contoh: `dash_cooldown_frames -= 1` per tick 60 FPS) untuk menjamin determinisme dan mencegah desinkronisasi.

### Source Tree Components to Touch / Create

- **NEW**: `scripts/combat/fsm/dash_state.gd` (Ground Dash State)
- **NEW**: `scripts/combat/fsm/air_dash_state.gd` (Air Dash State)
- **UPDATE**: `scripts/characters/base_mecha.gd` (Menambahkan `can_air_dash`, `dash_cooldown_frames`, `get_dash_vector()`)
- **UPDATE**: `scripts/combat/fsm/idle_state.gd` (Mengecek transisi ke Dash)
- **UPDATE**: `scripts/combat/fsm/walk_state.gd` (Mengecek transisi ke Dash)
- **UPDATE**: `scripts/combat/fsm/jump_state.gd` (Mengecek transisi ke AirDash)
- **UPDATE**: `scripts/combat/fsm/fall_state.gd` (Mengecek transisi ke AirDash)
- **UPDATE**: `scenes/test_arena.tscn` (Menambahkan node Dash dan AirDash ke StateMachine)
- **NEW**: `tests/test_vector_dash.gd` (Test runner headless untuk validasi 8-arah, 14f durasi, air dash limit, dan 18f cooldown)
- **NEW**: `tests/test_vector_dash.tscn` (Scene test runner)

### Testing Standards Summary

- **Verifikasi Headless**:
  - `tests/test_vector_dash.gd` memverifikasi seluruh AC secara mekanis:
    1. Vektor 8 arah + fallback arah hadap.
    2. Kecepatan 750 px/s dan durasi tepat 14 frame.
    3. Batasan 1 air dash per airborne session.
    4. Cooldown 18 frame sebelum dash berikutnya dapat dipicu.
- **Verifikasi Interaktif**:
  - Tekan `Shift` atau `X` di darat: mecha melesat cepat ke arah joystick / hadap mecha.
  - Tekan `Shift` atau `X` di udara: mecha melesat ke arah yang ditekan, tidak bisa dash lagi sampai menyentuh platform.

---

### Project Structure Notes

- Struktur file mengikuti konvensi FSM: `scripts/combat/fsm/dash_state.gd` dan `air_dash_state.gd`.
- Penamaan class PascalCase: `class_name DashState`, `class_name AirDashState`.

---

### Project Context Rules

- Target engine: Godot Engine 4 (v4.7.2).
- Bahasa: GDScript statically typed.
- Canvas: 640x360.
- StateMachine fallback: Jika terjadi anomali, tetap fallback ke `IdleState`.

---

### References

- [GDD 8-Way Thruster Vector Dash](file:///c:/game/_bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/gdd.md#41-core-gameplay-loop--movement-mechanics)
- [Architecture State Machine](file:///c:/game/_bmad-output/game-architecture.md#1-hierarchical-state-machine-mecha-hsm)
- [Epic 1 Story 1.2 Breakdown](file:///c:/game/_bmad-output/planning-artifacts/epics.md#story-12-8-way-thruster-vector-dash-system)
- [CombatConstants](file:///c:/game/scripts/combat/combat_constants.gd)
- [BaseMecha](file:///c:/game/scripts/characters/base_mecha.gd)

---

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Melanjutkan baseline dari Story 1.1.
- Unit & Integration Test Suite: `tests/test_vector_dash.gd` (5/5 tes lulus 100%).
  - Test 1: 8-Way Vector Resolution, zero-input fallback to `facing_direction`, ground pure-down floor constraint.
  - Test 2: Ground Dash execution, velocity `750 px/s`, 14-frame duration lock, gravity isolation, and transition to Idle.
  - Test 3: Air Dash execution, single-use air dash restriction (`can_air_dash = false`), landing reset.
  - Test 4: 18-frame deterministic cooldown tick-down and re-dash prevention.
  - Test 5: FSM integration in `scenes/test_arena.tscn` with `DashState` and `AirDashState` attached.
- Regression Suite: `tests/test_movement_fsm.gd` (5/5 tes lulus 100%).

### Completion Notes List

- Mengimplementasikan helper `resolve_dash_vector()` dan `get_dash_vector()` pada `BaseMecha`, menangani 8 arah vektor ternormalisasi, fallback arah hadap horizontal maju jika input nol, dan pembatasan pure down di darat.
- Mendaftarkan keybinding `dash` ke tombol `Shift` dan `Key X`.
- Mengimplementasikan `DashState` (`scripts/combat/fsm/dash_state.gd`) dengan durasi 14 frame, kecepatan 750 px/s, isolasi gravitasi, transisi ke Idle/Walk, dan trigger cooldown 18 frame.
- Mengimplementasikan `AirDashState` (`scripts/combat/fsm/air_dash_state.gd`) dengan batasan maksimal 1x per sesi melayang, auto-reset saat menyentuh platform (`is_on_floor()`), dan transisi ke FallState saat durasi berakhir.
- Mengintegrasikan transisi Dash dan AirDash ke dalam `IdleState`, `WalkState`, `JumpState`, dan `FallState`.
- Menambahkan node `Dash` dan `AirDash` ke scene `scenes/test_arena.tscn` serta memperbarui instruksi kontrol HUD.
- Menulis dan mengeksekusi test runner otomatis `tests/test_vector_dash.gd` dengan hasil 5/5 lulus.

### File List

- `scripts/characters/base_mecha.gd`
- `scripts/combat/fsm/dash_state.gd`
- `scripts/combat/fsm/air_dash_state.gd`
- `scripts/combat/fsm/idle_state.gd`
- `scripts/combat/fsm/walk_state.gd`
- `scripts/combat/fsm/jump_state.gd`
- `scripts/combat/fsm/fall_state.gd`
- `scenes/test_arena.tscn`
- `tests/test_vector_dash.gd`
- `tests/test_vector_dash.tscn`
- `tests/test_movement_fsm.gd`

### Change Log

- 2026-10-17: Implementasi lengkap Story 1.2 (8-Way Thruster Vector Dash System) dengan unit & regression test 100% passing dan status transisi ke review.

