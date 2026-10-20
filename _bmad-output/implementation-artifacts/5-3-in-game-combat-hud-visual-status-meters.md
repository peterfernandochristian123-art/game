---
baseline_commit: 50f6818
---

# Story 5.3: In-Game Combat HUD & Visual Status Meters

Status: review

## Story

As a player,
I want a clear, retro 32-bit combat HUD displaying health bars, dynamic heat levels, ultimate gauge, round timers, and round win counters,
So that I can monitor my combat resources and status at a glance without visual clutter.

## Acceptance Criteria

1. **Scene Combat HUD (`scenes/combat_hud.tscn`)**:
   - Tampilan HUD layar penuh bergaya neo-retro 32-bit pada resolusi kanvas 640x360.
   - Penataan simetris kompetitif: Status P1 di sisi kiri atas, P2 di sisi kanan atas, dan Timer serta status ronde di tengah atas.

2. **Real-Time Health Bars (HP Bar)**:
   - Bar HP kedua petarung diperbarui secara real-time saat menerima damage atau pemulihan HP.
   - P1 berkurang dari kanan-ke-kiri, P2 berkurang dari kiri-ke-kanan secara simetris.
   - Dilengkapi teks metrik HP numerik (mis. "1000 / 1000") dan ghost bar / damage trail.

3. **Dynamic Thermal Heat Gauge dengan 3 Zona Warna**:
   - Menampilkan persentase panas internal mecha (0–100%).
   - **Nominal Zone (0–79%)**: Bar berwarna Cyan/Hijau/Kuning stabil.
   - **Overclock Zone (80–99%)**: Bar berubah menjadi Merah Menyala Berkedip (*Flashing Red*) dengan tag status "OVERCLOCK".
   - **Meltdown Core Shutdown (100%)**: Bar berubah menjadi Ungu Pudar (*Faded Violet*) dengan tag status peringatan "MELTDOWN / CORE SHUTDOWN".

4. **Ultimate Gauge & Status Meter**:
   - Meteran Ultimate (0–100%) di bawah Heat Gauge dengan aksen emas/oranye.
   - Menampilkan status "MAX / PROTOCOL READY" saat meteran terisi penuh 100%.

5. **Round Timer & Round Win Counters**:
   - Timer hitung mundur 90 detik di tengah atas layar dengan angka digital tajam 32-bit.
   - Angka timer berkedip merah saat sisa waktu < 15 detik.
   - Indikator kemenangan ronde (*Round Win Dots/Icons*) untuk format Best of 3 (mis. [●] [○]).
   - Indikator khusus "SUDDEN DEATH" saat babak penentuan seri berlangsung.

6. **Automated Testing Suite**:
   - Dibuat `tests/test_combat_hud.gd` dan `tests/test_combat_hud.tscn`.
   - Validasi instansiasi elemen HUD (HP, Heat, Ultimate, Timer, Win Counters).
   - Validasi pembaruan HP bar P1 & P2 real-time.
   - Validasi transisi kode warna Heat Gauge (Nominal -> Overclock -> Meltdown).
   - Validasi pembaruan Ultimate meter dan teks indikator status.
   - Validasi sinkronisasi Timer dan Round Win counters dengan MatchManager.

## Tasks / Subtasks

- [x] Task 1: Sinyal State Combat Mecha (AC: 2, 3, 4)
  - [x] 1.1 Tambahkan sinyal `hp_changed`, `ultimate_changed`, dan forwarding `heat_changed` pada `scripts/characters/base_mecha.gd`.
- [x] Task 2: Implementasi Pengendali Combat HUD (AC: 1, 2, 3, 4, 5)
  - [x] 2.1 Buat `scripts/ui/combat_hud.gd` mengelola binding petarung (P1 & P2), MatchManager, kalkulasi warna Heat Gauge dinamis, dan update timer.
- [x] Task 3: Desain Visual Scene `scenes/combat_hud.tscn` (AC: 1, 2, 3, 4, 5)
  - [x] 3.1 Bangun layout kanvas 640x360 dengan frame bergaya mecha 32-bit, bar HP simetris, meteran panas dinamis, bar ultimate, dan round counters.
- [x] Task 4: Automated Testing Suite (AC: 6)
  - [x] 4.1 Buat `tests/test_combat_hud.gd` dan `tests/test_combat_hud.tscn`.
  - [x] 4.2 Uji seluruh skenario HP bar, warna heat zone, ultimate meter, timer countdown, dan win counters.

## Dev Agent Record

### Debug Log
- Memperluas `BaseMecha` dengan metode `set_hp(val)` untuk memusatkan emisi sinyal `hp_changed(current, max_val)` di seluruh skenario damage masuk (Normal Hit, Chip Damage, Ring-Out, dan Round Reset).
- Menghubungkan sinyal `heat_changed` dan `ultimate_changed` dari mecha controller langsung ke HUD data binders.

### Completion Notes List
- Dibuat scene `scenes/combat_hud.tscn` dengan estetika 32-bit pixel arcade retro pada resolusi kanvas 640x360.
- Diimplementasikan pengendali `scripts/ui/combat_hud.gd` yang mendukung binding petarung (P1 & P2) serta `MatchManager`.
- Bar HP real-time simetris (P1 kiri-ke-kanan, P2 kanan-ke-kiri) dengan warna adaptif (Hijau > Kuning > Merah).
- Dynamic Thermal Heat Gauge dengan 3 zona visual: Nominal (0–79% Cyan), Overclock (80–99% Merah Menyala Berkedip dengan tag `[OVERCLOCK]`), dan Meltdown (100% Ungu Pudar dengan tag `[MELTDOWN]`).
- Ultimate Gauge (0–100%) dengan indikasi status "PROTOCOL READY" saat bar mencapai 100%.
- Digital Round Timer 90 detik dengan peringatan visual saat sisa waktu <= 15s, serta indikator kemenangan ronde (Win Dots) dan penanganan Sudden Death.
- Suite automated test `tests/test_combat_hud.gd` lulus 6/6 (100%), dan seluruh test regresi lulus 100%.

### File List
- scripts/characters/base_mecha.gd (diperbarui sinyal hp/heat/ultimate)
- scripts/ui/combat_hud.gd (baru)
- scenes/combat_hud.tscn (baru)
- tests/test_combat_hud.gd (baru)
- tests/test_combat_hud.tscn (baru)
- _bmad-output/implementation-artifacts/5-3-in-game-combat-hud-visual-status-meters.md (baru)
- _bmad-output/implementation-artifacts/sprint-status.yaml (diperbarui)

### Change Log
- 2026-10-20: Implementasi Story 5.3 Combat HUD selesai dan lulus validasi 6/6, status review.
