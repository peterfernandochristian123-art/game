---
baseline_commit: e66cfbc
---

# Story 2.3: Spark Parry System with Frame-Exact Window

Status: review

## Story

As a defensive player with sharp reaction,
I want to execute a precision parry on an incoming enemy strike within a tight frame window,
so that I can negate damage, steal enemy ultimate meter, cool down my mech, and seize the combat initiative.

## Acceptance Criteria

1. **Aktivasi & Input Parry (Ground Neutral Only)**:
   - Tombol Parry (`parry` action pada InputMap: tombol Keyboard `K`/`C`, Gamepad `A`/`B`/`R1`, dan touch `PARRY`).
   - Mecha hanya dapat mengaktifkan parry saat berada di tanah dalam status netral (`IdleState` atau `WalkState`), bukan saat di udara, melompat, dash, atau diserang.
   - Mengalihkan mecha ke `ParryState` (`scripts/combat/fsm/parry_state.gd`).
   - Input parry didukung dalam `InputBuffer` (bila di-buffer dalam 5 frame sebelum mecha actionable di tanah).

2. **Frame Data Deterministik Spark Parry (Whiff Cycle: 19 Frames Total)**:
   - **Startup:** Tepat 1 frame (frame 1). Belum memblokir serangan.
   - **Active Window:** Tepat 4 frame (frame 2 hingga frame 5). Hanya pada jendela ini tangkisan sukses terjadi.
   - **Whiff Recovery:** Tepat 14 frame (frame 6 hingga frame 19). Mecha tidak dapat melakukan aksi lain dan berada dalam status rentan *Counter-Hit* (`is_counter_hit_vulnerable = true`).
   - Setelah frame 19 selesai (frame 20), mecha kembali ke `IdleState`.

3. **Logika Keberhasilan Tangkisan (Parry Success)**:
   - Jika serangan musuh mengenai mecha saat mecha berada di `ParryState` pada frame 2..5:
     - **Damage Negation:** Kerusakan dinolkan (0 damage diterima mecha penyerap).
     - **Hitstop Penyerang:** Mecha penyerang dibekukan (*hitstop*) selama 12 frame fisika deterministik.
     - **Ultimate Steal:** Mecha penyerap menyerap 15% Ultimate meter lawan (mecha penyerang berkurang hingga 15%, mecha penyerap bertambah 15%).
     - **Thermal Cooling:** Panas mecha penyerap berkurang sebesar -20.0% (`heat_component.add_heat(-20.0)`). Suhu tidak boleh < 0.
     - **Event & Sinyal:** Memancarkan sinyal `EventBus.parry_triggered.emit(self, attacker)`.
     - **Frame Advantage / Recovery:** Mecha penyerap tidak terkena hitstun/knockback, memperoleh invulnerability 12 frame, dan segera kembali actionable (bertransisi ke `IdleState`).

4. **Konstanta & Integrasi Arsitektur**:
   - Didefinisikan di `CombatConstants`:
     - `SPARK_PARRY_STARTUP_FRAMES: int = 1`
     - `SPARK_PARRY_ACTIVE_FRAMES: int = 4`
     - `SPARK_PARRY_RECOVERY_FRAMES: int = 14`
     - `SPARK_PARRY_TOTAL_FRAMES: int = 19`
     - `SPARK_PARRY_HITSTOP_FRAMES: int = 12`
     - `SPARK_PARRY_HEAT_COOLING: float = 20.0`
     - `SPARK_PARRY_ULTIMATE_STEAL: float = 15.0`
     - `MAX_ULTIMATE: float = 100.0`
   - `BaseMecha` memiliki field `current_ultimate: float = 0.0` dan `max_ultimate: float = CombatConstants.MAX_ULTIMATE`.
   - `BaseMecha.take_hit()` memeriksa apakah state mecha adalah `ParryState` dan berada di active window:
     - Jika ya, delegasikan ke `parry_state.handle_parry_hit(attacker, hit_data)` dan hentikan flow damage/hitstun standar.
     - Jika diserang pada startup (frame 1) atau recovery (frame 6–19), hit terjadi normal dan memicu hitstun/counter-hit.

5. **Testing Headless Otomatis**:
   - Buat `tests/test_spark_parry.gd` dan `tests/test_spark_parry.tscn`.
   - Uji siklus frame: Frame 1 (Startup), Frame 2..5 (Active), Frame 6..19 (Recovery/Counter-Hit vulnerable), Frame 20 (Kembali ke Idle).
   - Uji parry sukses pada frame aktif: damage 0, attacker hitstop 12 frame, ultimate steal 15%, pendinginan heat -20%, emisi sinyal `parry_triggered`.
   - Uji parry whiff: serangan masuk di frame 1 atau frame 8 mengenai mecha dan menimbulkan damage.
   - Uji regresi seluruh suite sebelumnya (Story 1.1–1.4, 2.1, 2.2) tetap 100% lulus.

## Tasks / Subtasks

- [x] Task 1: Konstanta Tempur & Input Setup (AC: 1, 4)
  - [x] 1.1 Tambahkan konstanta Spark Parry & Ultimate di `CombatConstants`.
  - [x] 1.2 Tambahkan input mapping `parry` di `BaseMecha._setup_input_fallbacks()` (KEY_L, KEY_V).
  - [x] 1.3 Tambahkan properti `current_ultimate`, `max_ultimate`, `add_ultimate(amount)`, `drain_ultimate(amount)` di `BaseMecha`.
- [x] Task 2: Implementasi ParryState (AC: 1, 2, 3)
  - [x] 2.1 Buat `scripts/combat/fsm/parry_state.gd` (`class_name ParryState extends BaseState`).
  - [x] 2.2 Kelola penghitung frame deterministik: `current_frame_in_state` (1 = startup, 2..5 = active, 6..19 = recovery).
  - [x] 2.3 Implementasikan flag `is_parry_active() -> bool` dan `is_counter_hit_vulnerable() -> bool`.
  - [x] 2.4 Implementasikan `handle_parry_hit(attacker: Node2D, hit_data: Dictionary) -> bool` untuk menjalankan efek sukses parry.
  - [x] 2.5 Daftarkan `ParryState` di `BaseMecha._setup_fsm_states()`.
- [x] Task 3: Transisi State & Integrasi Combat (AC: 1, 3, 4)
  - [x] 3.1 Sambungkan transisi ke `Parry` dari `IdleState` dan `WalkState` saat tombol parry ditekan atau dari buffer input.
  - [x] 3.2 Modifikasi `BaseMecha.take_hit()` untuk mengecek `ParryState.is_parry_active()`.
  - [x] 3.3 Terapkan hitstop pada attacker (12 frame) dan update HUD (indikator Spark Parry).
- [x] Task 4: Automated Testing Suite & Validasi (AC: 5)
  - [x] 4.1 Buat `tests/test_spark_parry.gd` + `tests/test_spark_parry.tscn`.
  - [x] 4.2 Verifikasi seluruh acceptance criteria secara headless.
  - [x] 4.3 Jalankan pengujian regresi seluruh suite 1.1–2.2.

## Dev Notes

- **Struktur State Machine:** Proyek menggunakan node-based FSM di bawah node `StateMachine` pada `BaseMecha`.
- **Determinisme:** Seluruh penghitungan frame dilakukan di `physics_update(_delta)` berbasis tick integer, tanpa bergantung pada float `delta`.
- **Ultimate Steal:** Nilai 15% dari max 100. Jika attacker memiliki ultimate < 15, curi sebesar sisa yang ada (atau minimum 0), dan tambahkan 15 ke mecha penyerap.
- **Hitstop:** Attacker dibekukan selama 12 frame. `EventBus.hitstop_requested.emit(12)` dipancarkan, dan jika attacker memiliki komponen hitstop / counter frame freeze, aktifkan freeze tersebut.
- **Indentasi:** GDScript menggunakan TAB.
