---
title: "Addendum: Fighting to Zero"
status: active
created: '2026-10-16'
updated: '2026-10-16'
---

# Addendum: Fighting to Zero (Roster & Sistem Lanjutan)

Dokumen ini mencatat detail desain yang diparkir dari sesi brainstorming untuk diimplementasikan pasca-MVP atau menjadi input langsung pada tahap Game Design Document (GDD).

---

## 1. Roster Mecha Pasca-MVP (Karakter 3 - 10)

Setiap karakter telah dirancang dengan kit 3 skill unik (Skill 1, Skill 2, Ultimate):

1. **Spectre-9 "Mirage"** (Stealth & Electronic Warfare)
   - *Skill 1*: Holo-Decoy Dash (Lompat mundur meninggalkan klon peledak glitch).
   - *Skill 2*: EMP Tether (Menonaktifkan skill musuh selama 2.5 detik).
   - *Ultimate*: Cyber Phantom Domain (Arena berubah menjadi wireframe neon, Mirage tak terlihat dan bebas mengeksekusi 3 tebasan kritis).
2. **Ignis-Core "Salamander"** (Zone Control & Pyrotechnics)
   - *Skill 1*: Magma Puddle (Cairan termal di lantai yang membakar dan memperlambat musuh).
   - *Skill 2*: Thermal Propulsion (Pendorong jet punggung untuk menabrak musuh ke dinding / wall-splat).
   - *Ultimate*: Supernova Meltdown (Gelombang kejut api 360 derajat penembus proyektil).
3. **Chronos-X "Paradox"** (Time Distortion Prototype)
   - *Skill 1*: Rewind Anchor (Menaruh penanda waktu; teleportasi balik dalam 3 detik).
   - *Skill 2*: Stasis Pulse (Bola gravitasi yang melambatkan musuh dan proyektil sebesar 70%).
   - *Ultimate*: Timeline Shatter (Hentikan waktu selama 1.5 detik untuk kombo bebas).
4. **Volt-Jockey "Railgunner"** (Long-Range Ballistics)
   - *Skill 1*: Kinetic Piercer (Tembakan rel penetrasi guard).
   - *Skill 2*: Refraction Drone (Drone prisma pemantul sudut tembakan).
   - *Ultimate*: Ion Sat-Strike (Bombardir laser orbital).
5. **Hive-Mother "Chitin"** (Bio-Mechanical Swarm)
   - *Skill 1*: Parasite Needle (Duri bio-metal penguras heat musuh).
   - *Skill 2*: Swarm Shield (Nano-serangga penyerap 2 serangan pertama).
   - *Ultimate*: Swarm Devourer (Ratusan mikro drone peledak serentak).
6. **Giga-Rupture "Berserk"** (Overclocked Steam Brawler)
   - *Skill 1*: Piston Jab Rush (Rentetan tinju piston mekanik pendorong).
   - *Skill 2*: Steam Vent Venting (Buang uap panas untuk cancel animation frame).
   - *Ultimate*: Redline Ignition (Bakar 15% HP sendiri untuk super-armor tanpa henti dan damage x2 selama 8 detik).
7. **Magna-Pulse "Lodestone"** (Magnetic Manipulator)
   - *Skill 1*: Magnetic Pull/Repel (Tarik/dorong posisi musuh secara paksa).
   - *Skill 2*: Scrap Shrapnel (Kumpulkan serpihan logam jadi bola proyektil tajam).
   - *Ultimate*: Magnetic Cataclysm (Pusaran magnetik penghisap musuh ke pusat kehancuran).
8. **Echo-Warden "Resonator"** (Acoustic Disruption)
   - *Skill 1*: Sonic Shockwave (Gelombang suara pembalik tombol kontrol musuh 1.5 detik).
   - *Skill 2*: Resonance Barrier (Dinding sonik penyerap proyektil menjadi serangan balik).
   - *Ultimate*: Screaming Void (Dentuman bass pemecah guard instan).

---

## 2. Arena Tambahan untuk Roadmap
- **Underground Reactor Room**: Arena sempit tertutup dengan bahaya semburan uap reaktor setiap 30 detik untuk menguji spacing dan wall-bounce kombo.

---

## 3. Catatan Teknis Arsitektur (Godot 4)
- **Input System**: Gunakan unified input abstraction (`InputMap`) yang memetakan virtual joystick / touch screen gesture di mobile dan gamepad/keyboard di PC ke sinyal aksi yang sama (`action_attack`, `action_skill_1`, `action_skill_2`, `action_ultimate`, `action_dash`, `action_guard`).
- **Hitbox/Hurtbox Component**: Modul reusable 2D collision layer khusus untuk frame data fighting game (startup, active, recovery frames).
