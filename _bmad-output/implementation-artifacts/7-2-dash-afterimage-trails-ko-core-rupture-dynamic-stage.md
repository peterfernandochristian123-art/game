---
baseline_commit: ed6e124
---

# Story 7.2: Dash Afterimage Trails, K.O. Core Rupture & Dynamic Stage Background

Status: ready-for-dev

## Story

As a player executing high-speed maneuvers or landing a decisive final blow,
I want dynamic dash silhouette after-image trails, a cinematic K.O. core rupture explosion, and a living 90s cyber-city background with glowing neon windows and passing hover vehicles,
So that every movement feels blindingly fast, victories feel momentous, and the zero-g skyscraper battlefield feels immersive.

## Acceptance Criteria

1. **Dash Ghost Afterimage Trails (`scripts/visual/vfx_ghost_trail.gd` / `scripts/visual/dash_trail_component.gd`)**:
   - Saat mecha melakukan dorongan *Vector Dash* (darat atau udara), sistem memancarkan 3–4 siluet *ghost afterimage* semi-transparan di posisi frame sebelumnya.
   - Warna bayangan afterimage proporsional sesuai archetype:
     - Apex-0 Viper: Cyan neon berpendar (#33E6FF / #00BFFF) dengan alpha decay dari 0.70 ke 0.0 selama 10 frame.
     - Titan-V Bulwark: Oranye-emas industrial (#FFA500 / #FF4500) dengan alpha decay dari 0.70 ke 0.0 selama 10 frame.
   - Afterimage tidak memblokir input atau memicu tabrakan fisik (tidak memiliki collider Area2D).

2. **Cinematic K.O. Core Rupture Sequence (`scripts/visual/vfx_core_rupture.gd`)**:
   - Mendengarkan sinyal `EventBus.round_ended(winner_id, win_condition)` dan sinyal K.O. karakter (saat HP mencapai 0).
   - Memancarkan sekuens ledakan reaktor dramatis pada koordinat mecha yang kalah:
     - Frame 0–4: *Energy Build-up Flash* (layar memancarkan flash putih lokal dengan hitstop freeze 18 frame).
     - Frame 5–25: *Radial Welding Sparks* (percikan api las berkecepatan tinggi memancar 360 derajat) dan partikel asap tebal bergaya 32-bit pixel.
     - Frame 26+: Sasis mecha terhuyung jatuh (*wreckage shutdown*) sebelum pengumuman pemenang ronde.

3. **Living 90s Cyber-City Skyscraper Arena Enhancements (`scenes/arena_skyscraper.tscn`)**:
   - Memperkaya latar belakang kota New Babel-01 tanpa membebani performa kanvas 640x360:
     - Menara pencakar langit (`Tower1`, `Tower2`, `Tower3`) dilengkapi jendela-jendela pixel grid dengan modulasi cahaya lembut berkedip acak (*twinkling cyber-windows*).
     - Lapisan lampu navigasi merah/hijau berkedip di puncak antena gedung.
     - Kendaraan hovercraft melintas sesekali secara horizontal di latar belakang dengan lampu ekor neon.

4. **Performance & Matrix Integrity**:
   - Seluruh efek visual partikel dan afterimage dibersihkan secara efisien (menggunakan pooling atau `queue_free()` deterministik setelah decay) dengan konsumsi RAM tetap di bawah 600 MB.
   - Framerate tetap terkunci pada 60 FPS stabil.
   - Seluruh matriks kolisi arena dan petarung tidak mengalami pergeseran.

5. **Automated Verification Suite (`tests/test_ghost_trail_and_stage_vfx.gd` & `tests/test_ghost_trail_and_stage_vfx.tscn`)**:
   - Validasi bahwa `DashTrailComponent` memicu generasi afterimage saat status mecha adalah `Dash` atau `AirDash`.
   - Validasi bahwa afterimage membersihkan diri sendiri saat masa hidupnya (*decay*) selesai.
   - Validasi bahwa sekuens `VFXCoreRupture` aktif saat ronde berakhir via K.O.
   - Seluruh 26 test suite yang ada sebelumnya tetap lulus 100% tanpa regresi.

## Tasks / Subtasks

- [ ] Task 1: Dash Ghost Afterimage Trail Subsystem (AC: 1, 4)
  - [ ] 1.1 Buat `scripts/visual/vfx_ghost_trail.gd` untuk rendering siluet mecha dengan alpha decay halus.
  - [ ] 1.2 Buat `scripts/visual/dash_trail_component.gd` yang terhubung dengan `DashState` & `AirDashState` mecha.
- [ ] Task 2: Cinematic K.O. Core Rupture FX (AC: 2, 4)
  - [ ] 2.1 Buat `scripts/visual/vfx_core_rupture.gd` untuk ledakan reaktor mecha radial, hitstop freeze, dan fragmen asap.
  - [ ] 2.2 Integrasikan dengan sinyal `round_ended` pada `EventBus` dan `ArenaSkyscraper`.
- [ ] Task 3: Living 90s Cyber-City Arena Background (AC: 3, 4)
  - [ ] 3.1 Tambahkan jendela pixel grid neon pada gedung-gedung latar belakang di `scenes/arena_skyscraper.tscn`.
  - [ ] 3.2 Tambahkan skrip `scripts/arena/cyber_city_background.gd` untuk lampu antena kedip dan kendaraan hovercraft melintas.
- [ ] Task 4: Automated Testing Suite & Regression Verification (AC: 5)
  - [ ] 4.1 Buat `tests/test_ghost_trail_and_stage_vfx.gd` dan `tests/test_ghost_trail_and_stage_vfx.tscn`.
  - [ ] 4.2 Daftarkan ke `tests/run_all_tests.ps1` dan pastikan seluruh 27 test suite lulus 100%.

## Dev Notes

- **Afterimage Rendering**:
  - Hindari ViewportTexture screenshot yang mahal di mobile; buat bayangan siluet dengan menduplikasi gambar `MechaPixelSprite` atau drawing instance siluet dengan warna solid dan alpha decay.
  - Afterimage harus di-parent ke scene arena atau root node agar posisinya tertinggal statis di koordinat dunia saat mecha bergerak meluncur cepat.

- **K.O. Sequence**:
  - Gunakan `EventBus.hitstop_requested` untuk freeze 18 frame agar momen K.O. terasa berdampak luar biasa.
  - Pemicuan hanya 1x per eliminasi mecha untuk mencegah double explosion.

### Project Context Rules

- **Platform Target**: PC & Mobile (Compatibility Renderer / GL Compatibility).
- **Pixel Art Canvas**: 640x360 internal canvas resolution.
- **Autoload Singletons**: `EventBus`, `InputBuffer`.

### References

- GDD §1.3 (Neo-Retro 32-Bit Aesthetics)
- GDD §3.3 (Win/Loss Conditions & K.O. Execution)
- GDD §6.1 (Zero-G Skyscraper Arena Atmosphere)
- Architecture §6 (Visual & Juice Subsystem)

## Dev Agent Record

### Agent Model Used

Gemini 3.8 Flash (Medium)

### Debug Log References

### Completion Notes List

### File List
