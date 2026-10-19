---
baseline_commit: ee90e1827dc2eae07d3f7e781fc74f7cfdc80f1a
---

# Story 2.2: Overclock Zone Buffs & Emergency Meltdown Shutdown

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a risk-taking player,
I want powerful buffs when operating in high heat (80–99%) but face severe penalties if reaching 100%,
so that I can experience thrilling high-risk, high-reward tactical combat.

## Acceptance Criteria

1. **Overclock Zone Thresholds & Status Signals**:
   - `HeatComponent` mendeteksi rentang zona panas:
     - Nominal: `0.0 <= heat < 80.0`
     - Overclock: `80.0 <= heat < 100.0`
     - Meltdown: `heat >= 100.0`
   - Memancarkan sinyal `overclock_state_changed(is_active: bool)` saat memasuki atau meninggalkan zona Overclock (`80.0 <= heat < 100.0`).
   - Menyediakan properti/metode query `is_overclocked() -> bool`.

2. **Overclock Zone Combat Buffs (80.0% – 99.9%)**:
   - **Damage Output Buff**: Serangan skill/ofensif saat mecha dalam status Overclock menghasilkan bonus damage +20% (pengali `1.2x`).
   - **1-Hit Super Armor**: Mecha mendapatkan status `1-Hit Super Armor` pada fase *startup frames* serangan skill (menyerap 1 kali pukulan tanpa terhuyung ke `HitstunState`).
   - Buff hanya aktif selama panas mecha berada di zona `80.0%` hingga `< 100.0%`. Begitu panas turun di bawah `80.0%` (misal karena pendinginan pasif), buff nonaktif.

3. **Emergency Meltdown Shutdown State (100.0% Heat)**:
   - Saat panas menyentuh `100.0%`, mecha mengalami *Core Shutdown* seketika dan beralih paksa ke `MeltdownShutdownState` (atau `MeltdownState` di `scripts/combat/fsm/meltdown_state.gd`).
   - Mecha lumpuh total selama tepat 90 frame fisika (1.5 detik pada 60 FPS deterministik):
     - Kecepatan horizontal terkunci `velocity.x = 0.0`.
     - Tidak dapat menerima input aksi apapun (semua input buffer atau command dibatalkan/diabaikan).
     - Membatalkan serangan atau aksi apapun yang sedang berjalan seketika saat meltdown terpantau.
   - **Incoming Damage Penalty**: Mecha yang sedang berada dalam status Meltdown menerima damage masuk tambahan +25% (pengali damage masuk `1.25x`) saat terkena serangan musuh di `take_hit()`.

4. **Meltdown Recovery & Thermal Reset**:
   - Setelah tepat 90 frame dalam `MeltdownShutdownState`, mecha keluar dari state kelumpuhan dan kembali ke `IdleState` (atau `FallState` jika di udara).
   - Suhu mecha direset kembali ke `0.0%` (`heat_component.reset()` atau `current_heat = 0.0`) dan memancarkan sinyal `heat_changed(0.0, 100.0)`.
   - Transisi keluar memancarkan notifikasi/log `[STATE]` yang bersih tanpa frame leak.

5. **Visual & UI Integration**:
   - Visual feedback status HUD di `test_arena.tscn` / `_update_hud()` memperbarui indikasi status mecha (misal indikator Overclock berkedip/merah dan Meltdown shutdown).
   - Efek visual mecha (`MechaVisual`) memberikan feedback visual saat Overclock (misal modul warna atau indikator uap/pendaran) dan saat Meltdown (visual redup/kelumpuhan).

6. **Automated Headless Test Suite**:
   - Buat file test mandiri `tests/test_overclock_meltdown.gd` dan `tests/test_overclock_meltdown.tscn`.
   - Menguji secara deterministik:
     - Deteksi transisi Overclock di 80.0% dan sinyal `overclock_state_changed`.
     - Pengali damage output +20% saat Overclock.
     - Penyerapan 1-hit super armor pada fase startup serangan saat Overclock (tanpa knockback/hitstun).
     - Pemicu seketika Meltdown saat mencapai 100.0% heat.
     - Kelumpuhan tepat 90 frame di `MeltdownShutdownState`.
     - Pengali damage masuk +25% saat mecha terkena hit di Meltdown.
     - Reset panas ke 0.0% setelah durasi 90 frame berakhir dan kembali ke status actionable.
   - Semua test suite sebelumnya (1.1, 1.2, 1.3, 1.4, 2.1) tetap lulus 100%.

## Tasks / Subtasks

- [x] Task 1: Overclock Thresholds & Signal di HeatComponent (AC: 1)
  - [x] 1.1 Tambahkan konstanta di `CombatConstants`: `OVERCLOCK_THRESHOLD: float = 80.0`, `MELTDOWN_THRESHOLD: float = 100.0`, `OVERCLOCK_DAMAGE_MULTIPLIER: float = 1.2`, `MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER: float = 1.25`, `MELTDOWN_DURATION_FRAMES: int = 90`.
  - [x] 1.2 Perbarui `scripts/combat/components/heat_component.gd`: tambahkan sinyal `overclock_state_changed(is_active: bool)`, tracking `is_overclocked: bool`, pembaruan evaluasi pada `add_heat()` dan `process_frame()`, serta helper method `is_overclocked() -> bool`.
- [x] Task 2: State MeltdownShutdownState FSM (AC: 3, 4)
  - [x] 2.1 Buat script `scripts/combat/fsm/meltdown_state.gd` (`class_name MeltdownState extends BaseState`).
  - [x] 2.2 Implementasikan logika durasi 90 frame integer fisika, kunci `velocity.x = 0.0`, pengabaian input, pemancaran event state, dan transisi keluar ke `Idle`/`Fall`.
  - [x] 2.3 Reset `heat_component.current_heat = 0.0` saat durasi meltdown selesai.
  - [x] 2.4 Daftarkan `Meltdown` state pada node `StateMachine` di `BaseMecha` (baik secara dinamis di `_ready()` atau via scene `test_arena.tscn`).
- [x] Task 3: Combat Logic Buffs & Penalties di BaseMecha & Attack/Damage System (AC: 2, 3, 4)
  - [x] 3.1 Hubungkan sinyal `meltdown_triggered` dari `HeatComponent` ke `BaseMecha`: pemicu langsung transisi paksa `state_machine.change_state(&"Meltdown")`.
  - [x] 3.2 Modifikasi `take_hit()` di `BaseMecha`: jika mecha sedang di `Meltdown`, kalikan damage masuk dengan `MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER` (1.25x).
  - [x] 3.3 Implementasi 1-Hit Super Armor pada startup: sediakan flag armor di `BaseMecha` / `AttackState` saat `is_overclocked` aktif pada startup frame; jika terkena hit pada frame startup, serap 1 hit tanpa beralih ke `HitstunState` dan hilangkan armor untuk sisa serangan.
  - [x] 3.4 Modifikasi damage calculation serangan saat penyerang `is_overclocked`: kalikan damage serangan dengan `OVERCLOCK_DAMAGE_MULTIPLIER` (1.2x).
- [x] Task 4: Feedback Visual & HUD Updates (AC: 5)
  - [x] 4.1 Update `_update_hud()` di `BaseMecha` atau HUD di `scenes/test_arena.tscn` untuk menampilkan status "OVERCLOCK" (misal teks atau warna HeatBar) dan "MELTDOWN (SHUTDOWN)".
  - [x] 4.2 Tambahkan modulasi visual sederhana pada `MechaVisual` saat mecha overclocked / meltdown.
- [x] Task 5: Testing Headless Otomatis & Regresi (AC: 6)
  - [x] 5.1 Buat `tests/test_overclock_meltdown.gd` dan `tests/test_overclock_meltdown.tscn` yang memverifikasi seluruh AC secara komprehensif.
  - [x] 5.2 Jalankan validasi headless untuk test baru dan semua suite regresi (1.1 - 2.1), pastikan 100% PASS.

## Dev Notes

### Kondisi Kode Saat Ini (file yang disentuh — baca penuh sebelum edit)

- [`scripts/combat/components/heat_component.gd`](../../scripts/combat/components/heat_component.gd) (UPDATE):
  - Saat ini sudah memiliki `current_heat`, `add_heat()`, `process_frame()`, dan sinyal `meltdown_triggered`.
  - Belum memiliki `overclock_state_changed`, variabel `is_overclocked`, maupun evaluasi rentang 80.0–99.9%.
  - Perhatikan bahwa `process_frame()` memanggil `add_heat(-PASSIVE_COOLING_PER_FRAME)`. Pastikan transisi status Overclock dievaluasi baik saat panas bertambah maupun saat berkurang.
- [`scripts/combat/combat_constants.gd`](../../scripts/combat/combat_constants.gd) (UPDATE):
  - Tambahkan konstanta Overclock & Meltdown di bagian `# Heat Gauge`. Jangan ubah konstanta yang sudah ada agar tidak memicu regresi.
- [`scripts/characters/base_mecha.gd`](../../scripts/characters/base_mecha.gd) (UPDATE):
  - Memiliki `take_hit(attacker: Node2D, hit_data: Dictionary)`. Perlu mendukung:
    - Pengecekan status mecha saat ini: jika `state_machine.current_state.name == &"Meltdown"`, damage masuk dikalikan 1.25x (misal damage 40 -> 50).
    - Pengecekan Super Armor startup: jika mecha sedang melakukan serangan dengan Super Armor aktif (karena Overclock), kurangi HP namun cegah transisi ke `HitstunState` dan konsumsi 1-hit armor.
  - Integrasikan sinyal `heat_component.meltdown_triggered` untuk seketika beralih ke `Meltdown`.
  - Pastikan FSM memiliki fallback aman jika state `Meltdown` belum terpasang di scene lama (buat secara dinamis di `_setup_states()` jika belum ada).
- [`scripts/combat/fsm/attack_state.gd`](../../scripts/combat/fsm/attack_state.gd) (UPDATE):
  - Mengelola siklus serangan (`startup`, `active`, `recovery`).
  - Saat memasuki serangan (`enter()`): jika mecha `is_overclocked`, aktifkan flag super armor selama `current_attack_frame < startup`.
  - Pastikan kalkulasi damage yang dikirimkan ke target memasukkan pengali 1.2x jika attacker `is_overclocked`.
- [`scripts/combat/fsm/meltdown_state.gd`](../../scripts/combat/fsm/meltdown_state.gd) (NEW):
  - Mewarisi `BaseState`.
  - Mengelola counter integer frame hingga 90 frame (1.5s pada 60 FPS deterministik).
  - Mengunci input dan pergerakan horizontal.
  - Saat selesai: reset panas `character.heat_component.reset()` dan kembali ke `Idle` / `Fall`.
- [`scenes/test_arena.tscn`](../../scenes/test_arena.tscn) (UPDATE):
  - Daftarkan node `Meltdown` di bawah `Player/StateMachine` dan `DummyTarget/StateMachine`.
  - Perbarui visual status HUD saat Overclock / Meltdown.

### Pola & Batasan Arsitektur

- **Deterministik Frame 60 FPS**: Hitung durasi Meltdown (90 frame) menggunakan integer counter per tick di `physics_update()`, bukan `delta` timer.
- **Hierarchical Node Pattern**: Akses state dan komponen melalui mecha root controller (`character.heat_component`), gunakan tab indentasi sesuai standar GDScript proyek ini.
- **Graceful Fallback**: Jika `state_machine.change_state(&"Meltdown")` dipanggil pada mecha yang tidak memiliki node Meltdown di scene tree, FSM harus membuat/menangani fallback tanpa crash.

### Pelajaran dari Story 2.1 & Sprint Sebelumnya

- Selalu gunakan type-hinting dan preload pattern (`const HeatComponentScript = preload(...)`).
- Buat test runner terisolasi tanpa bergantung pada autoload yang tidak terinisialisasi di mode headless (inisialisasi manual atau guard `is_instance_valid(EventBus)`).
- File test menulis output ke `res://test_overclock_meltdown_results.txt`.

### Project Structure Notes

- File baru: `scripts/combat/fsm/meltdown_state.gd`, `tests/test_overclock_meltdown.gd`, `tests/test_overclock_meltdown.tscn`.
- File diubah: `scripts/combat/components/heat_component.gd`, `scripts/combat/combat_constants.gd`, `scripts/characters/base_mecha.gd`, `scripts/combat/fsm/attack_state.gd`.

### Project Context Rules

- Bahasa komentar kode & dokumentasi: Bahasa Indonesia.
- Indentasi GDScript: TAB (bukan space).
- Determinisme: per-physics frame calculation.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2: Overclock Zone Buffs & Emergency Meltdown Shutdown]
- [Source: _bmad-output/game-architecture.md#Thermal Risk-Reward Dynamic Engine]
- [Source: _bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/gdd.md#FR5 & FR6]
- [Source: _bmad-output/implementation-artifacts/2-1-heat-gauge-component-passive-cooling-logic.md]

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Godot 4.7.2 headless: `tests/test_overclock_meltdown.tscn` lulus 7/7 (Constants, Threshold/Signals, Overclock Damage Buff +20%, Super Armor Startup Absorption, Meltdown Shutdown & Lockout, Meltdown Incoming Damage Penalty +25%, Meltdown Recovery 90 frames & Thermal Reset ke 0.0%).
- Full regression suite (Story 1.1, 1.2, 1.3, 1.4, 2.1, 2.2) lulus 100% tanpa regresi.

### Completion Notes List

- Diimplementasikan `HeatComponent` dengan pendeteksian zona Overclock (80.0–99.9%) dan sinyal `overclock_state_changed`.
- Diimplementasikan pengali output damage +20% (`OVERCLOCK_DAMAGE_MULTIPLIER = 1.2`) saat penyerang dalam status Overclock.
- Diimplementasikan `1-Hit Super Armor` pada fase startup frame serangan di `AttackState` saat status Overclock aktif, menyerap hit tanpa terlempar ke `HitstunState`.
- Dibuat `MeltdownState` (`scripts/combat/fsm/meltdown_state.gd`) dengan penguncian aksi dan pergerakan horizontal selama tepat 90 frame fisika deterministik.
- Diimplementasikan penalti damage masuk +25% (`MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER = 1.25`) saat mecha diserang dalam kondisi Meltdown.
- Diimplementasikan reset suhu termal mecha ke 0.0% dan transisi kembali ke `Idle`/`Fall` setelah 90 frame Meltdown berakhir.
- Diperbarui HUD display dengan status tag visual indikator `OVERCLOCK` dan `MELTDOWN SHUTDOWN`.

### File List

- scripts/combat/combat_constants.gd
- scripts/combat/components/heat_component.gd
- scripts/combat/fsm/attack_state.gd
- scripts/combat/fsm/meltdown_state.gd (baru)
- scripts/characters/base_mecha.gd
- tests/test_overclock_meltdown.gd (baru)
- tests/test_overclock_meltdown.tscn (baru)
- _bmad-output/implementation-artifacts/2-2-overclock-zone-buffs-emergency-meltdown-shutdown.md
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

- 2026-10-19: Implementasi Story 2.2 selesai dan lulus seluruh validasi 7/7 + regresi suite 100%, status review.

