# Epics & High-Level Stories: Fighting to Zero

Dokumen ini merinci pembagian *Development Epics* dan *User Stories* tingkat tinggi untuk pengembangan fase MVP *Fighting to Zero*. Setiap epic dirancang untuk menghasilkan *playable milestone* yang dapat diuji secara langsung.

---

## Ringkasan Urutan Rilis Epic

| Epic ID | Nama Epic | Fokus Utama | Deliverable yang Dapat Dimainkan |
| :--- | :--- | :--- | :--- |
| **EPIC-01** | Core Physics & Movement | Fondasi pergerakan 8-arah & deteksi tumbukan | Kotak uji karakter bergerak, meluncur di tanah, dan *vector dash* di udara. |
| **EPIC-02** | Heat & Defense Mechanics | Manajemen panas, *Spark Parry*, & status *Overheat* | Siklus trade pukulan, bar panas berfungsi, dan parry presisi frame aktif. |
| **EPIC-03** | Roster MVP: Viper & Bulwark | Kit lengkap 2 mecha (S1, S2, Ulti, Normals) | Pertarungan 2 karakter dengan archetype berbeda (Rushdown vs Grappler). |
| **EPIC-04** | Arena & Cliffhanger System | Platform melayang & perebutan bibir tebing | Arena dengan jurang fungsional, memicu adu rebutan *Cliffhanger* 2 detik. |
| **EPIC-05** | Game Modes & Dual Input HUD | Training mode, Versus AI, & Dual Touch/Gamepad UI | Alur game utuh: Pilih karakter, training dengan display hitbox, match AI. |
| **EPIC-06** | Audio-Visual Juice & Performance | Efek getar layar, partikel percikan api, & optimasi 60 FPS | Game terpoles siap rilis internal/alpha test di PC dan Android. |

---

## Detail Epics & Cerita Pengguna (User Stories)

### EPIC-01: Core Physics & Movement Engine
- **Tujuan**: Membangun fondasi kontrol pergerakan 2D yang presisi dengan respons instan tanpa hambatan inersia berlebih.
- **Scope Masuk**:
  - Pergerakan horizontal (kecepatan jalan 320 px/s).
  - *8-Way Thruster Vector Dash* (durasi 14 frame, kecepatan 750 px/s, cooldown 18 frame).
  - Sistem lompat dengan *Coyote Time* (5 frame) dan *Input Buffer Window* (5 frame).
  - Rantai serangan dasar (Light Normal, Heavy Normal) dengan collision hit/hurtbox standar.
- **Scope Keluar**: Skill khusus, animasi final, visual shader.
- **Stories**:
  - `STORY-01.1`: Implementasi mesin state pergerakan (Idle, Walk, Jump, Dash, Hitstun, Blockstun).
  - `STORY-01.2`: Implementasi sistem Vector Dash 8 arah dengan pembatasan 1 dash udara sebelum mendarat.
  - `STORY-01.3`: Implementasi sistem input buffering 5 frame terpadu untuk keyboard, gamepad, dan on-screen buttons.
  - `STORY-01.4`: Implementasi hit/hurtbox 2D berbasis frame dengan deteksi counter-hit.

---

### EPIC-02: Heat System & Combat Defense
- **Tujuan**: Mewujudkan pilar *Thermal Risk-Reward* dan *Refleks Parry* sebagai pengatur tempo pertarungan.
- **Scope Masuk**:
  - Pengukur panas (*Heat Gauge* 0–100%) dengan logika pendinginan alami (-12%/detik saat diam).
  - Status *Overclock Zone* (80–99%): Menambahkan bonus damage +20% dan 1-hit super armor pada fase startup.
  - Status *Emergency Meltdown* (100%): Lumpuh 90 frame (1.5 detik), penerimaan damage +25%.
  - *Spark Parry*: Window aktif 4 frame (frame 2–5), startup 1 frame, whiff recovery 14 frame. Efek: Menahan serangan, freeze musuh 12 frame, mencuri 15% energi Ultimate, membuang 20% panas.
  - Sistem *Normal Blocking* (reduksi damage 80%, chip damage 20% untuk serangan spesial).
- **Scope Keluar**: Suara khusus mecha individual, visual FX final.
- **Stories**:
  - `STORY-02.1`: Implementasi komponen Heat Engine dan integrasi kalkulasi suhu pada aksi menyerang/dash.
  - `STORY-02.2`: Implementasi status modifikasi damage & armor pada zona panas 80–99%.
  - `STORY-02.3`: Implementasi status penalti Meltdown 100% dan animasi pendinginan darurat.
  - `STORY-02.4`: Implementasi mekanik Spark Parry dengan window presisi frame dan logika penyerapan meteran musuh.

---

### EPIC-03: Roster MVP (Apex-0 "Viper" & Titan-V "Bulwark")
- **Tujuan**: Menyelesaikan dua karakter petarung dengan playstyle kontras yang membuktikan kedalaman archetype.
- **Scope Masuk**:
  - **Apex-0 "Viper"**:
    - Normal 3-hit string (Light Jab 3f startup, Beam Thrust 6f, Overhead Slash 11f).
    - Skill 1: *Blink Slash* (teleportasi horizontal cepat + tebasan, menembus proyektil, +25% Heat).
    - Skill 2: *Deflection Matrix* (pelindung energi pemantul proyektil / penyerap serangan, +20% Heat).
    - Ultimate: *Absolute Zero Protocol* (mode overclock 8 detik, panas tidak naik, dash tak terbatas).
  - **Titan-V "Bulwark"**:
    - Normal 2-hit heavy (Hydraulic Fist 7f startup, Ground Pound 14f).
    - Skill 1: *Hydraulic Piledriver* (command grab jarak dekat, membanting musuh dengan damage masif, +35% Heat).
    - Skill 2: *Riot Shield Deploy* (tameng stasioner penyerap serangan, super armor penuh, +15% Heat).
    - Ultimate: *Orbital Siege Cannon* (tembakan laser partikel raksasa layar penuh berdamage 45% HP).
- **Scope Keluar**: Kostum alternatif, animasi intro/outro kompleks.
- **Stories**:
  - `STORY-03.1`: Pembuatan sprite data dan parameter frame data untuk Apex-0 Viper.
  - `STORY-03.2`: Implementasi Skill 1, 2, dan Ultimate Viper beserta hitbox uniknya.
  - `STORY-03.3`: Pembuatan sprite data dan parameter frame data untuk Titan-V Bulwark.
  - `STORY-03.4`: Implementasi sistem Command Grab (Hydraulic Piledriver) dan Riot Shield Titan-V.
  - `STORY-03.5`: Penyeimbangan rasio HP (Viper 900 HP vs Bulwark 1200 HP).

---

### EPIC-04: Arena & Cliffhanger System
- **Tujuan**: Mewujudkan pilar arena tanpa dinding pembatas dan mekanik perebutan tepi tebing (*Cliffhanger struggle*).
- **Scope Masuk**:
  - Platform arena *Zero-G Skyscraper Platform* (lebar 1280 piksel, ketinggian tak terbatas ke bawah di kedua sisi).
  - Mekanik trigger Cliffhanger saat karakter terlempar melewati batas platform (durasi gantung 120 frame / 2.0 detik).
  - Pilihan aksi bagi pemain yang bergelantungan:
    - *Climb-Up Jump* (18f startup).
    - *Ledge Sweep Attack* (12f startup, 10% damage, -2 on block).
    - *Drop Fall* (konfirmasi jatuh / ring-out).
  - Aksi bagi pemain di atas platform:
    - *Ledge Stomp* (Down + Normal, 15f startup, memicu instan Ring-Out jika mengenai karakter bergelantungan).
  - Logika evaluasi ronde dan deklarasi pemenang (Best of 3 rounds).
- **Scope Keluar**: Arena interaktif dengan platform dinamis bergulir (disimpan untuk update v1.1).
- **Stories**:
  - `STORY-04.1`: Pembuatan boundary detection pada kedua ujung platform arena.
  - `STORY-04.2`: Implementasi state machine Cliffhanger (Ledge Grab, Hang Timer, Stomp Vulnerability).
  - `STORY-04.3`: Implementasi aksi balasan pemain menggantung (Climb, Sweep, Drop).
  - `STORY-04.4`: Implementasi ring-out detector dan transisi round reset.

---

### EPIC-05: Game Modes & Dual Input HUD
- **Tujuan**: Menyediakan alur pengalaman bermain yang ramah pengguna di PC dan mobile touchscreen.
- **Scope Masuk**:
  - *Versus AI Mode* (Logika AI dengan 3 tingkat kesulitan: Novice, Veteran, Ace).
  - *Training Mode* komprehensif: Opsi tampilan hitbox/hurtbox, data frame (startup/active/recovery), status panas, dan perekam aksi dummy.
  - *Local Versus Mode* (Dukungan dua kontroler gamepad pada PC).
  - *Touch UI Mobile*: Tombol sentuh virtual adaptif (Floating D-pad di kiri; tombol Normal, Dash, S1, S2, Ulti, Parry di kanan) dengan haptic feedback dasar.
- **Scope Keluar**: Online Rollback multiplayer (arsitektur dipersiapkan untuk fase pasca-MVP).
- **Stories**:
  - `STORY-05.1`: Implementasi state machine perilaku AI (Spacing, Heat Venting, Parry Reaction based on difficulty).
  - `STORY-05.2`: Pembuatan Training Mode Suite (Hitbox renderer toggle, frame data display, input history).
  - `STORY-05.3`: Implementasi Touch Overlay dengan auto-detection tipe platform (Mobile vs PC).
  - `STORY-05.4`: Menu pemilihan karakter, pengaturan tombol, dan transisi layar permainan.

---

### EPIC-06: Audio-Visual Juice & Performance Target
- **Tujuan**: Memberikan rasa tabrakan baja (*game feel*) yang memuaskan dan menjaga target 60 FPS terkunci.
- **Scope Masuk**:
  - Efek hitstop (freeze frame: 4 frame pada light hit, 10 frame pada heavy hit, 16 frame pada Ultimate).
  - Camera shake proporsional terhadap bobot serangan.
  - Efek visual partikel percikan api baja (*welding sparks*), asap pembuangan panas, dan laser beam glow shader.
  - SFX benturan logam, desis hidrolik, dan suara *Announcer* pertarungan retro.
  - Profiling performa: 60 FPS stabil di PC spek menengah ke bawah dan perangkat Android setara Snapdragon 680 ke atas.
- **Scope Keluar**: Soundtrack live orchestra (menggunakan synthwave/industrial retro berkualitas tinggi).
- **Stories**:
  - `STORY-06.1`: Implementasi sistem Hitstop global dan kamera dinamis (Zoom-in saat Cliffhanger / Parry).
  - `STORY-06.2`: Integrasi shader percikan api, laser beam, dan uap knalpot mecha saat overheat.
  - `STORY-06.3`: Integrasi tata suara SFX dampak pukulan, hydraulic, dan announcer.
  - `STORY-06.4`: Profiling performa dan optimasi render draw-calls pada Godot Engine 4 untuk mobile.
