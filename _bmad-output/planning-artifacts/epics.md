---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - "_bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/gdd.md"
  - "_bmad-output/game-architecture.md"
---

# Fighting to Zero - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Fighting to Zero, decomposing the requirements from the GDD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

- **FR1: 8-Way Thruster Vector Dash & Movement**: Pemain dapat menggerakkan karakter secara horizontal (kecepatan jalan 260–350 px/s) dan mengeksekusi dorongan jet 8-arah (*Vector Dash*, 14f, 750 px/s) di darat maupun udara dengan batasan 1 dash udara sebelum mendarat.
- **FR2: Unified 3-Skill Input Architecture**: Sistem input memetakan kontrol ke tombol tunggal (Normal Attack, Skill 1, Skill 2, Ultimate, Parry, Block) tanpa kombo putaran stik (*motion inputs/quarter-circles*) yang setara antara gamepad/keyboard PC dan floating touch joystick mobile.
- **FR3: Input Buffering & Coyote Time**: Sistem harus menyediakan input buffer window 5 frame (83.3 ms pada 60 FPS) dan coyote time 5 frame untuk toleransi transisi aksi dan lompatan/dash di tepi platform.
- **FR4: Heat Gauge Engine & Passive Cooling**: Mecha memiliki meteran panas internal 0–100% yang bertambah saat menyerang/dash dan mendingin secara pasif sebesar -12% per detik saat idle/berjalan.
- **FR5: Overclock Risk-Reward State**: Saat panas mencapai 80–99%, serangan skill menghasilkan bonus damage +20% dan mendapatkan status *1-Hit Super Armor* pada fase startup serangan.
- **FR6: Emergency Meltdown Penalization**: Saat panas menyentuh 100%, mecha mengalami *Core Shutdown* selama 90 frame (1.5 detik), lumpuh tanpa bisa bergerak/bertahan, menerima damage masuk +25%, dan setelah selesai suhu direset ke 0%.
- **FR7: Spark Parry System**: Pemain dapat mengeksekusi tangkisan presisi dengan window aktif 4 frame (frame 2–5). Keberhasilan memicu 12-frame hitstop, menyerap 15% bar Ultimate lawan, dan membuang 20% panas mecha sendiri; kegagalan (*whiff*) memicu recovery 14 frame yang rentan counter-hit.
- **FR8: Blocking & Chip Damage**: Menahan arah berlawanan dari posisi lawan menahan 100% serangan fisik biasa dan menerima 20% chip damage dari serangan spesial berbasis energi.
- **FR9: Target Chain & Damage Scaling**: Sistem kombo mendukung *Target Chain Cancel* (Normal 1 → Normal 2 → Skill) dan membatasi damage scaling bertahap (100% → 85% → 70% → -10%/hit, floor 25%) serta membatasi maksimal 1 ground bounce dan 1 wall/edge bounce per kombo.
- **FR10: Apex-0 "Viper" Character Kit**: Karakter tipe High-Speed Rushdown dengan 900 HP, 3-hit Rapier Beam combo, Skill 1 (*Blink Slash* tembus 400px +25% Heat), Skill 2 (*Deflection Matrix* pemantul proyektil +20% Heat), dan Ultimate (*Absolute Zero Protocol* kunci panas 0% selama 8s).
- **FR11: Titan-V "Bulwark" Character Kit**: Karakter tipe Heavy Grappler dengan 1200 HP (-5% passive damage reduction), 2-hit Heavy Impact, Skill 1 (*Hydraulic Piledriver* command grab tak dapat diblock +35% Heat), Skill 2 (*Riot Shield Deploy* super armor penuh 45f +15% Heat), dan Ultimate (*Orbital Siege Cannon* 450 HP damage).
- **FR12: Zero-G Skyscraper Arena & Boundaries**: Arena pertarungan berupa platform datar selebar 1280 piksel tanpa dinding pembatas dengan sensor tepi di X < 64 dan X > 1344.
- **FR13: Cliffhanger Struggle System**: Mecha yang terlempar ke luar platform arena secara otomatis meraih bibir tebing (maks 1x per ronde) selama 120 frame (2 detik) dengan pilihan aksi Climb-Up Jump (18f startup), Ledge Sweep Attack (12f startup), atau Drop Fall.
- **FR14: Ledge Stomp & Ring-Out Execution**: Pemain di atas platform dapat mengeksekusi serangan *Ledge Stomp* (Bawah + Serang, 15f startup) yang memicu instan Ring-Out jika mengenai lawan yang sedang menggantung di tebing.
- **FR15: Match Rules & Round Evaluation**: Format pertarungan Best of 3 Rounds (90 detik per ronde) dengan kondisi menang HP 0, Ring Out, atau Time Out HP tertinggi, serta Sudden Death 30 detik (90% Heat) saat seri.
- **FR16: Versus AI Mode**: Mode pertarungan melawan bot dengan 3 profil kesulitan: Novice (reaksi lambat, jarang parry), Veteran (reaksi frame 12, spacing aktif), dan Ace (reaksi frame 6, parry presisi, kombo Overclock).
- **FR17: Training Mode Suite**: Mode latihan interaktif dilengkapi display visualisasi Hitbox (merah), Hurtbox (hijau), dan Collision box (biru), inspector frame data real-time, dummy state configuration (Stand, Crouch, Block, Random Parry), serta recording playback 10 detik.
- **FR18: Local 2-Player Versus Mode**: Dukungan pertarungan lokal 2 pemain di PC dengan deteksi otomatis 2 unit kontroler gamepad independen.

### NonFunctional Requirements

- **NFR1: Framerate & Determinism**: Game harus terkunci pada 60 FPS stabil (frame drop < 0.5% selama durasi pertempuran) dengan simulasi logika pertempuran dihitung deterministik integer frame pada `_physics_process()`.
- **NFR2: Input Latency**: Input lag end-to-end < 50 ms pada PC dengan controller berkabel, dan buffer window 83.3 ms untuk mencegah dropped input pada kontrol sentuh mobile.
- **NFR3: Memory Footprint**: Konsumsi memori runtime < 600 MB RAM pada perangkat PC dan Mobile (Android / iOS).
- **NFR4: Loading Performance**: Waktu transisi dari Character Select ke Arena gameplay < 3.0 detik pada media penyimpanan standar.
- **NFR5: Platform Compatibility**: Mendukung target PC (Windows / Linux via Proton) dan Mobile (Android 9.0+ / iOS 14+) dengan Compatibility Renderer (OpenGL ES 3.0) untuk mencegah shader compilation stutter.
- **NFR6: Stability & Zero-Crash**: Sistem memiliki 0 crash selama 100 ronde pertempuran otomatis berturut-turut, dengan safe degradation fallback ke IdleState jika terjadi anomali state atau resource.
- **NFR7: Pixel Art Visual Fidelity**: Rendering kanvas internal tetap pada 640x360 piksel dengan integer pixel scaling ke 720p/1080p/1440p/4K tanpa distorsi blur pixel.
- **NFR8: Local Data Persistence**: Penyimpanan pengaturan (volume, keybindings, mobile touch layout) dan rekor profil pemain menggunakan format `ConfigFile` Godot (`user://settings.cfg` dan `user://records.cfg`).

### Additional Requirements

- **Starter Template / Greenfield Strategy**: Menggunakan Modular Custom Node-Based Fighting Controller dalam Godot 4 (GDScript Statically Typed) tanpa dependensi eksternal berat (Wajib menjadi dasar Epic 1 Story 1).
- **Autoload Infrastructure**: Mendaftarkan dan menginisialisasi singleton global `EventBus` (`scripts/core/event_bus.gd`), `InputBuffer` (`scripts/core/input_buffer.gd`), dan `CombatJuiceManager` (`scripts/combat/combat_juice_manager.gd`).
- **Data-Driven Move List (`.tres`)**: Seluruh nilai damage, startup, active, recovery, dan frame advantage disimpan dalam Godot Text Resource (`AttackData extends Resource`) terisolasi dari kode logika FSM.
- **Dedicated Collision Layer Matrix**: Pemisahan layer Area2D eksplisit (Layer 1: World, Layer 2: Hurtbox, Layer 3: Strike Hitbox, Layer 4: Grab Hitbox, Layer 5: Ledge Sensor).
- **Local Hitstop Freeze Mechanism**: Penghentian frame logika mecha lokal saat parry/hit tanpa membekukan thread engine atau rendering efek partikel.
- **AI Tooling MCP Integration**: Konfigurasi server GoPeak (`HaD0Yun/Gopeak-godot-mcp`) dan Context7 untuk inspeksi scene tree dan referensi engine Godot 4.

### UX Design Requirements

- **UX-DR1: Dynamic Floating Virtual Joystick**: Implementasi joystick virtual dinamis di sisi kiri layar yang muncul otomatis di posisi jempol pertama kali menyentuh layar.
- **UX-DR2: Dual-Thumb 6-Button Ergonomic Mobile Layout**: Tata letak tombol sentuh ergonomis di sisi kanan (Normal, Dash, Skill 1, Skill 2, Parry, Ultimate) dengan area sentuh nyaman untuk layar target minimum 5.5 inci.
- **UX-DR3: Neo-Retro 32-Bit HUD**: Tampilan status pertarungan layar penuh yang mencakup HP Bar, Heat Gauge dinamis (dengan indikator warna Nominal/Overclock/Meltdown), Ultimate Meter, Round Timer 90 detik, dan Round Win Counters.
- **UX-DR4: On-Screen Frame Inspector & Hitbox Debug Overlay**: Tampilan UI overlay debug (F1/Touch toggle) untuk menampilkan bounding box berwarna (Hitbox merah, Hurtbox hijau, Pushbox biru) dan teks metrik frame advantage real-time.
- **UX-DR5: Combat Juice Visual FX**: Umpan balik visual real-time meliputi partikel las percikan api dinamis (*welding sparks*), tebasan laser neon berpendar, distorsi uap saat Overclock, dan guncangan layar (*screen shake*).
- **UX-DR6: Announcer & Audio Bus Feedback**: Penataan audio dengan bus independen (Master, BGM, SFX, Announcer, MechaVoice) dengan voice announcer retro 90-an untuk round intro dan event penting.

### FR Coverage Map

- **FR1: 8-Way Thruster Vector Dash & Movement** -> **Epic 1** (Fondasi pergerakan horizontal, lompat, dan vector dash 8-arah)
- **FR2: Unified 3-Skill Input Architecture** -> **Epic 1** (Skema tombol tunggal seragam tanpa motion inputs)
- **FR3: Input Buffering & Coyote Time** -> **Epic 1** (Buffer 5 frame 83.3 ms dan coyote time 5 frame)
- **FR4: Heat Gauge Engine & Passive Cooling** -> **Epic 2** (Manajemen meteran panas 0–100% dan pendinginan pasif -12%/s)
- **FR5: Overclock Risk-Reward State** -> **Epic 2** (Buff zona 80–99% dengan +20% damage dan 1-Hit Super Armor)
- **FR6: Emergency Meltdown Penalization** -> **Epic 2** (Penalti zona 100% shutdown 90 frame dan damage masuk +25%)
- **FR7: Spark Parry System** -> **Epic 2** (Tangkisan presisi 4 frame aktif, 12f hitstop, curi 15% ulti, buang 20% panas)
- **FR8: Blocking & Chip Damage** -> **Epic 2** (Mekanik bertahan menahan arah belakang dan 20% chip damage)
- **FR9: Target Chain & Damage Scaling** -> **Epic 3** (Target chain cancel, scaling damage berjenjang, max 1 bounce)
- **FR10: Apex-0 "Viper" Character Kit** -> **Epic 3** (Kit lengkap archetype Rushdown: Blink Slash, Deflection Matrix, Absolute Zero)
- **FR11: Titan-V "Bulwark" Character Kit** -> **Epic 3** (Kit lengkap archetype Grappler: Hydraulic Piledriver, Riot Shield, Orbital Siege)
- **FR12: Zero-G Skyscraper Arena & Boundaries** -> **Epic 4** (Platform datar 1280px dan sensor batas jurang kiri-kanan)
- **FR13: Cliffhanger Struggle System** -> **Epic 4** (Mekanik gantung tebing 120 frame dengan opsi Climb, Sweep, Drop)
- **FR14: Ledge Stomp & Ring-Out Execution** -> **Epic 4** (Aksi injakan maut dari atas platform pemicu instan Ring-Out)
- **FR15: Match Rules & Round Evaluation** -> **Epic 4** (Sistem Best of 3 Rounds 90s, penentuan K.O., Ring-Out, Time-Out, Sudden Death)
- **FR16: Versus AI Mode** -> **Epic 5** (Duel bot AI dengan tingkat Novice, Veteran, dan Ace)
- **FR17: Training Mode Suite** -> **Epic 5** (Display hitbox/hurtbox/pushbox, inspector frame data, konfigurasi dummy)
- **FR18: Local 2-Player Versus Mode** -> **Epic 5** (Pertarungan lokal 2 pemain di PC dengan deteksi otomatis gamepad)

## Epic List

### Epic 1: Core Physics & Movement Engine
Membangun fondasi pergerakan mecha 2D yang responsif dan presisi dengan kontrol berbasis tombol tunggal, buffer input deterministik 60 FPS, dan serangan normal dasar.
**FRs covered:** FR1, FR2, FR3

### Epic 2: Heat System & Combat Defense Mechanics
Mengintegrasikan siklus taktis risiko panas (Heat Gauge, Overclock super armor, Meltdown lockout) dan mekanisme pertahanan aktif (Spark Parry, Blocking, Chip damage).
**FRs covered:** FR4, FR5, FR6, FR7, FR8

### Epic 3: Playable MVP Character Roster (Apex-0 Viper & Titan-V Bulwark)
Mewujudkan dua petarung mecha berkepribadian kontras (Rushdown vs Grappler) dengan kit jurus lengkap, sistem kombo Target Chain, dan kalkulasi damage scaling yang seimbang.
**FRs covered:** FR9, FR10, FR11

### Epic 4: Zero-G Arena & Cliffhanger System
Mewujudkan arena pencakar langit melayang tanpa dinding pengaman, memicu fase duel asimetris di tubir jurang (Cliffhanger Struggle 120 frame), injakan maut Ledge Stomp, dan evaluasi pertandingan Best of 3 Rounds.
**FRs covered:** FR12, FR13, FR14, FR15

### Epic 5: Game Modes & Dual-Input Interface
Menyediakan pengalaman bermain utuh yang ramah pemain di PC dan Mobile melalui antarmuka Main Menu, Training Mode Suite dengan Frame Inspector, Versus AI (Novice/Veteran/Ace), Local 2-Player Versus, dan Dynamic Floating Touch Joystick.
**FRs covered:** FR16, FR17, FR18

### Epic 6: Audio-Visual Juice, Combat Feedback & Performance Polish
Menyempurnakan kenikmatan benturan baja (*game feel*) melalui sistem hitstop lokal, guncangan layar (*screen shake*), partikel las percikan api, announcer retro 90-an, konfigurasi bus audio, dan optimasi performa 60 FPS terkunci.
**Requirements covered:** NFR1, NFR2, NFR3, NFR4, NFR5, NFR6, NFR7, UX-DR5, UX-DR6

---

## Epic 1: Core Physics & Movement Engine

Membangun fondasi pergerakan mecha 2D yang responsif dan presisi dengan kontrol berbasis tombol tunggal, buffer input deterministik 60 FPS, dan serangan normal dasar.

### Story 1.1: Project Setup, Autoload Infrastructure & Movement State Machine

As a player,
I want to move my mecha horizontally (walk) and jump with responsive 2D physics,
So that I can position my mecha reliably on the combat platform.

**Acceptance Criteria:**

**Given** proyek Godot 4 telah diinisialisasi dengan kanvas 640x360 dan singleton global Autoload `EventBus` terdaftar,
**When** pemain menekan tombol arah kiri atau kanan (WASD / D-Pad),
**Then** mecha bergerak horizontal dengan kecepatan jalan konsisten (antara 260 px/s hingga 350 px/s sesuai archetype),
**And** transisi status mecha antara `IdleState`, `WalkState`, `JumpState`, dan `FallState` dievaluasi deterministik pada `_physics_process(delta)` 60 FPS tanpa inersia meluncur berlebih.

---

### Story 1.2: 8-Way Thruster Vector Dash System

As a player,
I want to execute an instant thruster dash in any of the 8 directions on the ground or in mid-air,
So that I can quickly reposition, dodge attacks, and close the distance with my opponent.

**Acceptance Criteria:**

**Given** mecha berada dalam kondisi `IdleState`, `WalkState`, atau di udara (`JumpState`),
**When** pemain menekan tombol Dash bersamaan dengan arah vektor joystick/D-Pad,
**Then** mecha meluncur seketika ke salah satu dari 8 arah dengan kecepatan 750 px/s selama 14 frame,
**And** mecha dibatasi maksimal 1 kali Vector Dash di udara sebelum menyentuh tanah kembali,
**And** sistem menerapkan cooldown selama 18 frame sebelum dash berikutnya dapat dieksekusi.

---

### Story 1.3: Unified 5-Frame Input Buffer & Coyote Time

As a player using a gamepad, keyboard, or touch screen,
I want my action inputs during recovery animations or ledge departure to be buffered and executed reliably,
So that I do not suffer from dropped inputs or missed combos due to strict timing windows.

**Acceptance Criteria:**

**Given** mecha sedang berada dalam status animasi Recovery atau Blockstun,
**When** pemain menekan tombol aksi (Attack, Dash, Jump) dalam jendela 5 frame terakhir (83.3 ms pada 60 FPS) sebelum status kembali Actionable,
**Then** input yang tersimpan di Circular Buffer otomatis dieksekusi pada frame pertama mecha kembali aktif,
**And** jika mecha baru saja melangkah keluar dari tepi platform tanpa melompat, pemain masih dapat melompat selama durasi Coyote Time 5 frame.

---

### Story 1.4: Base Normal Attacks & Frame-Based Hit/Hurtbox Collision

As a player,
I want to perform light and heavy normal attacks with precise hit detection against the opponent's hurtbox,
So that I can engage in close-range footsies and start basic offensive pressure.

**Acceptance Criteria:**

**Given** mecha berjarak serang dengan lawan di platform,
**When** pemain menekan tombol Normal Attack,
**Then** mecha mengeksekusi serangan normal (Light Normal atau Heavy Normal) sesuai parameter startup frame,
**And** node `HitboxArea2D` (Layer 3) hanya diaktifkan selama jendela `active_frames` yang ditentukan,
**And** jika mengenai `HurtboxArea2D` lawan (Layer 2), memancarkan sinyal `hit_confirmed` via `EventBus` dan mengunci lawan dalam `HitstunState` sesuai durasi hitstun.

---

## Epic 2: Heat System & Combat Defense Mechanics

Mengintegrasikan siklus taktis risiko panas (Heat Gauge, Overclock super armor, Meltdown lockout) dan mekanisme pertahanan aktif (Spark Parry, Blocking, Chip damage).

### Story 2.1: Heat Gauge Component & Passive Cooling Logic

As a player,
I want every attack and dash action to build internal heat that gradually cools down when standing or walking,
So that I must strategically manage my actions to balance aggression with thermal safety.

**Acceptance Criteria:**

**Given** `HeatComponent` aktif pada mecha dengan rentang panas 0% hingga 100%,
**When** pemain mengeksekusi aksi Dash (+10% Heat) atau Skill ofensif (+15%–35% Heat),
**Then** meteran panas bertambah secara proporsional dan memancarkan sinyal `heat_changed`,
**And** saat karakter berada dalam kondisi `IdleState` atau `WalkState`, suhu berkurang secara pasif sebesar -12% per detik (-0.2% per physics frame).

---

### Story 2.2: Overclock Zone Buffs & Emergency Meltdown Shutdown

As a risk-taking player,
I want powerful buffs when operating in high heat (80–99%) but face severe penalties if reaching 100%,
So that I can experience thrilling high-risk, high-reward tactical combat.

**Acceptance Criteria:**

**Given** suhu reaktor mecha mencapai atau melebihi 80.0% dan di bawah 100.0% (Zona Overclock),
**When** mecha mengeksekusi serangan skill,
**Then** mecha memperoleh status `1-Hit Super Armor` pada frame startup dan output damage bertambah +20%,
**And** jika panas mencapai 100.0%, mecha seketika beralih ke `MeltdownShutdownState` selama 90 frame (1.5 detik), tidak dapat menerima input apa pun, menerima damage masuk +25%, dan setelah durasi habis suhu direset ke 0%.

---

### Story 2.3: Spark Parry System with Frame-Exact Window

As a defensive player with sharp reaction,
I want to execute a precision parry on an incoming enemy strike within a tight frame window,
So that I can negate damage, steal enemy ultimate meter, cool down my mech, and seize the combat initiative.

**Acceptance Criteria:**

**Given** mecha berada dalam status netral di darat,
**When** pemain menekan tombol Parry,
**Then** status `ParryState` aktif dengan jendela penangkisan tepat pada frame 2 hingga frame 5 (durasi 4 frame),
**And** jika serangan musuh mengenai mecha selama jendela aktif parry, damage dinolkan, penyerang dibekukan (*hitstop*) selama 12 frame, mecha penyerap menyerap 15% Ultimate meter lawan, dan panas mecha sendiri berkurang 20%,
**And** jika parry gagal mengenai serangan (*whiff*), mecha terkunci dalam recovery selama 14 frame dengan status rentan *Counter-Hit*.

---

### Story 2.4: Normal Blocking & Chip Damage Mechanics

As a defensive player,
I want to guard against enemy attacks by holding the direction away from the opponent,
So that I can safely mitigate normal physical damage and survive offensive strings.

**Acceptance Criteria:**

**Given** lawan sedang melancarkan serangan ke arah mecha,
**When** pemain menahan input arah berlawanan dari posisi lawan (Backward Block),
**Then** mecha beralih ke `BlockstunState` saat serangan mengenai mecha,
**And** damage dari serangan normal fisik diredam 100%,
**And** jika serangan adalah skill berbasis energi, mecha menerima 20% chip damage dari total nilai damage serangan.

---

## Epic 3: Playable MVP Character Roster (Apex-0 Viper & Titan-V Bulwark)

Mewujudkan dua petarung mecha berkepribadian kontras (Rushdown vs Grappler) dengan kit jurus lengkap, sistem kombo Target Chain, dan kalkulasi damage scaling yang seimbang.

### Story 3.1: Data-Driven Attack Architecture & Target Chain Scaling

As a developer and combat designer,
I want all move parameters defined in Godot Resource `.tres` files and combos evaluated with progressive damage scaling,
So that combat balance can be adjusted rapidly without code modifications and combos remain fair.

**Acceptance Criteria:**

**Given** class `AttackData extends Resource` mendefinisikan startup, active, recovery, damage, advantage, dan heat cost,
**When** pemain melakukan kombo beruntun (*Target Chain Cancel* Normal 1 → Normal 2 → Skill),
**Then** pengali damage berkurang berjenjang (Hit 1 = 100%, Hit 2 = 85%, Hit 3 = 70%, Hit 4+ = -10%/hit) dengan damage floor minimum 25%,
**And** sistem membatasi maksimal 1 ground bounce dan 1 wall/edge bounce dalam satu rangkaian kombo untuk mencegah kombo infinite.

---

### Story 3.2: Apex-0 "Viper" Rushdown Character Implementation

As a player preferring speed and aerial dominance,
I want to play as Apex-0 Viper with rapid rapier strikes, teleport slash, deflection matrix, and cryogenic mode,
So that I can out-maneuver heavy opponents with agile hit-and-run tactics.

**Acceptance Criteria:**

**Given** karakter Apex-0 Viper dipilih dengan Max HP 900, kecepatan jalan 350 px/s, dan dash 820 px/s,
**When** pemain mengeksekusi jurus khas Viper:
  - Normal String: 3-hit Rapier Beam Combo (Light Jab 3f, Beam Thrust 6f, Overhead Cleave 11f),
  - Skill 1 (*Blink Slash*): Teleportasi instan menembus garis musuh sejauh 400 px dan menebas dari belakang (+25% Heat),
  - Skill 2 (*Deflection Matrix*): Jaring energi selama 30 frame pemantul proyektil dan memperlambat musuh (+20% Heat),
  - Ultimate (*Absolute Zero Protocol*): Mode kriogenik 8 detik di mana Heat terkunci pada 0%, kecepatan dash meningkat +30%, dan dash udara tidak terbatas,
**Then** seluruh jurus berfungsi sesuai parameter Resource dan frame data GDD §5.1 & §5.2.

---

### Story 3.3: Titan-V "Bulwark" Heavy Grappler Implementation

As a player preferring raw power and space control,
I want to play as Titan-V Bulwark with heavy punches, unblockable piledriver, riot shield, and siege cannon,
So that I can dominate close-quarters combat and punish aggressive opponents with massive damage.

**Acceptance Criteria:**

**Given** karakter Titan-V Bulwark dipilih dengan Max HP 1200, passive armor reduction 5%, kecepatan jalan 260 px/s, dan dash 650 px/s,
**When** pemain mengeksekusi jurus khas Bulwark:
  - Normal String: 2-hit Heavy Impact (Hydraulic Punch 7f, Ground Slam 14f dengan ground bounce),
  - Skill 1 (*Hydraulic Piledriver*): Command grab jarak dekat (Startup 6f, mengabaikan block biasa, damage 220, +35% Heat),
  - Skill 2 (*Riot Shield Deploy*): Perisai baja stasioner dengan status Full Super Armor selama 45 frame (+15% Heat),
  - Ultimate (*Orbital Siege Cannon*): Meriam laser layar penuh berdamage 450 HP (Startup 24f),
**Then** seluruh jurus berfungsi sesuai parameter Resource dan frame data GDD §5.1 & §5.2.

---

## Epic 4: Zero-G Arena & Cliffhanger System

Mewujudkan arena pencakar langit melayang tanpa dinding pengaman, memicu fase duel asimetris di tubir jurang (Cliffhanger Struggle 120 frame), injakan maut Ledge Stomp, dan evaluasi pertandingan Best of 3 Rounds.

### Story 4.1: Zero-G Skyscraper Platform & Arena Boundaries

As a player,
I want to fight on an elevated platform suspended high above New Babel-01 without boundary walls,
So that arena positioning and edge awareness are essential tactical elements of the fight.

**Acceptance Criteria:**

**Given** scene `arena_skyscraper.tscn` dimuat dengan lantai platform baja selebar 1280 piksel,
**When** mecha berada di atas platform,
**Then** tabrakan fisik mecha tertahan di Layer 1 World Collision,
**And** sensor tepi kiri (X < 64) dan tepi kanan (X > 1344) mendeteksi saat mecha melayang di udara melewati batas platform tanpa dinding pembatas.

---

### Story 4.2: Cliffhanger Struggle State Machine & Actions

As a player knocked off the platform edge,
I want my mecha to grab the ledge for 2 seconds and choose between climbing back or sweeping the opponent,
So that I have a thrilling last-second chance to recover or reverse the momentum.

**Acceptance Criteria:**

**Given** mecha terhempas ke luar platform dan masih memiliki HP > 0 (maksimal 1 kali aktivasi per ronde),
**When** mecha melewati batas sensor tebing,
**Then** mecha otomatis meraih bibir tebing dan memasuki `CliffhangerState` dengan timer gantung 120 frame (2.0 detik),
**And** pemain bergelantungan dapat memilih:
  - Tombol Lompat/Atas: Mengeksekusi *Climb-Up Jump* kembali ke panggung (Startup 18 frame),
  - Tombol Serang: Mengeksekusi *Ledge Sweep Attack* (Startup 12 frame, 10% damage, -2 on block),
  - Tombol Bawah atau Timer Habis: Mengeksekusi *Drop Fall* (memicu Ring Out).

---

### Story 4.3: Ledge Stomp & Ring-Out Elimination

As an aggressive player controlling the center stage,
I want to perform a downward ledge stomp on an opponent hanging from the platform edge,
So that I can score an instant Ring-Out victory.

**Acceptance Criteria:**

**Given** lawan berada dalam status `CliffhangerState` menggantung di bibir tebing platform,
**When** pemain di atas platform menekan Tombol Bawah + Serang (*Ledge Stomp*, Startup 15 frame),
**Then** serangan meluncur tepat ke tepi platform,
**And** jika serangan mengenai lawan yang sedang menggantung, cengkeraman lawan lepas seketika dan lawan tereliminasi dengan status *Ring-Out*.

---

### Story 4.4: Match Rules, Round Timers & Win Conditions

As a competitive player,
I want matches conducted under a Best of 3 Rounds format with 90-second timers and sudden death resolution,
So that rounds conclude decisively with clear winner declarations.

**Acceptance Criteria:**

**Given** pertandingan dimulai dengan skor ronde 0 - 0 dan timer 90 detik per ronde,
**When** salah satu kondisi terpenuhi:
  1. HP lawan berkurang hingga 0 (K.O.),
  2. Lawan jatuh melewati batas bawah layar (Ring-Out),
  3. Timer mencapai 0 (pemenang ditentukan oleh sisa % HP tertinggi),
**Then** ronde dinyatakan selesai, pemenang ronde menerima 1 round point, dan ronde direset setelah transisi fade,
**And** mecha yang memenangkan 2 ronde pertama dinyatakan sebagai pemenang pertandingan (*MATCH WINNER*),
**And** jika terjadi skor seri (Double K.O. atau HP identik), sistem memicu babak Sudden Death 30 detik dengan kedua mecha memulai pada 90% Heat.

---

## Epic 5: Game Modes & Dual-Input Interface

Menyediakan pengalaman bermain utuh yang ramah pemain di PC dan Mobile melalui antarmuka Main Menu, Training Mode Suite dengan Frame Inspector, Versus AI (Novice/Veteran/Ace), Local 2-Player Versus, dan Dynamic Floating Touch Joystick.

### Story 5.1: Main Menu & Navigation Flow

As a player,
I want a clean 32-bit styled main menu to select between Versus AI, Training Mode, Local Versus, and Settings,
So that I can seamlessly navigate the game's features.

**Acceptance Criteria:**

**Given** game diluncurkan ke scene `main_menu.tscn`,
**When** pemain menavigasi menu menggunakan keyboard, gamepad, atau layar sentuh,
**Then** opsi menu (Versus AI, Training Mode, Local 2P Versus, Settings, Exit) dapat dipilih dengan visual focus highlight dan SFX konfirmasi,
**And** transisi scene dari Main Menu ke mode permainan berlangsung lancar dalam waktu < 3.0 detik.

---

### Story 5.2: Dual-Input System (Mobile Touch Overlay & Gamepad Autodetect)

As a player on PC or mobile,
I want native support for keyboard, Xbox/PlayStation controllers, and a floating virtual touch joystick,
So that I enjoy an equally responsive and ergonomic control experience on any device.

**Acceptance Criteria:**

**Given** game berjalan di platform PC atau Mobile,
**When** kontroler gamepad fisik dihubungkan di PC,
**Then** game mendeteksi input gamepad secara otomatis dan menyembunyikan touch UI overlay,
**And** ketika berjalan pada perangkat mobile (atau touch mode aktif), sistem menampilkan *Dynamic Floating Virtual Joystick* di sisi kiri yang muncul di lokasi sentuhan jempol, serta 6 tombol sentuh ergonomis di sisi kanan (*Normal, Dash, Skill 1, Skill 2, Parry, Ultimate*).

---

### Story 5.3: In-Game Combat HUD & Visual Status Meters

As a player,
I want a clear, retro 32-bit combat HUD displaying health bars, dynamic heat levels, ultimate gauge, and round timers,
So that I can monitor my combat resources and status at a glance without visual clutter.

**Acceptance Criteria:**

**Given** ronde pertarungan sedang berlangsung di arena,
**When** terjadi perubahan HP, Heat, atau Ultimate pada kedua karakter,
**Then** HUD memperbarui Bar HP kedua pemain secara real-time,
**And** Heat Gauge menampilkan kode warna dinamis: Hijau/Kuning (0–79% Nominal), Merah Berkedip (80–99% Overclock), dan Ungu Pudar (100% Meltdown Core Shutdown),
**And** Ultimate Meter (0–100%), Round Timer mundur 90 detik, dan indikator kemenangan ronde ditampilkan tajam pada resolusi kanvas 640x360.

---

### Story 5.4: Training Mode Suite with Real-Time Frame Inspector

As a competitive player or lab enthusiast,
I want an interactive Training Mode with visual hitbox overlays, dummy behavior toggles, and frame data inspection,
So that I can practice combos, study frame advantage, and master parry timing.

**Acceptance Criteria:**

**Given** pemain memasuki scene `Training Mode`,
**When** pemain menekan tombol F1 (atau tombol debug sentuh di mobile),
**Then** sistem menampilkan overlay kotak tumbukan berwarna (Merah = Hitbox serang, Hijau = Hurtbox, Biru = Pushbox/Ledge Sensor),
**And** On-Screen Frame Inspector menampilkan metrik frame startup, active, recovery, dan frame advantage on hit/block secara real-time,
**And** menu dummy (F2) memungkinkan konfigurasi status lawan (Stand, Crouch, Block All, Random Parry, dan Reset Posisi F3).

---

### Story 5.5: Versus AI Controller with 3 Difficulty Profiles

As a solo player,
I want to fight against an AI bot with Novice, Veteran, and Ace difficulty levels,
So that I can enjoy a satisfying single-player challenge adapted to my skill level.

**Acceptance Criteria:**

**Given** mode Versus AI dipilih dengan tingkat kesulitan (Novice, Veteran, atau Ace),
**When** pertandingan dimulai,
**Then** AI mengevaluasi jarak (*spacing*), level panas, dan input pemain:
  - *Novice*: Reaksi lambat, tidak melakukan dash udara agresif, parry jarang aktif,
  - *Veteran*: Spacing aktif, bereaksi pada window frame 12, melakukan block saat ditekan,
  - *Ace*: Membaca pola panas, melakukan Spark Parry presisi frame 6, dan memaksimalkan kombo Overclock,
**And** AI beroperasi mandiri tanpa lag atau frame drop pada loop 60 FPS.

---

### Story 5.6: Local 2-Player Versus Mode & Configuration Persistence

As two local players on PC,
I want to connect two separate controllers and compete head-to-head with saved player preferences,
So that we can play offline versus matches with our preferred volume and control bindings.

**Acceptance Criteria:**

**Given** dua controller gamepad tersambung pada PC di menu Local Versus,
**When** kedua pemain memilih karakter dan memulai pertandingan,
**Then** Player 1 dan Player 2 mengendalikan karakter masing-masing secara independen tanpa konflik input,
**And** pengaturan volume audio dan kustomisasi tombol disimpan secara lokal menggunakan `ConfigFile` pada `user://settings.cfg` dan dimuat otomatis saat peluncuran ulang.

---

## Epic 6: Audio-Visual Juice, Combat Feedback & Performance Polish

Menyempurnakan kenikmatan benturan baja (*game feel*) melalui sistem hitstop lokal, guncangan layar (*screen shake*), partikel las percikan api, announcer retro 90-an, konfigurasi bus audio, dan optimasi performa 60 FPS terkunci.

### Story 6.1: Local Frame-Hitstop & Dynamic Screen Shake

As a player landing a heavy punch or parrying an attack,
I want a momentary freeze frame (hitstop) and screen shake on impact,
So that every strike feels visceral, heavy, and satisfying.

**Acceptance Criteria:**

**Given** terjadi kontak serangan berhasil atau Spark Parry sukses,
**When** sinyal `hitstop_requested` dipancarkan via `EventBus`,
**Then** `HitstopComponent` membekukan siklus frame logika karakter yang terlibat (misal: 12 frame pada parry sukses) tanpa membekukan thread engine atau rendering partikel background,
**And** kamera arena menghasilkan getaran dinamis (*screen shake*) dengan intensitas proporsional terhadap kekuatan pukulan.

---

### Story 6.2: 32-Bit Pixel VFX & Welding Spark Particles

As a player engaged in intense mecha combat,
I want dynamic sparks, glowing energy slashes, and steam venting during high heat,
So that the combat is visually spectacular in authentic 90s neo-retro 32-bit aesthetics.

**Acceptance Criteria:**

**Given** pertempuran berlangsung di platform arena,
**When** mecha saling beradu pukulan, menangkis serangan, atau memasuki panas tinggi,
**Then** sistem partikel `GPUParticles2D` memancarkan percikan api las (*welding sparks*) oranye-kuning saat benturan logam,
**And** tebasan laser menghasilkan jejak neon biru/magenta berpendar tajam pada resolusi pixel 640x360,
**And** saat mecha berada di zona Overclock (80–99%), efek distorsi uap panas memancar dari ventilasi mecha.

---

### Story 6.3: Arcade Announcer, Sound Effects & Audio Server Bus Setup

As a player,
I want heavy metal clang sound effects, hydraulic hisses, and a retro arcade announcer voice over dedicated audio buses,
So that the game audio is immersive, punchy, and customizable.

**Acceptance Criteria:**

**Given** konfigurasi AudioServer dengan 5 bus audio (`Master`, `BGM`, `SFX`, `Announcer`, `MechaVoice`),
**When** peristiwa game terjadi (Round Start, Critical Heat, K.O., Spark Parry, Hydraulic Grab),
**Then** efek suara SFX logam berat dan desisan hidrolik diputar dengan kejernihan stereo 44.1 kHz,
**And** voice clip Announcer arcade retro 90-an ("ROUND 1... ENGAGE!", "CRITICAL HEAT DETECTED", "CORE BREAK!") diputar lantang di bus `Announcer` tanpa menenggelamkan SFX pertempuran,
**And** volume tiap bus dapat diatur secara independen dari menu Settings.

---

### Story 6.4: Performance Profiling, Memory Audit & 60 FPS Lock

As a player on target PC or mobile devices,
I want a locked 60 FPS experience with zero crashes and memory usage under 600 MB,
So that gameplay is fluid, tournament-ready, and never stutters.

**Acceptance Criteria:**

**Given** game dijalankan pada Compatibility Renderer (OpenGL ES 3.0) di PC dan perangkat Android target,
**When** 100 ronde pertempuran otomatis dijalankan secara berkelanjutan (automated stress test),
**Then** frame rate rata-rata terkunci pada 60 FPS stabil dengan frame drop < 0.5%,
**And** konsumsi RAM tidak melebihi batas 600 MB RAM,
**And** sistem mempertahankan 0 crash sepanjang pengujian dan lulus eksekusi test headless `godot --headless --script test/run_tests.gd`.

