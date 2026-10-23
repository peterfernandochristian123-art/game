---
title: "Game UX & UI Specification: Fighting to Zero"
status: complete
created: '2026-10-23'
---

# Game UX & UI Specification: Fighting to Zero

## 1. UX Vision & Aesthetics

Antarmuka *Fighting to Zero* mengusung estetika **Neo-Retro 32-Bit Arcade Cyberpunk** pada kanvas internal native 640x360 piksel. Desain UI mengutamakan keterbacaan instan (*glanceability*), umpan balik visual yang berdampak tinggi (*combat juice*), dan kesetaraan ergonomi kontrol lintas platform PC dan Mobile.

---

## 2. Navigation Flow & Information Architecture

```
[Game Launch]
      │
      ▼
[Main Menu: scenes/main_menu.tscn]
  ├── Versus AI (P1 vs Bot: Novice / Veteran / Ace)
  ├── Local 2-Player (Head-to-head gamepad duel)
  ├── Training Mode (Lab suite with F1/F2 inspector)
  └── Settings (Audio buses & Keybindings)
      │
      ▼
[Character & Stage Select: scenes/character_select.tscn]
  ├── Roster Selection: Apex-0 Viper / Titan-V Bulwark / Ray-X Pulsar
  ├── Live Animated Pixel Sprite Previews (P1 & P2)
  ├── Stage Selector Toggle: [TAB] Zero-G Skyscraper / Underground Reactor
  └── Lock-In Confirmation -> Launching Arena
      │
      ▼
[Gameplay Arena Duel: scenes/versus_ai_mode.tscn / local_versus_mode.tscn]
  ├── Full-Screen Combat HUD
  ├── Match Rules Evaluation (Best of 3 Rounds)
  └── Match Result Overlay (Rematch / Return to Character Select / Menu)
```

---

## 3. Combat HUD Specification

Tampilan antarmuka pertarungan (`scenes/combat_hud.tscn`) dirancang minimalis namun sarat informasi:

1. **HP Bars**:
   - Diletakkan di sudut kiri atas (P1) dan kanan atas (P2).
   - Bar merah/kuning dengan indikator chip damage dan animasi penyusutan halus.
2. **Dynamic 3-Zone Heat Meter**:
   - Terletak tepat di bawah bar HP masing-masing petarung.
   - **Nominal Zone (0% – 79%)**: Warna Cyan / Hijau zamrud stabil.
   - **Overclock Zone (80% – 99%)**: Warna Oranye-Merah berkedip dinamis dengan aura api petarung.
   - **Meltdown Shutdown (100%)**: Warna Ungu tua redup dengan tanda peringatan mati daya.
3. **Ultimate Meter (0% – 100%)**:
   - Terletak di dasar layar; memancarkan pendaran emas saat penuh (100% READY).
4. **Round Timer & Win Counters**:
   - Timer 90 detik digital retro di tengah atas.
   - Indikator lampu piala ronde (2 ronde untuk menang).

---

## 4. Dual-Input Control Ergonomics

- **PC (Keyboard / Controller)**:
  - Deteksi otomatis stik analog gamepad (Xbox / PlayStation).
  - Skema tombol tunggal: Normal (`J`), Dash (`L`), Skill 1 (`U`), Skill 2 (`I`), Parry (`K`), Ultimate (`O`).
- **Mobile (Touch Screen)**:
  - **Dynamic Floating Joystick**: Muncul otomatis di posisi jempol kiri pertama kali menyentuh layar.
  - **Cluster 6 Tombol Sentuh**: Tata letak ergonomis jempol kanan dengan radius nyaman minimum layar 5.5 inci.
