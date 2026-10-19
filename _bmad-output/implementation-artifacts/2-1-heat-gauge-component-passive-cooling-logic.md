---
baseline_commit: ee90e1827dc2eae07d3f7e781fc74f7cfdc80f1a
---

# Story 2.1: Heat Gauge Component & Passive Cooling Logic

Status: review

## Story

As a player,
I want every attack and dash action to build internal heat that gradually cools down when standing or walking,
so that I must strategically manage my actions to balance aggression with thermal safety.

## Acceptance Criteria

1. **HeatComponent (rentang 0–100%)**:
   - Buat `HeatComponent` (`scripts/combat/components/heat_component.gd`, `class_name HeatComponent extends Node`) dengan `current_heat` (float) dibatasi `0.0 … 100.0`.
   - Memancarkan sinyal lokal `heat_changed(current: float, max_val: float)` setiap kali nilai berubah (naik maupun turun).

2. **Penambahan Panas dari Aksi**:
   - Aksi **Dash** (`DashState` dan `AirDashState`, saat `enter()`): `+10.0%` heat per dash.
   - Aksi **Skill ofensif**: `+15%` hingga `+35%` (nilai per skill). Skill belum ada (Epic 3), maka sediakan API `add_heat(amount)` dan konstanta `SKILL_HEAT_MIN = 15.0` / `SKILL_HEAT_MAX = 35.0` yang bisa dipakai Epic 3. **Normal attack (5L/5H) tidak menambah heat** (lihat Pertanyaan Terbuka).
   - Heat tidak boleh melebihi 100.0 (clamp). Pemicu Meltdown di 100% **di luar scope** (Story 2.2) — cukup pancarkan `meltdown_triggered` saat mencapai 100.0 sebagai hook kosong yang aman.

3. **Pendinginan Pasif**:
   - Saat state aktif adalah `Idle` atau `Walk`, heat berkurang `-12%/detik` = `-0.2` per physics frame (`PASSIVE_COOLING_PER_FRAME = 12.0 / 60.0`).
   - Tidak ada pendinginan di state lain (Jump, Fall, Dash, AirDash, Attack, Hitstun). Heat tidak boleh < 0.
   - Deterministik di `_physics_process` 60 FPS, tanpa `delta`.

4. **Integrasi BaseMecha & HUD**:
   - `BaseMecha` memiliki `heat_component` (dibuat otomatis di `_ready()` bila node `HeatComponent` belum ada, pola sama dengan `_setup_combat_colliders()`).
   - Field lama `heat_gauge` pada `BaseMecha` tetap bekerja (HUD `_update_hud()` membacanya): sinkronkan `heat_gauge` dari sinyal `heat_changed` agar tidak ada regresi HUD.
   - Pancarkan juga event global bila perlu lintas sistem; minimal sinyal lokal sudah cukup (arsitektur: komponen → root via sinyal lokal).

5. **Testing Headless Otomatis**:
   - Buat `tests/test_heat_component.gd` + `tests/test_heat_component.tscn`.
   - Uji: clamp 0–100, emisi `heat_changed`, dash +10 (ground & air), pendinginan tepat `-0.2/frame` di Idle/Walk (60 frame = -12.0), tanpa pendinginan di state lain, tidak < 0, `meltdown_triggered` terpancar di 100.
   - Seluruh suite Story 1.1–1.4 tetap lulus 100%.

## Tasks / Subtasks

- [x] Task 1: HeatComponent & Konstanta (AC: 1, 2, 3)
  - [x] 1.1 Tambah konstanta di `CombatConstants`: `MAX_HEAT = 100.0`, `DASH_HEAT_COST = 10.0`, `SKILL_HEAT_MIN = 15.0`, `SKILL_HEAT_MAX = 35.0`, `PASSIVE_COOLING_PER_SECOND = 12.0`, `PASSIVE_COOLING_PER_FRAME = 12.0 / 60.0`.
  - [x] 1.2 Buat `scripts/combat/components/heat_component.gd` dengan `add_heat()`, `cool_down_frame()` / `process_frame(can_cool: bool)`, `reset()`, sinyal `heat_changed`, `meltdown_triggered`.
  - [x] 1.3 Buat folder `scripts/combat/components/` (+ `.gitkeep` jika kosong).
- [x] Task 2: Integrasi BaseMecha (AC: 4)
  - [x] 2.1 Tambah `var heat_component: HeatComponent`, buat otomatis di `_ready()`.
  - [x] 2.2 Hubungkan `heat_changed` → perbarui `heat_gauge`.
  - [x] 2.3 Di `_physics_process()`: panggil `heat_component.process_frame(can_cool)` dengan `can_cool = state aktif ∈ {Idle, Walk}` (jalankan SEBELUM/ SESUDAH `state_machine.physics_update`, tetapkan satu urutan dan dokumentasikan).
- [x] Task 3: Heat dari Dash (AC: 2)
  - [x] 3.1 `DashState.enter()` dan `AirDashState.enter()` memanggil `character.heat_component.add_heat(DASH_HEAT_COST)` (guard `has` / null-safe, karena dummy test bisa tanpa komponen).
- [x] Task 4: Test (AC: 5)
  - [x] 4.1 Buat `tests/test_heat_component.gd/.tscn` mengikuti pola `test_combat_attacks.gd` (log ke `res://test_heat_results.txt`).
  - [x] 4.2 Jalankan seluruh suite 1.1–1.4 + suite baru, pastikan 100% lulus.

### Review Findings

- [x] [Review][Defer] Dua sumber kebenaran heat maksimum (`BaseMecha.max_heat` vs `CombatConstants.MAX_HEAT`) — deferred. Alasan: nilai keduanya sama (100); tangani saat ada karakter dengan heat maksimum berbeda.
- [x] [Review][Patch] `heat_component` kini bertipe `HeatComponentScript` [scripts/characters/base_mecha.gd:37]
- [x] [Review][Patch] Tes `_test_physics_process_cooling` ditambahkan + komentar urutan cooling [scripts/characters/base_mecha.gd:223]
- [x] [Review][Patch] project.godot dikembalikan (`git checkout`), noise editor dibuang [project.godot]
- [x] [Review][Defer] File `test_*_results.txt` dan `*.uid`/`*.import` ikut terlacak/berubah di git — deferred, pre-existing

## Dev Notes

### Kondisi Kode Saat Ini (file yang disentuh — baca penuh sebelum edit)

- [`scripts/characters/base_mecha.gd`](../../scripts/characters/base_mecha.gd) (UPDATE): sudah memiliki `max_heat: float = 100.0` dan `heat_gauge: float = 0.0`; `_update_hud()` membaca `heat_gauge` ke `HUD/HeatBar` & `HeatLabel`. `_physics_process()` urutannya: `tick_cooldowns()` → deteksi ledge/coyote → `state_machine.physics_update(delta)` → `move_and_slide()` → `_update_hud()`. **Pertahankan** semua perilaku ini (dash cooldown, coyote, air dash reset, hitbox/hurtbox, `take_hit`).
- [`scripts/combat/combat_constants.gd`](../../scripts/combat/combat_constants.gd) (UPDATE): `extends RefCounted`; konstanta dash, frame data `LIGHT_ATTACK`/`HEAVY_ATTACK`. Tambahkan konstanta heat tanpa mengubah yang ada.
- [`scripts/combat/fsm/dash_state.gd`](../../scripts/combat/fsm/dash_state.gd) dan [`air_dash_state.gd`](../../scripts/combat/fsm/air_dash_state.gd) (UPDATE): `enter()` mengatur arah & velocity; `exit()` memulai cooldown 18 frame. Tambahkan heat **hanya di `enter()`**. Jangan ubah durasi/kecepatan.
- `idle_state.gd`, `walk_state.gd`: tidak perlu diubah; pendinginan ditentukan dari nama state aktif di `BaseMecha`.
- `DummyTarget` di `scenes/test_arena.tscn` adalah `BaseMecha` tanpa state Dash/Walk; komponen heat dibuat otomatis, tidak boleh error.
- State machine memakai nama node: `Idle`, `Walk`, `Jump`, `Fall`, `Dash`, `AirDash`, `Attack`, `Hitstun` (cek `state_machine.current_state.name`).

### Pola & Batasan Arsitektur

- Referensi implementasi di [`_bmad-output/game-architecture.md`](../game-architecture.md) (bagian HeatComponent): `PASSIVE_COOLING_PER_FRAME = 12.0 / 60.0`, `process_frame(can_cool)`, `add_heat()`, sinyal `heat_changed(current, max_val)`. Gunakan itu sebagai dasar, tetapi **gunakan indentasi TAB** (proyek GDScript memakai tab; contoh arsitektur memakai spasi).
- Komunikasi: komponen → mecha via sinyal lokal; lintas domain via `EventBus` (autoload). Jangan menambah autoload baru.
- Naming: file `snake_case.gd`, sinyal `past_tense_snake_case`, konstanta `UPPER_SNAKE_CASE`.
- Gunakan `const CombatConstants = preload("res://scripts/combat/combat_constants.gd")` seperti file lain (pola preload eksplisit dipakai di seluruh proyek).
- Determinisme: hitung per physics frame, bukan `delta` (tick 60 FPS tetap).
- Jangan implementasi Overclock (80–99%) atau Meltdown state — itu Story 2.2. Cukup siapkan `meltdown_triggered` dan flag `is_overclocked` bila murah, tanpa efek gameplay.

### Pelajaran dari Story 1.4

- Test headless dibuat sebagai scene runner (`tests/*.tscn`) yang menulis hasil ke file teks di root; ikuti pola yang sama dan jalankan dengan `godot --headless --path . res://tests/<scene>.tscn`.
- Konstruksi mecha di test dilakukan manual (BaseMecha + StateMachine + node state) — pastikan test heat tidak bergantung pada scene arena.
- Hati-hati dengan `get_node_or_null` / `has_method` guard yang dipakai luas; pertahankan gaya defensif ini agar dummy tidak crash.
- Terdapat dua salinan proyek (`/` dan `fighting-to-zero/`); **kerjakan di root** (versi lebih baru, `run/main_scene=res://scenes/test_arena.tscn`).

### Project Structure Notes

- File baru: `scripts/combat/components/heat_component.gd`, `tests/test_heat_component.gd`, `tests/test_heat_component.tscn`.
- File diubah: `base_mecha.gd`, `combat_constants.gd`, `dash_state.gd`, `air_dash_state.gd`.
- Struktur sesuai arsitektur (`scripts/combat/components/heat_component.gd`).

### Project Context Rules

- Tidak ada `project-context.md` di repo ini. Gunakan konvensi dari arsitektur dan pola kode Story 1.1–1.4. Bahasa komentar kode & dokumen: Indonesia.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1: Heat Gauge Component & Passive Cooling Logic]
- [Source: _bmad-output/game-architecture.md — Thermal Engine / HeatComponent, Naming Conventions]
- [Source: _bmad-output/implementation-artifacts/1-4-base-normal-attacks-frame-based-hit-hurtbox-collision.md]
- [Source: _bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/gdd.md — FR4 Heat Gauge]

### Pertanyaan Terbuka (untuk konfirmasi)

1. Apakah normal attack (5L/5H) harus menambah heat? Epic hanya menyebut Dash dan "Skill ofensif"; story ini mengasumsikan **tidak**.
2. Berapa heat per skill spesifik (15–35%) — akan ditentukan di Story 3.x.

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

- Godot 4.7.2 headless: `tests/test_heat_component.tscn` lulus 9/9.
- Regresi: Story 1.1 (5/5), 1.2 (5/5), 1.3 (5/5), 1.4 (5/5) lulus 100%. Pesan ERROR FSM di log berasal dari skenario tes lama (state sengaja tidak terdaftar), bukan dari story ini.

### Completion Notes List

- `HeatComponent` (0-100, clamp, `heat_changed`, hook `meltdown_triggered`) dibuat; pendinginan -0.2/frame hanya di Idle/Walk, dipanggil di `BaseMecha._physics_process` setelah `state_machine.physics_update`.
- `BaseMecha` membuat komponen otomatis dan menyinkronkan `heat_gauge` (HUD lama tetap bekerja); `add_heat()` tersedia untuk skill Epic 3.
- Dash dan AirDash menambah +10 heat di `enter()`. Normal attack tidak menambah heat (sesuai asumsi story; belum dikonfirmasi user).
- Overclock/Meltdown state tidak diimplementasikan (Story 2.2).

### File List

- scripts/combat/components/heat_component.gd (baru)
- scripts/combat/combat_constants.gd
- scripts/characters/base_mecha.gd
- scripts/combat/fsm/dash_state.gd
- scripts/combat/fsm/air_dash_state.gd
- tests/test_heat_component.gd (baru)
- tests/test_heat_component.tscn (baru)

### Change Log

- 2026-10-19: Story 2.1 diimplementasikan, diverifikasi 9/9 + regresi 1.1-1.4, status review.