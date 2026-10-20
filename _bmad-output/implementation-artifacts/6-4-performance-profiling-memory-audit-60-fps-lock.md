---
baseline_commit: c1718cf
---

# Story 6.4: Performance Profiling, Memory Audit & 60 FPS Lock

Status: review

## Story

As a player on target PC or mobile devices,
I want a locked 60 FPS experience with zero crashes and memory usage under 600 MB,
So that gameplay is fluid, tournament-ready, and never stutters.

## Acceptance Criteria

1. **Deterministic 60 FPS Frame Lock & Physics Configuration**:
   - `Engine.max_fps` dikonfigurasi ke 60 FPS dan `Engine.physics_ticks_per_second` terkunci pada 60 Hz.
   - Project settings mengonfigurasi rendering retro pixel-perfect 640x360 dengan VSync dan frame rate lock.

2. **Performance & Memory Monitor Component (`scripts/core/performance_monitor.gd`)**:
   - Memantau metrik performa real-time:
     - `get_current_fps()`: Frame rate rata-rata.
     - `get_memory_usage_mb()`: Penggunaan RAM fisik/statis (OS / Performance monitor).
     - `get_orphan_node_count()`: Audit node yatim piatu / memory leaks.
   - Peringatan otomatis jika penggunaan RAM mendekati ambang batas 600 MB.

3. **Automated Combat Stress Test (`tests/test_performance_stress.gd` & `tests/test_performance_stress.tscn`)**:
   - Menjalankan simulasi intensif 100 siklus pertarungan / ribuan frame kontak serangan, combo cancels, partikel las, dan guncangan kamera secara beruntun.
   - Memverifikasi memori stabil di bawah batas aman 600 MB (target < 200 MB pada arsitektur 2D pixel art).
   - Memverifikasi zero crash sepanjang eksekusi.

4. **Unified Master Test Runner (`tests/run_all_tests.ps1`)**:
   - Mengeksekusi seluruh pengujian dari Epic 1 hingga Epic 6 secara headless dan melaporkan rekapitulasi hasil 100% lulus.

## Tasks / Subtasks

- [x] Task 1: Frame Rate Lock & Engine Settings Verification (AC: 1)
  - [x] 1.1 Konfigurasi `Engine.max_fps = 60` di startup atau project configuration (`scripts/core/performance_monitor.gd`).
- [x] Task 2: Performance & Memory Monitor Subsystem (AC: 2)
  - [x] 2.1 Buat `scripts/core/performance_monitor.gd` untuk audit RAM, FPS, dan Node count.
- [x] Task 3: Automated Stress Test Suite (AC: 3)
  - [x] 3.1 Buat `tests/test_performance_stress.gd` dan `tests/test_performance_stress.tscn`.
- [x] Task 4: Unified Master Test Runner & Verification (AC: 4)
  - [x] 4.1 Buat `tests/run_all_tests.ps1`.
  - [x] 4.2 Jalankan master test runner headless (100% pass) dan verifikasi seluruh sistem.

## Dev Agent Record

### Implementation Summary
- Dibuat `scripts/core/performance_monitor.gd` untuk mengunci frame rate ke 60 FPS (`Engine.max_fps = 60`), mengaudit RAM (`OS.get_static_memory_usage()`), memantau orphan nodes, dan menyusun laporan diagnostik sistem.
- Dibuat `tests/test_performance_stress.gd` dan `tests/test_performance_stress.tscn` untuk simulasi stres 100 siklus pertarungan bertubi-tubi dengan instansiasi VFX, hitstop, dan audio bus. Hasil memori puncak hanya 31.24 MB (jauh di bawah batas 600 MB).
- Dibuat Master Test Runner `tests/run_all_tests.ps1` yang menjalankan 25 test suite dari Epic 1 hingga Epic 6 secara sekuensial dan headless.
- Memperbaiki ketidaksesuaian signature pada `scripts/ai/ai_controller.gd` (`_on_hit_confirmed`) sehingga sesuai dengan `EventBus.hit_confirmed`.
