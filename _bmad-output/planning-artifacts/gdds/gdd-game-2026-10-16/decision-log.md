# Decision Log: Fighting to Zero GDD

Project: Fighting to Zero (game)  
Author: User  
Date: 2026-10-16  
Status: Finalized  

---

## 2026-10-16: Workspace Initialization & Intent Confirmation
- **Intent**: Create new Game Design Document (GDD).
- **Genre Selection**: Fighting (2D Mecha Fighting Game / Arcade Duelist) matching `fighting.md` taxonomy (Complexity: High).
- **Core Input Document**: `_bmad-output/planning-artifacts/briefs/brief-game-2026-10-16/brief.md` adopted as primary foundation.
- **Engine & Scope**: Godot Engine 4, Solo Developer MVP target (2 fighters, 1 arena, Versus AI, Training, Local Versus).
- **Working Mode**: Express drafting with pre-resolved design parameters based on Game Brief.

## 2026-10-16: Core Design & System Decisions
1. **Simplified 3-Skill Input Architecture**:
   - Single-button skill triggers (Normal Attack, 8-way Dash, Skill 1, Skill 2, Ultimate, Spark Parry).
   - Input buffer: 5 frames (83.3ms at 60 FPS) to ensure smooth input transmission on mobile touch controls without lag feeling on PC.
   - Captured in `gdd.md` Section 4.2 & `epics.md` EPIC-01.
2. **Spark Parry Frame Data**:
   - Active window: 4 frames (frames 2–5). Startup: 1 frame. Whiff recovery: 14 frames (punishable counter-hit state).
   - Reward on success: 0 blockstun, freezes attacker for 12 frames, absorbs 15% Ultimate meter from attacker, refunds 20% Heat.
   - Captured in `gdd.md` Section 4.1 & 5.2.
3. **Heat Management Thresholds**:
   - 0–79% (Nominal): Standard performance and cooling rate (-12%/s when idle).
   - 80–99% (Overclock Zone): Skills gain +20% damage and 1-hit Super Armor (startup frames only).
   - 100% (Emergency Meltdown / Overheat): Mecha enters Shutdown state for 90 frames (1.5 detik), taking +25% damage from all attacks. Venting cools back to 0%.
   - Captured in `gdd.md` Section 4.1 & `epics.md` EPIC-02.
4. **Cliffhanger Ring-Tension Mechanic**:
   - Trigger: Knockback beyond platform bounds when HP > 0 triggers ledge grab (max 1 time per stock/round).
   - Duration: 120 frames (2.0 detik).
   - Options for hanging player:
     - *Climb-Up Jump* (Jump / Up button): 18 frames startup, vulnerable to anti-air.
     - *Ledge Sweep Attack* (Attack button): Low sweep (12 frames startup), deals 10% damage, safe on block (-2).
     - *Drop Fall* (Down button): Deliberate self-destruct / ring-out.
   - Option for platform controller:
     - *Ledge Stomp* (Down + Attack): Forces instant Ring-Out if executed before defender recovers (15f startup).
   - Captured in `gdd.md` Section 4.1 & `epics.md` EPIC-04.
5. **Roster Archetypes (MVP)**:
   - **Apex-0 "Viper"**: Rushdown / Glass Cannon. High mobility (fast vector dashes, 3-frame startup normals), lower armor (900 HP).
   - **Titan-V "Bulwark"**: Heavy Grappler / Space Control. High armor (1200 HP, passive 5% damage reduction), slower dashes, command throw S1.
   - Captured in `gdd.md` Section 5.1 & `epics.md` EPIC-03.

## 2026-10-16: Finalization & Audit Pass
- **Input Reconciliation**: Seluruh visi, 4 pilar, target platform, estetika neo-retro 32-bit, dan mitigasi risiko dari Game Brief telah direkonsiliasi secara penuh ke dalam `gdd.md` dan `epics.md`.
- **Discipline Pass**: Memenuhi seluruh konvensi genre *Fighting* kompleksitas tinggi (Frame data lengkap pada 60 FPS, damage scaling, juggle/bounce boundaries, defensive mechanics, training mode specs).
- **Out of Scope Check**: Fitur lanjutan (Rollback Netcode online, roster 3–10, hazard stage dinamis) telah dialokasikan dengan jelas ke fase pasca-MVP.
- **Workflow State**: GDD selesai dan ditandai siap untuk tahap berikutnya (`gds-game-architecture`).
