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

### Epic 7: 32-Bit Pixel Character Sprites & Animation Integration
Menggantikan placeholder visual kotak primitif dengan sprite mecha pixel art beresolusi 32-bit yang kaya detail dan sistem visual state animation dinamis (Idle, Walk, Jump, Dash, Attack, Hitstun, Cliffhanger), siluet mecha khas untuk Apex-0 Viper dan Titan-V Bulwark, serta resolusi technical debt arsitektur.
**Requirements covered:** NFR7, UX-DR5, FR10, FR11

### Epic 8: Cyberpunk OST & Mecha Combat Audio Immersion
Menghadirkan pengalaman audio arcade 90-an yang imersif dan bertenaga penuh melalui dynamic synthwave background music engine (Title BGM & Skyscraper Battle BGM), ekspansi sound effects aksi mecha autentik (thruster dash, heat warning siren, meltdown shutdown, varied impact sounds), serta voice announcer arcade terpadu.
**Requirements covered:** UX-DR6, NFR5, NFR6

### Epic 9: Standalone Build & Export Pipeline
Menyiapkan profil ekspor Godot 4, konfigurasi preset Windows Desktop, pengemasan paket game biner terenkapsulasi (`FightingToZero.exe` & `FightingToZero.pck`), serta verifikasi rilis standalone siap distribusi.
**Requirements covered:** NFR3, NFR5, NFR6

### Epic 10: Playable 3rd Mecha Roster - Ray-X "Pulsar" (Zoner / Beam & Drone Disrupter)
Mewujudkan petarung mecha ke-3 berorientasi penyerangan jarak jauh (Zoner / Trapper) dengan senjata laser foton, drone melayang penutup area, dan gelombang kejut Supernova Horizon 360°.
**Requirements covered:** FR10, FR11, NFR7, UX-DR5

### Epic 11: Character Select Screen & Roster Selection System
Menyediakan antarmuka pemilihan karakter (Character Select) arcade retro 32-bit dengan preview sprite bergerak dinamis, inspeksi move list & statistik, konfigurasi pemain (P1 vs AI / Local 2P), dan factory spawner otomatis.
**Requirements covered:** FR10, FR11, FR16, FR18, UX-DR3

### Epic 12: Underground Reactor Arena & Environmental Steam Hazards
Menghadirkan panggung arena ke-2 berlatar reaktor bawah tanah industri tertutup dengan dinding pembatas fisik pantul (Wall Bounce), sistem bahaya semburan uap termal bertekanan tinggi (Steam Hazards), serta pemilihan panggung dinamis di antarmuka pra-pertandingan.
**Requirements covered:** FR12, FR9, UX-DR5, NFR7

### Epic 13: Playable 4th Mecha Roster - Phantom-9 "Kage" (Stance Switcher / Stealth Ninja Mecha)
Mewujudkan petarung mecha ke-4 bertipe Stance Switcher ninja bertema bayangan dan katana ganda dengan mekanik pergantian kuda-kuda (Kenjutsu vs Shinobi), tebasan kilat Iaido, hujan shuriken, dan jurus pamungkas Tsukuyomi Shadow Blossom.
**Requirements covered:** FR10, FR11, NFR7, UX-DR5

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

---

## Epic 7: 32-Bit Pixel Character Sprites & Animation Integration

Menggantikan placeholder visual kotak primitif dengan sprite mecha pixel art beresolusi 32-bit yang kaya detail dan sistem visual state animation dinamis (Idle, Walk, Jump, Dash, Attack, Hitstun, Cliffhanger), siluet mecha khas untuk Apex-0 Viper dan Titan-V Bulwark, serta resolusi technical debt arsitektur.

### Story 7.1: 32-Bit Pixel Mecha Sprites, State Visuals & Architecture Hardening

As a player,
I want distinct, highly recognizable 32-bit pixel art mecha visuals and fluid state animations for Apex-0 Viper and Titan-V Bulwark instead of placeholder colored blocks,
So that the combat feels authentic, visually punchy, readable, and true to the 90s arcade aesthetic.

**Acceptance Criteria:**

**Given** karakter Apex-0 Viper dan Titan-V Bulwark aktif di arena pertarungan,
**When** karakter bertransisi antar status FSM (Idle, Walk, Jump, Fall, Dash, Attack, Hitstun, Cliffhanger, Meltdown),
**Then** node visual karakter menampilkan sprite mecha pixel art beresolusi 32-bit dengan siluet khas:
  - Apex-0 Viper: Desain ramping aerodinamis warna cyan-neon dengan rapier beam dan thruster biru,
  - Titan-V Bulwark: Desain bodi baja berat warna oranye-industrial dengan piston hidrolik dan shoulder armor tebal,
**And** animasi mikro (bobbing idle, flame thruster saat dash/jump, flash hitstun, dan pose satu tangan cliffhanger) terikat mulus dengan siklus frame FSM,
**And** dimensi bounding box kolisi (24x38 px) dan semua layer Area2D tetap terjaga tanpa mengubah parameter hitbox/hurtbox yang sudah seimbang,
**And** menyelesaikan technical debt yang tertunda: unifikasi `CombatConstants.MAX_HEAT` dan aturan `.gitignore` untuk hasil tes otomatis.

---

### Story 7.2: Dash Afterimage Trails, K.O. Core Rupture & Dynamic Stage Background

As a player executing high-speed maneuvers or landing a decisive final blow,
I want dynamic dash silhouette after-image trails, a cinematic K.O. core rupture explosion, and a living 90s cyber-city background with glowing neon windows and passing hover vehicles,
So that every movement feels blindingly fast, victories feel momentous, and the zero-g skyscraper battlefield feels immersive.

**Acceptance Criteria:**

**Given** pertempuran mecha berlangsung di arena `arena_skyscraper.tscn`,
**When** mecha mengeksekusi *Vector Dash* darat atau *Air Dash*,
**Then** sistem `DashGhostTrail` menghasilkan jejak siluet bayangan bergradasi warna neon khas (cyan untuk Viper, oranye untuk Bulwark) yang memudar selama 8–12 frame,
**When** mecha tereliminasi oleh K.O. (HP 0),
**Then** sistem memicu sekuens dramatis *Core Rupture*: partikel percikan las bertegangan tinggi, flash layar lokal, dan efek fragmentasi ledakan reaktor mecha dengan freeze 18 frame sebelum sekuens kemenangan ronde,
**And** latar belakang `arena_skyscraper.tscn` diperkaya dengan elemen cyber-city 90-an dinamis: jendela gedung bertingkat yang berpendar lembut, lampu kabut kota New Babel-01, dan kendaraan hovercraft melintas sesekali di kejauhan secara deterministik 60 FPS tanpa beban memori berlebih.

---

## Epic 8: Cyberpunk OST & Mecha Combat Audio Immersion

Menghadirkan pengalaman audio arcade 90-an yang imersif dan bertenaga penuh melalui dynamic synthwave background music engine (Title BGM & Skyscraper Battle BGM), ekspansi sound effects aksi mecha autentik (thruster dash, heat warning siren, meltdown shutdown, varied impact sounds), serta voice announcer arcade terpadu.

### Story 8.1: Cyberpunk Synthwave OST System (Menu & Arena BGM)

As a player navigating menus or engaging in intense mecha combat,
I want dynamic, looped 90s cyberpunk synthwave background music playing through the BGM audio bus with smooth transitions,
So that every battle feels energetic, stylish, and retro-arcade authentic.

**Acceptance Criteria:**

**Given** AudioManager mengelola bus `BGM` di AudioServer,
**When** pemain berada di Main Menu atau memasuki arena Skyscraper,
**Then** AudioManager memutar BGM bertema arcade synthwave 90-an yang di-loop mulus (Title Theme: tempo santai 105 BPM; Arena Theme: tempo energetik 128 BPM),
**And** transisi musik dari Menu ke Arena berlangsung dengan crossfade halus tanpa audio popping atau glitch,
**And** volume BGM dapat diatur dan di-mute secara independen dari menu Settings dan tersimpan di `user://settings.cfg`.

---

### Story 8.2: Authentic Mecha Combat SFX Expansion & Dynamic Sound Feedback

As a player performing dashes, managing heat, or landing hits,
I want distinct mechanical sound effects for thruster dashes, heat alarms, meltdown shutoff, and heavy impact varieties,
So that I receive clear, visceral audio cues for every combat state and action.

**Acceptance Criteria:**

**Given** pertempuran mecha sedang berlangsung di arena,
**When** mecha mengeksekusi Vector Dash darat/udara,
**Then** AudioManager memutar efek suara desisan jet thruster mecha bertekanan tinggi di bus `SFX`,
**When** panas reaktor mencapai zona Overclock (80–99%) atau Emergency Meltdown (100%),
**Then** sistem membunyikan sinyal peringatan termal (Overclock pulsing alarm) atau sirine mati daya darurat (Meltdown shutdown power-down),
**When** serangan mendarat pada lawan,
**Then** efek suara impact bervariasi secara dinamis (Light Hit vs Heavy Impact vs Wall/Ledge Bounce),
**And** seluruh SFX diproses melalui pooling suara tanpa kebocoran memori pada loop 60 FPS deterministik.

---

## Epic 9: Standalone Build & Export Pipeline

Menyiapkan profil ekspor Godot 4, konfigurasi preset Windows Desktop, pengemasan paket game biner terenkapsulasi (`FightingToZero.exe` & `FightingToZero.pck`), serta verifikasi rilis standalone siap distribusi.

### Story 9.1: Standalone Windows Release Package & Presets

As a player or distributor,
I want a standalone Windows executable (`FightingToZero.exe`) and package (`FightingToZero.pck`) that runs independently without opening the Godot Editor,
So that anyone can easily install and play the full game on PC.

**Acceptance Criteria:**

**Given** proyek Godot 4 telah terkonfigurasi dengan `export_presets.cfg`,
**When** proses ekspor dijalankan melalui Godot CLI (`--export-pack "Windows Desktop" builds/windows/FightingToZero.pck`),
**Then** berkas biner `.pck` tergenerasi sempurna dengan seluruh resource, scene, skrip, dan shader terkompilasi,
**And** paket binary mandiri `builds/windows/FightingToZero.exe` dapat dieksekusi secara instan dan memuat `FightingToZero.pck` dengan performa terkunci 60 FPS,
**And** disediakan script peluncur batch `run_standalone_build.bat` di root direktori untuk kemudahan testing.

---

## Epic 10: Playable 3rd Mecha Roster - Ray-X "Pulsar" (Zoner / Beam & Drone Disrupter)

Mewujudkan petarung mecha ke-3 berorientasi penyerangan jarak jauh (Zoner / Trapper) dengan senjata laser foton, drone melayang penutup area, dan gelombang kejut Supernova Horizon 360°.

### Story 10.1: Ray-X "Pulsar" Zoner Character Implementation

As a player who prefers long-range zoning, spatial traps, and beam artillery,
I want to play as Ray-X Pulsar with photon railguns, floating disrupter drone pods, and the 360-degree Supernova shockwave,
So that I can control arena space, deny aggressive rushes, and control the edge from a safe distance.

**Acceptance Criteria:**

**Given** karakter Ray-X Pulsar dipilih dengan Max HP 950, kecepatan jalan 300 px/s, dan dash 720 px/s (14 frame),
**When** pemain mengeksekusi jurus khas Pulsar:
  - Normal String: 2-hit Plasma Pulse (Light Plasma Burst 5f startup, Long-reach Beam Lance 10f),
  - Skill 1 (*Photon Railgun*): Tembakan laser partikel linear cepat menembus proyektil biasa (Startup 12f, damage 110, +25% Heat),
  - Skill 2 (*Disrupter Drone Pod*): Melepaskan drone tempur melayang yang mengunci posisi spasial di platform (+20% Heat),
  - Ultimate (*Supernova Horizon*): Gelombang kejut partikel foton 360 derajat di sekeliling Pulsar (Startup 18f, damage 380, invulnerable startup frame),
**Then** seluruh jurus berfungsi sesuai parameter Resource `.tres` dan kalkulasi damage scaling terpadu,
**And** visual mecha pixel art mecha menampilkan siluet warna violet neon (#A64DFF) dengan visor kuning foton (#FFE633) dan thruster plasma ungu.

---

## Epic 11: Character Select Screen & Roster Selection System

Menyediakan antarmuka pemilihan karakter (Character Select) arcade retro 32-bit dengan preview sprite bergerak dinamis, inspeksi move list & statistik, konfigurasi pemain (P1 vs AI / Local 2P), dan factory spawner otomatis.

### Story 11.1: Character Select Screen & Roster Selection System

As a player starting a duel in Versus AI or Local 2P mode,
I want to select my preferred mecha from the 3-fighter roster (Apex-0 Viper, Titan-V Bulwark, Ray-X Pulsar), inspect their stats, and see live animated pixel sprite previews,
So that I can customize each combat match with contrasting combat playstyles before entering the arena.

**Acceptance Criteria:**

**Given** pemain memilih mode Versus AI atau Local 2-Player dari Main Menu,
**When** scene `scenes/character_select.tscn` dimuat,
**Then** sistem menampilkan 3 kartu roster mecha (Apex-0 Viper, Titan-V Bulwark, Ray-X Pulsar) dengan estetika cyberpunk 32-bit resolusi 640x360,
**And** navigasi kursor (WASD/Gamepad) berpindah antar karakter secara mulus dan menampilkan preview sprite bergerak (*live animated pixel preview*) dari `MechaPixelSprite`,
**And** panel samping menampilkan statistik lengkap (HP, Kecepatan Jalan, Kecepatan Dash, Rating Speed/Defense/Range, dan deskripsi jurus khas),
**And** saat P1 dan P2 (atau P1 dan AI) mengunci pilihan (Lock-In), `MatchConfig` menyimpan konfigurasi pertandingan dan secara otomatis menginstansiasi mecha terpilih di arena via `FighterFactory`.

---

## Epic 12: Underground Reactor Arena & Environmental Steam Hazards

Menghadirkan panggung arena ke-2 berlatar reaktor bawah tanah industri tertutup dengan dinding pembatas fisik pantul (Wall Bounce), sistem bahaya semburan uap termal bertekanan tinggi (Steam Hazards), serta pemilihan panggung dinamis di antarmuka pra-pertandingan.

### Story 12.1: Underground Reactor Stage with Boundary Walls & Steam Hazards

As a player competing in Versus AI, Local 2P, or Training mode,
I want to battle in the Underground Reactor stage featuring enclosed boundary walls that bounce knocked-back fighters and active steam vents that periodically erupt with heat hazards,
So that I can experience tactical corner pressure, wall-bounce combos, and environmental risk management distinct from the open skyscraper arena.

**Acceptance Criteria:**

**Given** scene arena `scenes/arena_underground_reactor.tscn` dimuat,
**When** pertarungan berlangsung di dalam reaktor,
**Then** arena dibatasi oleh dinding fisik baja tertutup di batas kiri (X = 64) dan batas kanan (X = 1344) pada Layer 1 World Collision (tanpa open cliff/cliffhanger),
**And** karakter yang terhempas keras ke dinding memicu reaksi pantulan *Wall-Bounce* dengan pembatasan 1x per rangkaian kombo (FR9),
**And** panggung dilengkapi dua ventilasi uap geotermal reaktor (`scripts/hazards/steam_vent_hazard.gd`) yang mengalami siklus peringatan (Indikator Lampu Merah/Desis 3 detik) dan erupsi semburan uap (durasi 1.5 detik) yang meningkatkan Heat mecha sebesar +20% serta memberikan chip damage ringan jika tersentuh,
**And** `MatchConfig` dan Character Select Screen mendukung seleksi arena (`&"skyscraper"` vs `&"reactor"`), dan mengalihkan transisi scene gameplay ke arena terpilih secara mulus.

---

## Epic 13: Playable 4th Mecha Roster - Phantom-9 "Kage" (Stance Switcher / Stealth Ninja Mecha)

Mewujudkan petarung mecha ke-4 bertipe Stance Switcher ninja bertema bayangan dan katana ganda dengan mekanik pergantian kuda-kuda (Kenjutsu vs Shinobi), tebasan kilat Iaido, hujan shuriken, dan jurus pamungkas Tsukuyomi Shadow Blossom.

### Story 13.1: Phantom-9 "Kage" Character Implementation & Stance Shift Mechanics

As a player who enjoys agile dual-style hybrid fighters and mind-game mixups,
I want to play as Phantom-9 Kage with dynamic Stance Switching between close-range Kenjutsu Katana and ranged Shinobi Shurikens,
So that I can confuse opponents with evasive feints and fluidly adapt my combat range in mid-battle.

**Acceptance Criteria:**

**Given** karakter Phantom-9 Kage dipilih dengan Max HP 920, kecepatan jalan 320 px/s, dan dash 780 px/s (14 frame),
**When** pemain mengeksekusi aksi unik Phantom-9:
  - **Skill 1 (*Stance Shift & Shadow Feint*)**: Bertransisi seketika antara `&"kenjutsu"` (Katana Melee) dan `&"shinobi"` (Shuriken Ranged) dengan 12 frame evasive feint dan +15% Heat,
  - **Normal String (Kenjutsu)**: 5L (Katana Quick Draw 4f startup, 60 damage) dan 5H (Spinning Overhead Cleave 8f startup, 90 damage),
  - **Normal String (Shinobi)**: 5L (Kunai Poke 5f startup, 50 damage) dan 5H (Kunai Flurry 9f startup, 85 damage),
  - **Skill 2 (Kenjutsu - *Iaido Crescent*)**: Tebasan lunge berkecepatan tinggi menembus garis depan (Startup 10f, damage 120, +25% Heat),
  - **Skill 2 (Shinobi - *Shuriken Storm*)**: Melepaskan 3 shuriken bayangan menyebar (Startup 12f, damage 35x3, +20% Heat),
  - **Ultimate (*Tsukuyomi Shadow Blossom*)**: Sekuens tebasan bayangan 5-hit sinematik ke seluruh penjuru layar (Startup 16f, damage 420, invulnerability startup frames),
**Then** seluruh jurus berfungsi sesuai parameter Resource `.tres` dan kalkulasi damage scaling terpadu,
**And** visual mecha pixel art mecha menampilkan siluet warna crimson red (#F22640) dengan chassis midnight black (#0F141A), syal ninja berpendar (#E61F38), dan afterimage dash jejak merah delima gelap.

