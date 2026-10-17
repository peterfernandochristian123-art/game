---
baseline_commit: NO_VCS
---

# Story 1.1: Project Setup, Autoload Infrastructure & Movement State Machine

Status: done

## Story

As a player,
I want to move my mecha horizontally (walk) and jump with responsive 2D physics,
So that I can position my mecha reliably on the combat platform.

## Acceptance Criteria

1. **Autoload Infrastructure Setup**:
   - Singleton global Autoload `EventBus` (`res://scripts/core/event_bus.gd`) terdaftar dan aktif di `project.godot`.
   - Singleton global Autoload `InputBuffer` (`res://scripts/core/input_buffer.gd`) terdaftar minimal sebagai stub infrastruktur buffer siap pakai.
   - Konstanta tempur `res://scripts/combat/combat_constants.gd` diimplementasikan dengan nilai baku 60 FPS tick, kecepatan jalan dasar, gravitasi, dan batas arena.
   - Konfigurasi nama layer collision 2D diatur di `project.godot` (Layer 1: World, Layer 2: Hurtbox, Layer 3: Strike Hitbox, Layer 4: Grab Hitbox, Layer 5: Ledge Sensor).

2. **Hierarchical Finite State Machine (HSM / FSM) Foundation**:
   - Class abstrak `BaseState` (`res://scripts/combat/fsm/base_state.gd`) mewarisi `Node` dengan method siklus hidup: `enter()`, `exit()`, `physics_update(delta: float) -> void`, dan `handle_input(event: InputEvent) -> void`.
   - Node `StateMachine` (`res://scripts/combat/fsm/state_machine.gd`) mengelola dictionary state yang terdaftar, state saat ini (`current_state`), transisi aman `change_state(target_state: StringName)`, dan memiliki mekanisme fallback otomatis ke `IdleState` jika nama state tidak valid tanpa melempar crash runtime.

3. **Core Movement States Implementation**:
   - `IdleState`: Karakter berada di tanah (`is_on_floor() == true`), `velocity.x` didegradasi menuju 0 tanpa sliding liar, siap bertransisi ke `WalkState` atau `JumpState`.
   - `WalkState`: Karakter bergerak horizontal ke kiri atau kanan dengan kecepatan jalan konsisten (default `280.0 px/s`, rentang 260–350 px/s sesuai spesifikasi Viper/Bulwark), memperbarui arah visual (`facing_direction`), dan bertransisi kembali ke `IdleState` jika tidak ada input arah atau ke `JumpState` jika tombol lompat ditekan.
   - `JumpState`: Mecha menerima impuls vertikal instan `JUMP_VELOCITY = -420.0 px/s`, transisi ke `FallState` begitu `velocity.y > 0.0`.
   - `FallState`: Mecha menerima percepatan gravitasi (`GRAVITY = 980.0 px/s²`), dapat mempertahankan kontrol arah horizontal di udara, dan bertransisi kembali ke `IdleState` (atau `WalkState` jika arah ditahan) saat menyentuh platform (`is_on_floor()`).

4. **Mecha Controller Integration & Determinisme 60 FPS**:
   - Controller mecha modular `BaseMecha` (`res://scripts/characters/base_mecha.gd`) mewarisi `CharacterBody2D`, mengintegrasikan node `StateMachine`, node visual mecha, dan node collision dasar.
   - Seluruh logika evaluasi pergerakan, transisi state, dan kalkulasi fisika dieksekusi secara deterministik di dalam `_physics_process(delta)` pada basis 60 Hz tetap (`delta = 1.0 / 60.0`).
   - Logging diagnostik standar `[STATE]` diaktifkan pada build debug (`OS.is_debug_build()`) untuk memvalidasi setiap perpindahan state.

5. **Test Arena Validation**:
   - `res://scenes/test_arena.tscn` diperbarui untuk menginstansiasi mecha berbasis `BaseMecha` baru (atau merefaktor `player_controller.gd` menjadi arsitektur baru) dan memverifikasi pergerakan horizontal serta lompatan di atas platform berdimensi 640x360 piksel berjalan mulus tanpa error.

---

## Tasks / Subtasks

- [x] Task 1: Setup Autoload Singletons & Combat Constants (AC: 1)
  - [x] 1.1 Buat script `res://scripts/core/event_bus.gd` dengan sinyal tempur dasar: `hit_confirmed`, `parry_triggered`, `hitstop_requested`, `screen_shake_requested`, `cliffhanger_triggered`, `round_ended`.
  - [x] 1.2 Buat script `res://scripts/core/input_buffer.gd` dengan struktur antrean circular 5-frame dasar untuk persiapan Epic 1 Story 3.
  - [x] 1.3 Buat script `res://scripts/combat/combat_constants.gd` (`class_name CombatConstants`) yang mendefinisikan konstanta fisik: `TICK_RATE = 60`, `DEFAULT_WALK_SPEED = 280.0`, `JUMP_VELOCITY = -420.0`, `GRAVITY = 980.0`, `ARENA_LEFT_BOUND = 64.0`, `ARENA_RIGHT_BOUND = 1344.0`.
  - [x] 1.4 Daftarkan `EventBus` dan `InputBuffer` pada bagian `[autoload]` di `project.godot`.
  - [x] 1.5 Daftarkan label 2D physics collision layers pada bagian `[layer_names]` di `project.godot`: Layer 1: "World", Layer 2: "Hurtbox", Layer 3: "StrikeHitbox", Layer 4: "GrabHitbox", Layer 5: "LedgeSensor".

- [x] Task 2: Implementasi Arsitektur State Machine (AC: 2)
  - [x] 2.1 Buat class abstrak `res://scripts/combat/fsm/base_state.gd` (`class_name BaseState extends Node`) dengan referensi ke `character: CharacterBody2D` dan `state_machine: Node`.
  - [x] 2.2 Definisikan virtual methods: `enter()`, `exit()`, `physics_update(delta: float) -> void`, `handle_input(event: InputEvent) -> void`.
  - [x] 2.3 Buat node pengelola `res://scripts/combat/fsm/state_machine.gd` (`class_name StateMachine extends Node`).
  - [x] 2.4 Implementasikan inisialisasi dictionary state dari node child pada `_ready()`, injeksi referensi `character` ke setiap child state, dan transisi aman `change_state(target_state_name: StringName)` dengan validasi `states.has()` serta fallback ke `IdleState`.

- [x] Task 3: Implementasi Ground & Air Movement States (AC: 3)
  - [x] 3.1 Buat `res://scripts/combat/fsm/states_ground.gd` (atau file modular `idle_state.gd` dan `walk_state.gd`).
  - [x] 3.2 Implementasikan logika `IdleState`: perlambatan horizontal instan / lerp cepat menuju 0, deteksi transisi input horizontal -> `WalkState`, input lompat -> `JumpState`, tidak berada di tanah -> `FallState`.
  - [x] 3.3 Implementasikan logika `WalkState`: pembacaan sumbu horizontal (`Input.get_axis("move_left", "move_right")` atau `ui_left`/`ui_right`), kalkulasi `velocity.x = input_dir * walk_speed`, update facing direction pada sprite mecha, transisi ke `IdleState` saat `input_dir == 0.0`, atau ke `JumpState` jika tombol lompat ditekan.
  - [x] 3.4 Buat `res://scripts/combat/fsm/states_air.gd` (atau `jump_state.gd` dan `fall_state.gd`).
  - [x] 3.5 Implementasikan logika `JumpState`: inisialisasi `velocity.y = JUMP_VELOCITY`, aplikasi gravitasi per frame, kontrol pergerakan udara horizontal (`air_control`), dan transisi ke `FallState` saat `velocity.y >= 0.0`.
  - [x] 3.6 Implementasikan logika `FallState`: gravitasi berkelanjutan hingga mecha menyentuh tanah (`character.is_on_floor()`), transisi ke `IdleState` atau `WalkState` saat landing.

- [x] Task 4: BaseMecha Controller & Scene Composition (AC: 4)
  - [x] 4.1 Buat class controller `res://scripts/characters/base_mecha.gd` (`class_name BaseMecha extends CharacterBody2D`).
  - [x] 4.2 Tambahkan properti inti mecha: `walk_speed: float`, `jump_velocity: float`, `facing_direction: int = 1`, `current_hp: int`, `heat_gauge: float`.
  - [x] 4.3 Panggil `state_machine.physics_update(delta)` di dalam `_physics_process(delta)` dan eksekusi `move_and_slide()`.
  - [x] 4.4 Pastikan logging diagnostik `[STATE][%s] Transisi ke %s` tercetak saat debug build.

- [x] Task 5: Testing & Validasi di Test Arena (AC: 5)
  - [x] 5.1 Perbarui `res://scenes/test_arena.tscn` agar menggunakan hierarki node baru `BaseMecha` dengan child `StateMachine` (`Idle`, `Walk`, `Jump`, `Fall`).
  - [x] 5.2 Jalankan pengujian interaktif lokal untuk memverifikasi pergerakan kiri/kanan dan lompatan di platform.
  - [x] 5.3 Pastikan tidak ada peringatan atau error di console/log Godot Engine.

---

## Dev Notes

### Relevant Architecture Patterns and Constraints

1. **Reinvention Prevention (Mencegah Pembuatan Kode Duplikat)**:
   - Proyek saat ini memiliki prototipe monolitik di `res://scripts/player_controller.gd`.
   - Kode prototipe tersebut menggabungkan input hardcode, kalkulasi dash, pendinginan panas, dan UI HUD dalam satu script besar (130 baris).
   - **Tindakan**: Refaktor dan migrasikan fungsionalitas dasar tersebut ke arsitektur resmi FSM (`BaseMecha` + `StateMachine` + States). Jangan menulis kode FSM yang mengabaikan `scenes/test_arena.tscn` yang sudah berfungsi. Hubungkan scene pengujian ke controller baru sehingga pergerakan tetap dapat langsung diuji.

2. **Hierarchical State Machine Safeguard**:
   - Sesuai Dokumen Arsitektur Bagian *Cross-cutting Concerns §1 (Error Handling Strategy)*, transisi state **wajib** dilindungi oleh safeguard fallback:
   ```gdscript
   func change_state(target_state_name: StringName) -> void:
       if not states.has(target_state_name):
           push_error("[FSM] State tidak terdaftar: %s pada %s. Fallback ke Idle." % [target_state_name, owner.name])
           target_state_name = &"Idle"
       
       current_state.exit()
       current_state = states[target_state_name]
       current_state.enter()
   ```

3. **Format Logging Baku**:
   - Sesuai standar arsitektur: `[STATE] Deskripsi peristiwa`.
   - Dilarang memanggil `print()` di setiap tick `_physics_process()`. Hanya lakukan logging saat transisi state terjadi dan bungkus dalam `if OS.is_debug_build():`.

4. **Pemisahan Logika Frame Deterministik 60 FPS**:
   - Seluruh logika FSM dan fisika berjalan di `_physics_process(delta)`.
   - Jangan menggunakan `delta` sebagai faktor pengali pada timer berbasis frame integer.

### Source Tree Components to Touch / Create

- **NEW**: `scripts/core/event_bus.gd` (Autoload Global)
- **NEW**: `scripts/core/input_buffer.gd` (Autoload Global Buffer Stub)
- **NEW**: `scripts/combat/combat_constants.gd` (Konstanta Baku)
- **NEW**: `scripts/combat/fsm/base_state.gd` (Base State Class)
- **NEW**: `scripts/combat/fsm/state_machine.gd` (FSM Manager)
- **NEW**: `scripts/combat/fsm/states_ground.gd` (Idle & Walk States)
- **NEW**: `scripts/combat/fsm/states_air.gd` (Jump & Fall States)
- **NEW**: `scripts/characters/base_mecha.gd` (Base CharacterBody2D Mecha Controller)
- **UPDATE**: `project.godot` (Mendaftarkan Autoload `EventBus`, `InputBuffer`, dan nama Collision Layers)
- **UPDATE**: `scenes/test_arena.tscn` (Menghubungkan Player ke `BaseMecha` + `StateMachine`)

### Testing Standards Summary

- **Manual Verification**:
  1. Jalankan game via Godot 4 (atau batch `run_game.bat`).
  2. Tekan tombol `A` / `D` (atau panah kiri/kanan): Mecha berjalan horizontal pada kecepatan `280 px/s`. Mecha berbalik arah (flip sprite/scale) sesuai arah gerak.
  3. Lepas tombol arah: Mecha berhenti seketika tanpa meluncur liar (*no floaty inertia*).
  4. Tekan `SPACE` / `W`: Mecha melompat ke atas dengan `JUMP_VELOCITY = -420 px/s`, mencapai puncak, jatuh dengan gravitasi `980 px/s²`, dan mendarat kembali ke status Idle dengan mulus.
- **Log Inspection**:
  - Console Godot menampilkan log transisi FSM:
    - `[STATE][BaseMecha] Transisi ke Walk`
    - `[STATE][BaseMecha] Transisi ke Idle`
    - `[STATE][BaseMecha] Transisi ke Jump`
    - `[STATE][BaseMecha] Transisi ke Fall`
  - Tidak ada pesan error atau unhandled exceptions.

---

### Project Structure Notes

- **Struktur Folder Terpadu**:
  - File baru diletakkan persis sesuai hierarki domain arsitektur: `scripts/core/`, `scripts/combat/fsm/`, `scripts/combat/`, `scripts/characters/`.
  - Penamaan file menggunakan `snake_case.gd`, dan class menggunakan `PascalCase`.
- **Variansi / Transisi Prototipe**:
  - `scripts/player_controller.gd` yang ada sebelumnya dapat dipertahankan sementara sebagai referensi atau digantikan penuh oleh `scripts/characters/base_mecha.gd` di dalam `scenes/test_arena.tscn`.

---

### Project Context Rules

- **Platform Target**: PC & Mobile (Canvas resolution: 640x360, Stretch mode: viewport).
- **Bahasa**: GDScript Statically Typed (`var speed: float = 280.0`, `func change_state(name: StringName) -> void`).
- **Engine Rules**: Godot Engine 4 (v4.7.2), Compatibility Renderer (OpenGL ES 3.0).
- **Konvensi Node Hierarchy**: Node mecha memiliki root `CharacterBody2D`, dengan child `CollisionShape2D`, `MechaVisual` (atau `AnimatedSprite2D`), dan `StateMachine`.
- **Boundary**: Child node di dalam mecha dilarang direct call ke sibling node tanpa melalui `character` / `owner` controller.

---

### References

- [GDD Mecha Movement & Physics](file:///c:/game/_bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/gdd.md#41-core-gameplay-loop--movement-mechanics)
- [Architecture State Machine & Collision Matrix](file:///c:/game/_bmad-output/game-architecture.md#1-hierarchical-state-machine-mecha-hsm)
- [Architecture Autoload & Event System](file:///c:/game/_bmad-output/game-architecture.md#4-event-system-decoupled-messaging)
- [Epic 1 Specification in Epics Breakdown](file:///c:/game/_bmad-output/planning-artifacts/epics.md#epic-1-core-physics--movement-engine)
- [Current Prototipe Controller](file:///c:/game/scripts/player_controller.gd)

---

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Suite headless automated tests: `tests/test_movement_fsm.gd` (5/5 tests passed).
  - Test 1: CombatConstants physics & arena parameters.
  - Test 2: Global Autoloads `EventBus` and `InputBuffer`.
  - Test 3: 2D Physics Collision Layer matrix names (World, Hurtbox, StrikeHitbox, GrabHitbox, LedgeSensor).
  - Test 4: StateMachine FSM lifecycle, state transitions (Idle -> Walk -> Jump -> Fall -> Idle), and safe fallback to `IdleState` on invalid state.
  - Test 5: TestArena scene composition (`BaseMecha` + `StateMachine` + 4 states).
- Runtime verification: Main scene `res://scenes/test_arena.tscn` boots without crashes and processes deterministic 60 FPS physics updates.

### Completion Notes List

- Berhasil mendaftarkan singleton global Autoload `EventBus` (`res://scripts/core/event_bus.gd`) dan `InputBuffer` (`res://scripts/core/input_buffer.gd`) di `project.godot`.
- Berhasil mengonfigurasi matrix nama layer collision 2D di `project.godot`.
- Berhasil mengimplementasikan arsitektur Hierarchical State Machine (Mecha HSM) dengan class `BaseState`, node pengelola `StateMachine`, serta state pergerakan dasar `IdleState`, `WalkState`, `JumpState`, dan `FallState`.
- Berhasil mengimplementasikan controller `BaseMecha` (`CharacterBody2D`) dengan kecepatan jalan konsisten `280.0 px/s`, impuls lompat `JUMP_VELOCITY = -420.0 px/s`, gravitasi `980.0 px/s²`, dan update facing direction.
- Berhasil memperbarui `res://scenes/test_arena.tscn` agar menggunakan hierarki node `BaseMecha` dan `StateMachine`.
- Seluruh 5 unit/integration test suites lulus 100%.

### File List

- `scripts/core/event_bus.gd`
- `scripts/core/input_buffer.gd`
- `scripts/combat/combat_constants.gd`
- `scripts/combat/fsm/base_state.gd`
- `scripts/combat/fsm/state_machine.gd`
- `scripts/combat/fsm/idle_state.gd`
- `scripts/combat/fsm/walk_state.gd`
- `scripts/combat/fsm/jump_state.gd`
- `scripts/combat/fsm/fall_state.gd`
- `scripts/combat/fsm/states_ground.gd`
- `scripts/combat/fsm/states_air.gd`
- `scripts/characters/base_mecha.gd`
- `project.godot`
- `scenes/test_arena.tscn`
- `tests/test_movement_fsm.gd`
- `tests/test_runner.tscn`
