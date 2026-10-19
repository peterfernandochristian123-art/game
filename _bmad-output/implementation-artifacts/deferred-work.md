## Deferred from: code review of story 2-1 (2026-10-19)

- File hasil tes (`test_*_results.txt`) dan artefak Godot (`*.uid`, `*.import`) terlacak/berubah di git; pertimbangkan `.gitignore` atau kebijakan commit yang jelas.
- Dua sumber kebenaran heat maksimum: `BaseMecha.max_heat` vs `CombatConstants.MAX_HEAT`. Alasan: nilai sama (100); tangani saat ada karakter dengan heat maksimum berbeda.
