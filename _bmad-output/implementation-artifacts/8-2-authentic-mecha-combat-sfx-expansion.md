---
baseline_commit: 1c724c3
---

# Story 8.2: Authentic Mecha Combat SFX Expansion & Dynamic Sound Feedback

Status: done

## Story

As a player performing dashes, managing heat, or landing hits,
I want distinct mechanical sound effects for thruster dashes, heat alarms, meltdown shutoff, and heavy impact varieties,
So that I receive clear, visceral audio cues for every combat state and action.

## Acceptance Criteria

1. **Authentic 90s Mecha SFX Synthesizer Additions (`scripts/audio/audio_synthesizer.gd`)**:
   - `generate_thruster_dash(duration: float = 0.22) -> AudioStreamWAV`: Desisan jet thruster mecha bertekanan tinggi dengan amplop noise terfilter dan sub-bass ignition pop.
   - `generate_overclock_alarm(duration: float = 0.18) -> AudioStreamWAV`: Sinyal strobo digital frekuensi tinggi ganda (1050 Hz & 1400 Hz) penanda reaktor memasuki zona bahaya (80–99%).
   - `generate_meltdown_shutdown(duration: float = 0.45) -> AudioStreamWAV`: Suara penurunan frekuensi daya reaktor (*pitch dive* 600 Hz -> 60 Hz dengan hum elektrik) saat terjadi shutdown total 100%.
   - `generate_heavy_impact(duration: float = 0.28) -> AudioStreamWAV`: Hantaman logam berbeban berat dengan bass punch dan frekuensi rendah resonan untuk pukulan finisher / heavy attack.
   - `generate_wall_bounce(duration: float = 0.25) -> AudioStreamWAV`: Efek pantulan baja bergetar saat karakter terpental ke dinding atau lantai (*wall/ground bounce*).

2. **AudioManager Dynamic SFX Dispatch Subsystem (`scripts/audio/audio_manager.gd`)**:
   - Menyimpan cache instance AudioStreamWAV untuk kelima efek suara baru di atas.
   - Mendengarkan `EventBus.state_changed`:
     - Saat mecha bertransisi ke state `&"Dash"` atau `&"AirDash"`: Memutar `sfx_thruster_dash` pada bus `SFX`.
     - Saat mecha bertransisi ke state `&"Meltdown"`: Memutar `sfx_meltdown_shutdown` pada bus `SFX` dan memanggil announcer `"CRITICAL MELTDOWN!"`.
   - Mendengarkan `EventBus.overclock_triggered`:
     - Saat karakter memasuki zona Overclock: Memutar `sfx_overclock_alarm` pada bus `SFX`.
   - Mendengarkan `EventBus.hit_confirmed`:
     - Memilih antara `sfx_metal_clang` (serangan normal) dan `sfx_heavy_impact` / `sfx_wall_bounce` (serangan berkekuatan tinggi damage >= 120 atau pemicu bounce).
   - Menyediakan API publik langsung (`play_thruster_dash()`, `play_overclock_alarm()`, `play_meltdown_shutdown()`, `play_heavy_impact()`, `play_wall_bounce()`).

3. **EventBus & BaseMecha Thermal/Combat Signal Integration**:
   - Mendaftarkan sinyal `overclock_triggered(character: Node2D, is_active: bool)` pada [EventBus](file:///c:/Users/game/scripts/core/event_bus.gd).
   - Menghubungkan sinyal `overclock_state_changed` pada `HeatComponent` di [BaseMecha](file:///c:/Users/game/scripts/characters/base_mecha.gd) untuk memancarkan `EventBus.overclock_triggered`.

4. **Automated Verification Suite (`tests/test_mecha_combat_sfx.gd` & `.tscn`)**:
   - Memvalidasi pembentukan seluruh buffer stream audio baru (`thruster_dash`, `overclock_alarm`, `meltdown_shutdown`, `heavy_impact`, `wall_bounce`).
   - Memvalidasi pemicuan SFX melalui `state_changed`, `overclock_triggered`, dan `hit_confirmed`.
   - Memastikan seluruh 28 test suite yang telah ada sebelumnya tetap lulus 100%.

## Tasks / Subtasks

- [x] Task 1: SFX Synthesizer Expansion (`scripts/audio/audio_synthesizer.gd`) (AC: 1)
  - [x] 1.1 Implementasikan `generate_thruster_dash`
  - [x] 1.2 Implementasikan `generate_overclock_alarm`
  - [x] 1.3 Implementasikan `generate_meltdown_shutdown`
  - [x] 1.4 Implementasikan `generate_heavy_impact` dan `generate_wall_bounce`
- [x] Task 2: EventBus & BaseMecha Overclock Signal Integration (AC: 3)
  - [x] 2.1 Tambahkan sinyal `overclock_triggered` di `scripts/core/event_bus.gd`
  - [x] 2.2 Sambungkan `heat_component.overclock_state_changed` di `scripts/characters/base_mecha.gd`
- [x] Task 3: AudioManager Dynamic Dispatch Subsystem (`scripts/audio/audio_manager.gd`) (AC: 2)
  - [x] 3.1 Inisialisasi dan cache stream audio baru
  - [x] 3.2 Implementasikan listener `EventBus.state_changed` untuk Dash dan Meltdown
  - [x] 3.3 Implementasikan listener `EventBus.overclock_triggered` untuk Overclock Alarm
  - [x] 3.4 Perluas listener `EventBus.hit_confirmed` untuk variasi dampak pukulan berat
  - [x] 3.5 Sediakan helper method publik
- [x] Task 4: Automated Verification Suite & Regression (AC: 4)
  - [x] 4.1 Buat `tests/test_mecha_combat_sfx.gd` dan `tests/test_mecha_combat_sfx.tscn`
  - [x] 4.2 Daftarkan di `tests/run_all_tests.ps1` dan jalankan master test suite
