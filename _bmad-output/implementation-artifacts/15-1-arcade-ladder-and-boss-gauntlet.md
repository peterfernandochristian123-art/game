---
title: "Epic 15: Arcade Ladder & Boss Gauntlet Mode"
status: done
epic: epic-15
---

# Epic 15: Arcade Ladder & Boss Gauntlet Mode

Status: done

## Overview
Menghadirkan pengalaman arcade klasik penuh aksi dan narasi mendalam ke dalam **Fighting to Zero**:
1. **Arcade Ladder Progression (`scripts/arcade/arcade_ladder_manager.gd` & `scenes/arcade_ladder_mode.tscn`)**:
   - Kampanye turnamen 4-tahap sekuensial dengan eskalasi AI (Novice ➔ Veteran ➔ Ace ➔ Nightmare Boss).
   - Banner intro panggung ("STAGE 1 / 4 - SKYSCRAPER DUEL", dsb.) dengan transisi mulus.
   - Layar hitung mundur "CONTINUE?" 10 detik saat pemain kalah, memungkinkan retry panggung seketika.
2. **Pre-Battle & Victory Dialogue Cutscenes (`scripts/arcade/dialogue_db.gd`, `scripts/arcade/dialogue_overlay.gd` & `scenes/dialogue_overlay.tscn`)**:
   - Percakapan dua arah otentik sebelum duel antar karakter (mengacu pada lore [narrative.md](file:///c:/Users/user/.gemini/antigravity-ide/scratch/game/_bmad-output/planning-artifacts/narrative.md)).
   - Efek pengetikan teks dinamis (typer effect) dengan opsi instan skip via Space, Enter, atau Button A gamepad.
   - Kutipan kemenangan unik (*victory quotes*) pasca setiap kemenangan ronde.
3. **Climactic Final Boss: Unit-0 "Shadow Core" (`scripts/characters/boss_unit_zero.gd`)**:
   - Mecha prototipe korup dengan Max HP 1500, passive damage reduction 10%, jalan 340 px/s, dash 880 px/s.
   - Status *Permanent Overclock Zone* (90% Heat terkunci tanpa meltdown), memberikan 1-Hit Super Armor pada frame startup dan +20% damage buff.
   - Ditenagai profil AI `Difficulty.NIGHTMARE` (3-frame reflex delay, 90% parry rate, dan 100% kombo punish).
4. **Arcade Ending, Victory Summary & Rank Evaluation (`scripts/arcade/arcade_ending.gd` & `scenes/arcade_ending.tscn`)**:
   - Evaluasi performa berdasarkan waktu tempuh, continues, parry, dan ring-out menghasilkan predikat Peringkat S / A / B / C.
   - Kartu epilog cerita khas untuk setiap karakter:
     - Apex-0 Viper: *The Absolute Zero Ascension*
     - Titan-V Bulwark: *The Iron Reign of the Under-Core*
     - Ray-X Pulsar: *Solar Harmony Restored*
     - Phantom-9 Kage: *The Shadow Dispersal*
   - Pelacakan rekor karir pemain (Arcade Clears dan Best Rank) di `user://records.cfg` via `RecordsManager`.
5. **Main Menu & Roster Integration**:
   - Ditambahkan opsi "ARCADE LADDER" di `MainMenu` (`MENU_DATA`).
   - `CharacterSelect` secara otomatis menyesuaikan mode Arcade (pemilihan P1 dan peluncuran langsung ke kampanye gauntlet).

## Automated Verification
Suite pengujian `tests/test_arcade_ladder.tscn` memvalidasi seluruh 4 story (dialogue database, overlay interaction, boss mechanics, nightmare AI, ladder pipeline, rank evaluation & records).
Seluruh **35 Automated Test Suites** dari Epic 1 hingga Epic 15 lulus 100%.
