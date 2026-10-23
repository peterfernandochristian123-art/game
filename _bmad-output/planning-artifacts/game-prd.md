---
title: "Product Requirements Document (PRD): Fighting to Zero"
status: complete
version: "1.2.0"
created: '2026-10-23'
---

# Product Requirements Document (PRD): Fighting to Zero

## 1. Product Summary & Vision

**Fighting to Zero** adalah game duel petarung 2D 1v1 arcade kompetitif berkecepatan tinggi yang menggabungkan estetika seni bela diri retro 32-bit dengan sistem kontrol 3-Skill terpadu tanpa motion input rumit. 

### Unique Selling Propositions (USPs):
1. **Unified 3-Skill Architecture**: Tidak ada putaran analog atau kombinasi tombol rumit; keahlian ditentukan oleh pembacaan jarak (*spacing*), reaksi parry, dan strategi risiko panas.
2. **Thermal Risk-Reward Engine**: Manajemen suhu internal mecha (Overclock Super Armor pada 80–99% vs Meltdown Shutdown pada 100%).
3. **Clutch Cliffhanger & Wall Combat**: Perebutan dramatis di bibir jurang tanpa pembatas (Skyscraper) dan tekanan sudut kombo pantulan dinding (Reactor).
4. **Lintas Platform Setara**: Pengalaman kontrol seimbang antara Mobile Touch dan Gamepad/PC.

---

## 2. Requirements Matrix

### Functional Requirements (FR)
- **FR1 (Vector Dash)**: Dorongan jet 8-arah (750 px/s, 14f) darat dan udara.
- **FR2 (Single-Button Controls)**: Normal, Skill 1, Skill 2, Ultimate, Parry, Block.
- **FR3 (Buffer & Coyote Time)**: Circular buffer 5 frame (83.3 ms) dan coyote time 5f.
- **FR4 (Heat Management)**: Meteran panas 0–100% dengan pendinginan pasif -12%/s.
- **FR5 (Overclock Buffs)**: Bonus damage +20% dan 1-Hit Super Armor saat 80–99% Heat.
- **FR6 (Meltdown Penalty)**: Kuncian kelumpuhan 90 frame saat menyentuh 100% Heat.
- **FR7 (Spark Parry)**: Tangkisan presisi window 4 frame (f2-f5), curi 15% ulti, buang 20% heat.
- **FR8 (Blocking & Chip)**: Redam 100% damage fisik, terima 20% chip damage skill energi.
- **FR9 (Target Chain Scaling)**: Combo scaling 100%->25%, maks 1 ground bounce & 1 wall bounce.
- **FR10 (Apex-0 Viper)**: Archetype Rushdown (Blink Slash, Deflection Matrix, Absolute Zero).
- **FR11 (Titan-V Bulwark)**: Archetype Grappler (Hydraulic Piledriver, Riot Shield, Orbital Siege).
- **FR12 (Zero-G Skyscraper)**: Arena platform 1280px terbuka dengan sensor tepi X<64 dan X>1344.
- **FR13 (Cliffhanger System)**: Gantung tebing 120 frame dengan opsi Climb, Sweep, atau Drop.
- **FR14 (Ledge Stomp)**: Serangan injakan tebing pemicu instan Ring-Out.
- **FR15 (Match Rules)**: Format Best of 3 rounds (90s per ronde) dan Sudden Death 30s.
- **FR16 (Versus AI)**: AI bot dengan profil Novice, Veteran, dan Ace.
- **FR17 (Training Mode)**: Overlay hitbox F1, dummy controller F2, dan reset F3.
- **FR18 (Local 2P)**: Pertarungan 2 pemain lokal dengan gamepad mandiri.
- **FR19 (Ray-X Pulsar)**: Petarung ke-3 tipe Zoner (Photon Railgun, Drone, Supernova).
- **FR20 (Character Select)**: Antarmuka seleksi petarung 32-bit dengan preview sprite dinamis.
- **FR21 (Underground Reactor)**: Arena ke-2 bertembok pantul dengan bahaya semburan uap geotermal.

### Non-Functional Requirements (NFR)
- **NFR1**: Terkunci pada 60 FPS deterministik pada physics cycle.
- **NFR2**: Input latency < 50 ms.
- **NFR3**: Konsumsi memori runtime < 600 MB RAM.
- **NFR4**: Waktu transisi scene < 3.0 detik.
- **NFR5**: Kompatibilitas renderer OpenGL ES 3.0 / Compatibility mode.
- **NFR6**: 0 crash selama 100 ronde uji beban berkelanjutan.
- **NFR7**: Resolusi internal native 640x360 dengan integer scaling.
- **NFR8**: Persistensi pengaturan audio dan kontrol lokal di `user://settings.cfg`.

---

## 3. Delivery & Verification Status

- **Status Pengembangan**: Epics 1 s.d. 12 selesai 100% (Done).
- **Status Pengujian**: 32/32 Test Suites lulus otomatis.
- **Packaging**: Paket mandiri Windows `FightingToZero.exe` & `FightingToZero.pck` terenkapsulasi siap rilis.
