---
title: "Game Design Document: Fighting to Zero"
game_type: fighting
platforms:
  - PC (Steam / itch.io)
  - Mobile (Android / iOS)
created: '2026-10-16'
updated: '2026-10-16'
---

# Fighting to Zero - Game Design Document

**Penulis:** User  
**Tipe Game:** Fighting (2D Mecha Arcade Duelist)  
**Target Platform:** PC (Windows/Linux) & Mobile (Android/iOS)  
**Target Engine:** Godot Engine 4  

---

## 1. Executive Summary

### 1.1 Core Concept
**Fighting to Zero** adalah game fighting 2D 1v1 duel mecha bertempo tinggi yang memadukan estetika retro *32-bit pixel art* era 90-an dengan responsivitas pertarungan modern. Pemain mengendalikan mecha tempur di atas platform pencakar langit tanpa dinding pembatas, berfokus pada mobilitas dorongan jet 8-arah, manajemen risiko panas (*Overheat*), ketepatan tangkisan baja (*Spark Parry*), serta perebutan dramatis di tubir jurang (*Cliffhanger Ring-Out*).

Game ini mendobrak batasan aksesibilitas genre pertarungan konvensional melalui **Sistem 3-Skill Hero Terpadu** (*Normal, Skill 1, Skill 2, Ultimate, Parry*) yang meniadakan input kombo putaran stik rumit (*motion inputs/quarter-circles*), sehingga memberikan kenyamanan dan keadilan kontrol yang setara antara layar sentuh mobile dan gamepad/keyboard PC.

### 1.2 Target Audience
- **Audiens Primer (16–35 tahun)**: Penggemar game fighting kompetitif dan platform fighter yang mendambakan adu refleks, *spacing*, dan pembacaan taktik (*mind games*) murni tanpa hambatan menghafal input kombo panjang.
- **Komunitas Mecha Retro**: Gamer bernostalgia era PS1/Arcade 90-an (*Zero Divide, Cyberbots, Virtual-On, Armored Core*) yang merindukan suara hantaman baja berat, percikan api, dan desain robot fungsional berbobot.
- **Audiens Sekunder**: Gamer mobile pencari game aksi cepat berkualitas konsol dengan sesi pertandingan berdurasi 2–3 menit.

### 1.3 Unique Selling Points (USPs)
1. **Unified 3-Skill Control**: Kontrol presisi berbasis tombol tunggal yang adil antara kontrol sentuh layar mobile dan controller fisik PC.
2. **Thermal Risk-Reward Engine**: Sistem manajemen suhu dinamis menggantikan mana/stamina klise. Memaksa pemain bertarung di zona merah bahaya (80–99%) untuk bonus *Super Armor* dan damage, dengan risiko *Overheat Meltdown* (lumpuh total) jika menyentuh 100%.
3. **Clutch Cliffhanger & Edge Tension**: Terlempar keluar platform arena memicu fase gantung tebing 2 detik yang menegangkan untuk adu panjat balik atau injakan maut (*Ring Out*).
4. **Neo-Retro 32-Bit Aesthetics**: Tampilan visual sprite mecha beresolusi tinggi dengan siluet tegas, efek partikel las percikan api dinamis, dan efek *hitstop* yang memberikan kepuasan benturan logam nyata.

---

## 2. Goals and Context

### 2.1 Project Goals
- **Membuktikan Gameplay Feel Inti**: Menghadirkan *vertical slice* pertarungan mecha 2D yang terasa responsif, berdampak berat, dan kompetitif dengan performa 60 FPS stabil.
- **Membuktikan Arsitektur Kontrol Lintas Platform**: Memastikan skema kontrol layar sentuh di mobile memiliki daya saing dan kenikmatan setara dengan gamepad analog di PC.
- **Skalabilitas Produksi Solo Developer**: Mengadopsi lingkup terukur (MVP: 2 Karakter, 1 Arena, Versus AI, dan Training Mode) yang dapat diselesaikan dan dipoles secara optimal sebelum ekspansi roster berikutnya.

### 2.2 Background and Rationale
Banyak game fighting di platform mobile gagal mempertahankan audiens karena memaksakan joystick virtual konvensional yang tidak ramah sentuhan, atau terdegradasi menjadi game RPG auto-play berbasis gacha. Di sisi lain, game fighting PC sering kali memiliki kurva belajar input (*execution barrier*) yang mengintimidasi pemain kasual. *Fighting to Zero* menjembatani kedua ruang tersebut dengan menyederhanakan eksekusi input, sembari memindahkan seluruh kedalaman kompetitif ke pembacaan timing, manajemen suhu, dan penguasaan jarak (*footsies*).

---

## 3. Core Gameplay

### 3.1 Game Pillars
1. **Readable High-Mobility (Manuver 8-Arah Terbaca)**  
   Kebebasan dorongan jet instan ke 8 penjuru di darat maupun udara, memberikan kelincahan layaknya mecha anime, dengan siluet dan *startup animation* yang tetap terbaca jelas untuk diantisipasi lawan.
2. **Thermal Risk-Reward (Overheat vs Super Armor)**  
   Manajemen sumber daya terpusat pada suhu internal mecha. Semakin agresif mecha menyerang dan beralih manuver, semakin tinggi panas yang dihasilkan. Bermain di batas bahaya memberikan kekuatan luar biasa, namun kecerobohan berbuah kelumpuhan fatal.
3. **Clutch Cliffhanger & Ring Tension**  
   Arena pertarungan tidak memiliki dinding pengaman. Menjaga posisi tengah arena adalah prioritas; terlempar ke pinggir arena memicu fase perebutan tepi tebing (*Cliffhanger*) yang membalikkan momentum atau mengakhiri ronde seketika.
4. **Accessible Inputs, High Skill Ceiling**  
   Seluruh kapabilitas petarung diakses melalui tombol tunggal langsung. Keahlian ditentukan oleh reaksi terhadap frame lawan, jebakan *feint*, dan manajemen ruang, bukan kecepatan jari menekan kombinasi tombol.

### 3.2 Core Gameplay Loop
Siklus aksi permainan berlangsung dalam tempo intens berulang:
1. **Neutral & Spacing**: Pemain bermanuver memanfaatkan *8-Way Thruster Vector Dash* untuk mencari celah masuk dan menjaga posisi dari tepi arena.
2. **Engage & Heat Trade**: Melakukan rantai serangan dasar, mengorbankan kenaikan suhu untuk meluncurkan Skill 1 atau Skill 2.
3. **Defense & Counter-Play**: Memprediksi serangan musuh untuk mengeksekusi *Spark Parry* presisi frame demi menguras meteran lawan dan memulihkan suhu panas mecha sendiri.
4. **Overclock & Execution**: Menembus batas panas ke zona *Overclock* (80–99%) guna memanfaatkan *Super Armor*, melepaskan *Ultimate Attack*, atau meluncurkan serangan penghempas yang mendorong lawan ke tubir jurang tebing platform.

### 3.3 Win/Loss Conditions
- **Format Pertandingan**: *Best of 3 Rounds* (Ronde 90 detik).
- **Kondisi Menang**:
  1. *HP Depletion*: Mengurangi Health Point (HP) mecha lawan hingga 0.
  2. *Ring Out Execution*: Menginjak (*Ledge Stomp*) atau menghempaskan lawan yang gagal naik dari fase *Cliffhanger*.
  3. *Time Out*: Karakter dengan sisa persentase HP lebih tinggi saat waktu habis dinyatakan menang.
- **Kondisi Seri (Draw)**: Double K.O. atau HP identik saat time out memicu babak sudden death 30 detik dengan kedua mecha berada pada kondisi 90% Heat.

---

## 4. Game Mechanics

### 4.1 Primary Mechanics & Systems
1. **Sistem Panas (Heat Gauge Engine)**:
   - Rentang Bar: 0% – 100%.
   - **Tingkat Pendinginan Pasif**: -12% per detik saat karakter dalam kondisi Idle atau Walking (tidak menyerang / tidak melakukan dash).
   - **Zona Nominal (0% – 79%)**: Mecha beroperasi normal.
   - **Zona Overclock (80% – 99%)**: Serangan Skill menghasilkan +20% damage tambahan dan memperoleh status *1-Hit Super Armor* pada frame awal serangan (fase startup).
   - **Zona Emergency Meltdown (100%)**: Mecha mengalami mati daya mendadak (*Core Shutdown*) selama 90 frame (1.5 detik), tidak dapat bergerak atau bertahan, dan menerima damage tambahan +25% dari segala serangan. Setelah durasi selesai, suhu direset kembali ke 0%.
2. **Sistem Tangkisan Presisi (Spark Parry)**:
   - Durasi aktif: 4 frame (frame 2–5 setelah tombol ditekan).
   - Biaya Whiff (gagal menangkis): Karakter terkunci dalam animasi pemulihan selama 14 frame (berstatus rentan *Counter-Hit*).
   - Hadiah Berhasil: Pembatalan instan dari segala stagger/blockstun, membuat penyerang membeku (*hitstop*) selama 12 frame, menyerap 15% dari bar Ultimate lawan, dan membuang 20% panas mecha secara instan.
3. **Mekanik Perebutan Tebing (Cliffhanger Struggle)**:
   - Syarat Trigger: Mecha terhempas ke luar batas platform kiri/kanan dan masih memiliki HP > 0. Mecha secara otomatis meraih bibir tebing dengan satu tangan (maksimal 1 kali aktivasi per ronde).
   - Batas Waktu Gantung: 120 frame (2.0 detik).
   - Opsi Pemain Bergelantungan:
     - **Climb-Up Jump** (Tombol Lompat/Atas): Melompat kembali ke platform (Startup 18 frame, rentan terhadap serangan anti-air).
     - **Ledge Sweep Attack** (Tombol Serang): Menebas kaki lawan di bibir tebing (Startup 12 frame, damage 10%, -2 on block).
     - **Drop Fall** (Tombol Bawah): Menyerah dan melepaskan pegangan (memicu instan Ring Out).
   - Opsi Pemain di Atas Platform:
     - **Ledge Stomp** (Tombol Bawah + Serang): Serangan injakan ke bibir tebing (Startup 15 frame, jika mengenai lawan yang bergelantungan akan memicu instan Ring-Out).

### 4.2 Controls and Input Architecture
- **Input Buffer Window**: 5 frame (83.3 ms pada 60 FPS) untuk mempermudah transisi aksi pada layar sentuh tanpa mengorbankan ketajaman kontrol PC.
- **Coyote Time**: 5 frame (memungkinkan eksekusi lompatan/dash sesaat setelah mecha melangkah keluar tepi lantai).
- **Pemetaan Tombol Terpadu**:

| Aksi | Fungsi Gameplay | Kontrol PC (Keyboard / Gamepad) | Kontrol Mobile (Virtual Touch) |
| :--- | :--- | :--- | :--- |
| **Arah / Vektor** | Bergerak / Mengarahkan Dash 8-Arah | WASD / D-Pad / Analog Kiri | Dynamic Floating Virtual Joystick |
| **Normal Attack** | Pukulan dasar / Rantai kombo ringan | Tombol J / Tombol X (Xbox) | Tombol Sentuh "ATK" |
| **Vector Dash** | Dorongan jet 8-arah (darat/udara) | Tombol L / Tombol B (Xbox) | Tombol Sentuh "DASH" |
| **Skill 1** | Skill ofensif khas mecha | Tombol U / Tombol Y (Xbox) | Tombol Sentuh "SKILL 1" |
| **Skill 2** | Skill utilitas / pertahanan | Tombol I / Tombol RB (Xbox) | Tombol Sentuh "SKILL 2" |
| **Spark Parry** | Tangkisan presisi frame | Tombol K / Tombol A (Xbox) | Tombol Sentuh "PARRY" |
| **Ultimate** | Jurus pamungkas (butuh bar 100%) | Tombol O / Tombol RT (Xbox) | Tombol Sentuh "ULTIMATE" |
| **Block** | Menahan mundur dari lawan | Tahan tombol Arah Belakang | Tahan Arah Mundur pada Joystick |

---

## 5. Fighting Game Specific Design

### 5.1 Character Roster (Spesifikasi MVP)

#### Karakter 1: Apex-0 "Viper"
- **Archetype**: High-Speed Rushdown / Aerial Assassin.
- **Total HP**: 900 HP (Pertahanan lebih tipis, mobilitas tinggi).
- **Kecepatan Gerak**: Jalan 350 px/s, Dash 820 px/s (12 frame).
- **Karakteristik Kit**:
  - *Normal String*: 3-Hit Rapier Beam Combo (Light Jab 3f startup, Beam Thrust 6f, Overhead Cleave 11f).
  - *Skill 1 - Blink Slash*: Teleportasi instan menembus garis musuh sejauh 400 px dan menebas dari belakang (Startup 10f, +25% Heat).
  - *Skill 2 - Deflection Matrix*: Memasang jaring laser selama 30 frame yang memantulkan proyektil dan memperlambat musuh (+20% Heat).
  - *Ultimate - Absolute Zero Protocol*: Membuka katup kriogenik selama 8 detik. Panas terkunci pada 0%, kecepatan dash meningkat +30%, dan dash udara tidak terbatas.

#### Karakter 2: Titan-V "Bulwark"
- **Archetype**: Heavy Grappler / Zone Controller.
- **Total HP**: 1200 HP (Lapis baja tebal, reduksi pasif damage masuk sebesar 5%).
- **Kecepatan Gerak**: Jalan 260 px/s, Dash 650 px/s (16 frame).
- **Karakteristik Kit**:
  - *Normal String*: 2-Hit Heavy Impact (Hydraulic Punch 7f startup, Ground Slam 14f dengan efek wall bounce).
  - *Skill 1 - Hydraulic Piledriver*: Command grab jarak dekat (Startup 6f, mengabaikan block biasa, membanting musuh dengan 220 damage, +35% Heat).
  - *Skill 2 - Riot Shield Deploy*: Menancapkan perisai baja ke lantai. Memberikan status *Full Super Armor* selama 45 frame terhadap serangan non-grab (+15% Heat).
  - *Ultimate - Orbital Siege Cannon*: Menembakkan meriam laser partikel vertikal-diagonal layar penuh berdamage 450 HP (Startup 24f).

### 5.2 Move Lists and Frame Data Standards
Game ini berjalan pada basis **60 frame per detik (FPS)**. Standar data frame diterapkan sebagai berikut:

| Kategori Serangan | Startup Frame | Active Frame | Recovery Frame | On-Block Advantage | On-Hit Advantage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Light Normal (Viper)** | 3 frame | 2 frame | 6 frame | +1 frame (Aman) | +4 frame (Link ke Normal 2) |
| **Heavy Normal (Bulwark)** | 7 frame | 3 frame | 14 frame | -4 frame (Aman dari grab) | +6 frame (Knockdown ringan) |
| **Blink Slash (Skill 1)** | 10 frame | 4 frame | 18 frame | -8 frame (Dapat dihukum) | +12 frame (Hard Knockdown) |
| **Hydraulic Grab (Skill 1)** | 6 frame | 2 frame | 22 frame | Tak dapat diblock | +25 frame (Melemparkan musuh) |
| **Spark Parry** | 1 frame | 4 frame | 14 frame | +12 frame freeze | +12 frame freeze (Inisiatif balik) |
| **Ledge Stomp** | 15 frame | 4 frame | 20 frame | -10 frame | Instan Ring-Out pada tebing |

### 5.3 Combo System & Scaling
- **Struktur Kombo**: Menggunakan sistem *Target Chain Cancel* (Normal 1 → Normal 2 → Skill) dan *Juggle Link* terbatas di udara.
- **Damage Scaling**:
  - Hit ke-1: 100% damage.
  - Hit ke-2: 85% damage.
  - Hit ke-3: 70% damage.
  - Hit ke-4 dan seterusnya: Berkurang 10% per hit dengan batas minimum *damage floor* sebesar 25%.
- **Bounce System**: Maksimal 1 kali *Ground Bounce* dan 1 kali *Wall/Edge Bounce* dalam satu rangkaian kombo untuk mencegah kombo tak terbatas (*infinite loops*).

### 5.4 Defensive Mechanics
- **Normal Blocking**: Menahan tombol arah berlawanan dari posisi musuh. Mengurangi 100% damage serangan fisik biasa, dan menerima 20% *chip damage* terhadap serangan skill berbasis energi.
- **Invincibility Frames (I-Frames)**: 
  - Bangkit dari lantai (*Wake-up*): 6 frame invulnerable.
  - Spark Parry sukses: 12 frame invulnerable selama animasi penangkisan.
  - Dash darat frame 1–3 berstatus anti-throw, namun tetap rentan terhadap serangan fisik.

### 5.5 Stage Design: Zero-G Skyscraper Platform
- **Dimensi**: Platform baja selebar 1280 piksel dengan tinggi permukaan 60 piksel dari batas bawah layar.
- **Boundary**: Sisi kiri dan kanan terbuka penuh (tanpa dinding atau pembatas fisik). Melewati koordinat X < 64 atau X > 1344 saat di udara mengaktifkan sensor *Cliffhanger*.
- **Latar Belakang**: Pemandangan kota metropolitan neo-cyberpunk (*New Babel-01*) berawan kabut atmosfer di bawah ketinggian 2000 meter.

### 5.6 Single Player & Training Modes
1. **Versus AI Mode**:
   - Tiga tingkat kesulitan: *Novice* (AI lambat bereaksi, jarang parry), *Veteran* (AI aktif menjaga jarak, bereaksi pada frame 12), *Ace* (AI membaca pola panas, melakukan parry pada frame 6, memaksimalkan kombo Overclock).
2. **Training Mode Suite**:
   - Opsi visualisasi Hitbox (merah), Hurtbox (hijau), dan Collision box (biru).
   - Display frame data real-time (menampilkan Startup, Advantage on Hit/Block).
   - Dummy controller settings (Stand, Crouch, Jump, Block All, Random Parry, Record & Playback aksi 10 detik).

### 5.7 Competitive Features
- Arsitektur sistem input deterministik yang disiapkan untuk integrasi *Rollback Netcode* pasca-MVP.
- Dukungan *Local Versus* di PC dengan deteksi otomatis 2 unit kontroler gamepad independen.

---

## 6. Progression and Balance

### 6.1 Player Progression
- Berfokus pada progresi keahlian pemain (*pure mastery*).
- Indikator kecakapan berupa catatan statistik pertarungan (Win Rate, Rasio Keberhasilan Spark Parry, Total Ring-Out, Skor Efisiensi Panas).
- Sistem *Achievement Profile* internal untuk membuka palet warna alternatif (*skin mecha retro* 32-bit).

### 6.2 Difficulty Curve & Balancing Philosophy
- Filosofi Penyeimbangan: Tidak ada karakter "S-Tier" absolut; setiap mecha memiliki keunggulan match-up yang jelas (*Apex-0 unggul kecepatan jarak jauh, Titan-V mematikan pada pertarungan sudut dan kontak dekat*).
- Kurva Pembelajaran: Pemain dapat langsung bertarung dalam 60 detik pertama berkat sistem 3-skill, namun butuh waktu puluhan jam untuk menguasai ritme *Heat Management* dan *Spark Parry*.

### 6.3 Economy and Resources
- Tidak ada sistem stamina/energi bayar (*no pay-to-play gating*).
- Satu-satunya ekonomi dalam ronde adalah **Heat Meter (0–100%)** dan **Ultimate Gauge (0–100%)**, yang seluruhnya direset pada awal setiap ronde baru.

---

## 7. Level Design Framework

### 7.1 Level Types
- **Standard Flat Platform**: Desain panggung kompetitif datar tanpa rintangan penghalang untuk memastikan fokus murni pada adu taktik dua petarung.
- **Hazard Dynamics (Untuk Rilis Lanjutan)**: Variasi cuaca badai petir dan angin samping yang memengaruhi laju luncuran mecha.

### 7.2 Level Progression
- Pada fase MVP, panggung utama difokuskan secara spesifik pada *Zero-G Skyscraper Platform* untuk menguji stabilitas mekanik *Cliffhanger*. Panggung tambahan (seperti *Underground Magma Forge* dan *Orbital Elevator Station*) telah disiapkan untuk ekspansi konten berikutnya.

---

## 8. Art and Audio Direction

### 8.1 Art Style (Neo-Retro 32-Bit)
- **Gaya Visual**: Pixel art beresolusi tajam (resolusi dasar internal kanvas: 640x360 piksel, diskalakan presisi bilangan bulat ke 1080p/4K).
- **Karakter Visual Mecha**: Desain robot militer modular dengan siluet tajam, sendi hidrolik yang bergerak nyata, dan ventilasi pembuangan panas yang memerah saat bar mendekati 100%.
- **Efek Visual (VFX)**: Percikan api las kuning-oranye (*welding sparks*), tebasan pedang beam berpendar (*neon blue/magenta glow*), dan efek distorsi uap panas saat memasuki status *Overclock*.

### 8.2 Audio and Music
- **Sound Effects (SFX)**: Denting benturan pelat baja berat (*heavy metal clang*), desisan uap hidrolik bertekanan tinggi (*hydraulic hiss*), dan dengung motor listrik reaktor mecha.
- **Voice / Announcer**: Pengisi suara *Arcade Announcer* retro khas 90-an dengan filter radio sintetis ("SYSTEM ONLINE... ROUND 1... ENGAGE!", "CRITICAL HEAT DETECTED", "CORE BREAK!").
- **Musik Latar (OST)**: Musik bertempo cepat 140–160 BPM beraliran perpaduan *Industrial Metal* dan *Darksynth* bertenaga gitar elektrik synthesizer.

---

## 9. Technical Specifications

### 9.1 Performance Requirements
- **Frame Rate Target**: Terkunci pada **60 FPS** stabil tanpa stuttering (frame drop < 0.5% selama durasi pertarungan).
- **Waktu Muat (Load Time)**: Transisi dari layar pilih karakter ke dalam arena < 3.0 detik pada storage modern.
- **Konsumsi Memori (RAM)**: < 600 MB RAM pada perangkat PC dan Mobile.

### 9.2 Platform-Specific Details
- **PC (Windows / Linux via Proton)**:
  - Dukungan resolusi 16:9 native (1280x720, 1920x1080, 2560x1440, 3840x2160).
  - Skema kontrol otomatis mendeteksi Xbox Controller, DualShock/DualSense, dan Keyboard.
- **Mobile (Android 9.0+ & iOS 14+)**:
  - Layar sentuh dengan tata letak tombol ergonomis (*Dual-Thumb layout*).
  - Toleransi buffer sentuhan 5 frame dan area sentuh joystick virtual dinamis (*Floating Joystick* yang muncul di tempat jempol pertama kali menyentuh layar).
  - Optimasi hemat daya baterai untuk menjaga perangkat tidak lekas panas saat sesi permainan panjang.

### 9.3 Asset Requirements
- Format Sprite: Spritesheet 2D berbasis keyframe berukuran grid 96x96 piksel hingga 128x128 piksel per frame karakter.
- Audio: Stereo WAV / OGG Vorbis 44.1 kHz 16-bit.

---

## 10. Development Epics

Detail rinci cerita pengguna dan implementasi teknis tersimpan di [epics.md](file:///c:/Users/game/_bmad-output/planning-artifacts/gdds/gdd-game-2026-10-16/epics.md). Berikut adalah ringkasan struktur epics utama:

| Epic ID | Judul Epic | Lingkup Utama | Target Playable |
| :--- | :--- | :--- | :--- |
| **EPIC-01** | Core Physics & Movement | Pergerakan 8-arah, Vector Dash, Input Buffer 5f | Kotak uji karakter bergerak dan meluncur responsif. |
| **EPIC-02** | Heat & Defense Mechanics | Heat Gauge, Overclock, Meltdown, Spark Parry | Pertukaran pukulan, manajemen panas, dan parry frame aktif. |
| **EPIC-03** | Roster MVP: Viper & Bulwark | Kit lengkap 2 mecha (S1, S2, Ulti, Normals) | Pertarungan 2 karakter seimbang (Rushdown vs Grappler). |
| **EPIC-04** | Arena & Cliffhanger System | Zero-G Platform, Cliffhanger 120f, Ledge Stomp | Arena jurang aktif dengan adu rebutan tepi tebing. |
| **EPIC-05** | Game Modes & Dual Input HUD | Training Mode, Versus AI, Touch Overlay | Game utuh dari menu, training hitbox, hingga match AI. |
| **EPIC-06** | Audio-Visual Juice & Performance | Hitstop, partikel percikan, SFX, 60 FPS profiling | Game terpoles siap rilis internal/alpha test PC & Mobile. |

---

## 11. Success Metrics

### 11.1 Technical Metrics
- **Kestabilan Frame Rate**: 100% sesi gameplay mempertahankan 60 FPS rata-rata di Steam Deck dan smartphone target (Snapdragon 680 / Helio G95).
- **Input Responsiveness**: Input lag end-to-end < 50 ms pada PC dengan controller kabel.
- **Zero Crash Rate**: 0 crash terdeteksi selama 100 putaran ronde pertempuran AI otomatis berkelanjutan.

### 11.2 Gameplay & Player Engagement Metrics
- **Parry Adoption Rate**: Minimal 1 kali keberhasilan *Spark Parry* terpicu di setiap ronde pada tingkat pemain mahir, membuktikan mekanik ini intuitif dan bermanfaat.
- **Overheat Danger Frequency**: Rata-rata pemain menghabiskan minimal 25% durasi ronde di dalam zona Overclock (80–99%), membuktikan pilar *Risk-Reward* berhasil memacu tensi.
- **Round Duration Tempo**: Durasi pertandingan per ronde berada di rentang 45–75 detik, ideal untuk game fighting mobile maupun turnamen PC.

---

## 12. Out of Scope (Batasan Fase MVP)

Berikut adalah fitur yang **secara eksplisit ditunda** untuk update versi pasca-MVP demi menjaga fokus penyelesaian solo developer:
- Sistem Online Multiplayer / Netcode Lobby (Fokus awal membuktikan game feel lokal dan AI sebelum ekspansi jaringan).
- Karakter Roster 3 hingga 10 (Telah didokumentasikan dalam konsep awal, namun ditunda hingga Viper dan Bulwark selesai seimbang).
- Story Mode sinematik berbasis narasi dialog panjang.
- Sistem monetisasi mikrotransaksi, gacha, atau kosmetik berbayar.
- Dukungan layar rasio non-standar (seperti 32:9 Ultra-Wide).

---

## 13. Assumptions and Dependencies

- **[ASSUMPTION: Godot 4 2D Mobile Pipeline]**: Diasumsikan pipeline render 2D Godot Engine 4 (Compatibility / Forward+) mampu mempertahankan performa 60 FPS pada chipset smartphone menengah tanpa kendala shader compile stuttering.
- **[ASSUMPTION: Touch Ergonomics]**: Diasumsikan ukuran layar smartphone minimum 5.5 inci nyaman untuk layout kontrol 6 tombol aksi di sebelah kanan.
- **Ketergantungan Aset**: Menggunakan tool animasi modular atau keyframe pixel artistik untuk menjaga beban produksi solo developer tetap realistis.
