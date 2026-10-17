---
baseline_commit: NO_VCS
---

# Story 1.3: Unified 5-Frame Input Buffer & Coyote Time

Status: done

## Story

As a player using a gamepad, keyboard, or touch screen,
I want my action inputs during recovery animations or ledge departure to be buffered and executed reliably,
So that I do not suffer from dropped inputs or missed combos due to strict timing windows.

## Acceptance Criteria

1. **5-Frame Input Buffering Window**:
   - Input aksi (`jump`, `dash`, dan tombol tempur) yang ditekan saat mecha sedang berada dalam kondisi non-actionable (misalnya: masa aktif dash atau frame akhir animasi) disimpan ke dalam antrean `InputBuffer` selama jendela 5 frame fisika (`CombatConstants.INPUT_BUFFER_WINDOW_FRAMES = 5`, setara 83.3 ms pada 60 FPS).
   - Input yang tersimpan di dalam buffer otomatis kedaluwarsa dan dihapus jika telah melewati batas 5 frame tanpa dikonsumsi (`_prune_expired_inputs()`).
   - Begitu mecha kembali ke status actionable (`IdleState` atau `WalkState`), sistem segera memeriksa antrean `InputBuffer`. Jika ada aksi yang tersimpan (misal `jump` atau `dash`), aksi tersebut langsung dikonsumsi (`consume_action()`) dan dieksekusi seketika pada frame pertama mecha aktif.

2. **Coyote Time Tolerance (5 Frame Window)**:
   - Saat mecha melangkah keluar dari bibir platform tanpa melompat (kehilangan pijakan tanah dan bertransisi dari `WalkState`/`IdleState` ke `FallState`), mecha mengaktifkan timer toleransi Coyote Time selama 5 frame fisika (`CombatConstants.COYOTE_TIME_FRAMES = 5`).
   - Selama jendela 5 frame Coyote Time ini masih aktif (`coyote_frames_left > 0`), input lompat (`jump`) tetap diizinkan dieksekusi seolah-olah mecha masih berada di atas platform tanah, memicu transisi ke `JumpState`.
   - Begitu 5 frame berakhir dan mecha masih di udara, hak lompat darat dinonaktifkan (`coyote_frames_left == 0`), dan mecha hanya dapat melakukan Air Dash (jika masih memiliki hak air dash).
   - Jika mecha melompat secara sengaja dari tanah (`JumpState`), Coyote Time tidak diaktifkan (agar tidak terjadi *double jump* tak disengaja di udara).

3. **Input Handling & Buffer Consumption Integration**:
   - `BaseMecha` dan state yang relevan mengintegrasikan `InputBuffer`:
     - Input event yang belum terabsorpsi otomatis dicatat ke dalam `InputBuffer`.
     - `IdleState` dan `WalkState` memprioritaskan konsumsi aksi dari `InputBuffer` (`dash`, `jump`) saat memasuki state atau pada awal `physics_update()`.
     - `FallState` mengelola penghitungan mundur frame Coyote Time dan memeriksa konsumsi input lompat sebelum coyote time habis.

4. **Determinisme & Test Runner Otomatis**:
   - Jendela buffer 5-frame dan coyote time 5-frame dihitung murni berbasis frame integer (`int`) pada `_physics_process()`.
   - Script pengujian headless `tests/test_input_buffer_coyote.gd` dibuat untuk memvalidasi:
     1. Penyimpanan input buffer selama 5 frame dan kedaluwarsa pada frame ke-6.
     2. Konsumsi otomatis aksi buffer saat transisi ke actionable.
     3. Eksekusi lompat sukses selama 5 frame Coyote Time setelah jatuh dari platform.
     4. Penolakan lompat darat pada frame ke-6 setelah jatuh dari platform (Coyote Time expired).
     5. Pencegahan double jump saat melompat normal dari tanah.

---

## Tasks / Subtasks

- [x] Task 1: Integrasi Global InputBuffer & Action Recording (AC: 1, 3)
  - [x] 1.1 Hubungkan input event `jump` dan `dash` ke `InputBuffer.buffer_action()` saat ditekan.
  - [x] 1.2 Implementasikan helper `try_consume_buffered_action(action_name: StringName) -> bool` pada `BaseMecha`.
  - [x] 1.3 Pastikan input buffer window tepat 5 frame dan otomatis dibersihkan saat kedaluwarsa.

- [x] Task 2: Implementasi Coyote Time pada FallState & BaseMecha (AC: 2, 3)
  - [x] 2.1 Tambahkan variabel `coyote_frames_left: int = 0` dan flag `was_on_floor_last_frame: bool = true` pada `BaseMecha`.
  - [x] 2.2 Pada saat mecha meninggalkan tanah tanpa melompat (kehilangan kontak lantai), inisialisasi `coyote_frames_left = CombatConstants.COYOTE_TIME_FRAMES`.
  - [x] 2.3 Pada `FallState.physics_update()`, lakukan dekremen frame `coyote_frames_left` setiap tick.
  - [x] 2.4 Izinkan transisi ke `JumpState` dari `FallState` jika `coyote_frames_left > 0` dan input lompat ditekan/tersedia di buffer.

- [x] Task 3: Buffer Consumption pada State Actionable (AC: 1, 3)
  - [x] 3.1 Pada `IdleState.enter()` dan `physics_update()`, periksa dan konsumsi buffered `dash` dan `jump`.
  - [x] 3.2 Pada `WalkState.enter()` dan `physics_update()`, periksa dan konsumsi buffered `dash` dan `jump`.
  - [x] 3.3 Pastikan saat keluar dari `DashState`, input yang dibuffer selama akhir frame dash langsung dieksekusi tanpa jeda hilang.

- [x] Task 4: Testing Otomatis & Verifikasi (AC: 1, 2, 3, 4)
  - [x] 4.1 Buat test runner `tests/test_input_buffer_coyote.gd` dan scene `tests/test_input_buffer_coyote.tscn`.
  - [x] 4.2 Uji retensi buffer 5 frame (aktif di frame 1-5, hilang di frame 6).
  - [x] 4.3 Uji konsumsi buffer saat transisi actionable.
  - [x] 4.4 Uji Coyote Time 5 frame saat meninggalkan platform.
  - [x] 4.5 Jalankan seluruh test suite headless di Godot 4 dan pastikan 100% lulus.

---

## Dev Notes

### Relevant Architecture Patterns and Constraints

1. **Konstanta Baku dari CombatConstants**:
   - `CombatConstants.INPUT_BUFFER_WINDOW_FRAMES = 5`
   - `CombatConstants.COYOTE_TIME_FRAMES = 5`
   - Dilarang menulis magic numbers frame buffer langsung di dalam logika controller.

2. **Konsumsi Input Deterministik**:
   - `InputBuffer.consume_action(action)` mengembalikan `true` dan menghapus item dari antrean, menjamin satu input hanya dapat memicu satu aksi (tidak ada aksi ganda).

3. **Pemisahan Sumber Input**:
   - Aksi dapat bersumber dari input langsung (`Input.is_action_just_pressed()`) maupun antrean buffer (`InputBuffer.consume_action()`).

### Source Tree Components to Touch / Create

- **UPDATE**: `scripts/core/input_buffer.gd` (Validasi antrean 5-frame dan handling direction)
- **UPDATE**: `scripts/characters/base_mecha.gd` (Menambahkan `coyote_frames_left`, buffering input event, dan helper `try_consume_buffered_action()`)
- **UPDATE**: `scripts/combat/fsm/idle_state.gd` (Mengecek buffered jump & dash)
- **UPDATE**: `scripts/combat/fsm/walk_state.gd` (Mengecek buffered jump & dash)
- **UPDATE**: `scripts/combat/fsm/fall_state.gd` (Implementasi toleransi 5-frame Coyote Time)
- **NEW**: `tests/test_input_buffer_coyote.gd` (Unit test headless untuk buffer 5-frame & coyote time)
- **NEW**: `tests/test_input_buffer_coyote.tscn` (Scene test runner)

---

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

- Melanjutkan baseline dari Story 1.1 dan Story 1.2 yang telah berstatus `done`.
- Unit & Integration Test Suite: `tests/test_input_buffer_coyote.gd` (5/5 tes lulus 100%).
  - Test 1: InputBuffer 5-frame retention & auto-pruning pada frame ke-6.
  - Test 2: InputBuffer directional consumption & single-use execution guarantee.
  - Test 3: Eksekusi otomatis buffered action pada frame pertama status actionable mecha setelah dash.
  - Test 4: Coyote Time 5-frame window toleransi lompatan setelah jatuh dari tebing tanpa melompat.
  - Test 5: Kedaluwarsa Coyote Time pada frame ke-6 dan proteksi double jump.
- Regression Suites: `tests/test_vector_dash.gd` (5/5 tes lulus) dan `tests/test_movement_fsm.gd` (5/5 tes lulus).

### Completion Notes List

- Mengimplementasikan `consume_action_with_data()` pada singleton global `InputBuffer` untuk mengekstraksi aksi beserta vektor arahnya.
- Menambahkan pelacakan `coyote_frames_left`, `notify_ledge_drop()`, `tick_coyote_time()`, `can_coyote_jump()`, dan `consume_coyote_jump()` pada `BaseMecha`.
- Mengintegrasikan penangkapan input di `_unhandled_input()` mecha ke dalam antrean `InputBuffer`.
- Mengimplementasikan konsumsi buffer instan pada `IdleState` dan `WalkState` (`enter()` dan `physics_update()`).
- Mengimplementasikan pemeriksaan Coyote Time jump pada `FallState`.
- Menulis suite pengujian otomatis `tests/test_input_buffer_coyote.gd` dan `tests/test_input_buffer_coyote.tscn` dengan 100% kelulusan.

### File List

- `scripts/core/input_buffer.gd`
- `scripts/characters/base_mecha.gd`
- `scripts/combat/fsm/idle_state.gd`
- `scripts/combat/fsm/walk_state.gd`
- `scripts/combat/fsm/jump_state.gd`
- `scripts/combat/fsm/fall_state.gd`
- `tests/test_input_buffer_coyote.gd`
- `tests/test_input_buffer_coyote.tscn`

### Change Log

- 2026-10-17: Implementasi lengkap Story 1.3 (Unified 5-Frame Input Buffer & Coyote Time) dengan hasil tes 100% lulus dan status diperbarui ke review.
