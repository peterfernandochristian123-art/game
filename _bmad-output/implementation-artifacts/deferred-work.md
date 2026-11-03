## Deferred from: code review of story 2-1 (2026-10-19) - RESOLVED in Story 7.1

- [x] File hasil tes (`test_*_results.txt`) dan artefak Godot (`*.uid`, `*.import`): `test_*results.txt` telah dihapus dari git tracking (`git rm --cached`) dan `.gitignore` diperbarui untuk mencegah pelacakan file hasil pengujian otomatis.
- [x] Dua sumber kebenaran heat maksimum: `BaseMecha.max_heat` telah diselaraskan agar merujuk ke `CombatConstants.MAX_HEAT` sebagai single source of truth.

- source_spec: `C:\Users\game\_bmad-output\implementation-artifacts\spec-tekken2-attack-vfx.md`
  summary: Test the NAME_HINTS tier-2 (node-name -> profile id) resolution in VFXManager.get_profile_for with bare Node2D casters.
  evidence: Verification Gap review showed every current test exercises tier 1 (explicit vfx_profile) or tier 3 (generic); no assertion reads a hint mapping. Real but narrow - no production fighter reaches tier 2 (all 12 carry explicit preloads); a small addition to tests/test_vfx_profiles.gd closes it.
- source_spec: `C:\Users\game\_bmad-output\implementation-artifacts\spec-tekken2-attack-vfx.md`
  summary: combat_hud.gd hardcodes name-substring identity mapping for P1 skill labels (Viper/Bulwark/Pulsar/Kage/Unit-0 only); Trigger and the 6 crossovers get generic labels.
  evidence: Pre-existing issue untouched by the Tekken 2 VFX diff (scripts/ui/combat_hud.gd:278-291); shares the name-substring mechanism this change retired everywhere else. Flagged by Verification Gap reviewer.
- source_spec: `C:\Users\game\_bmad-output\implementation-artifacts\spec-tekken2-attack-vfx.md`
  summary: _bmad/custom/config.toml (empty-table pin disambiguating bmm/gds duplicate keys) is bundled in the same working-tree diff as the VFX feature.
  evidence: Diff-hygiene finding (Blind Hunter); the pin was approved in-session and proven working by a successful render_skill.py run, but it is unrelated to the feature and belongs in its own commit.
- source_spec: `C:\Users\game\_bmad-output\implementation-artifacts\spec-tekken2-attack-vfx.md`
  summary: Manual vfx_showcase.tscn pass (cycle all 12 fighters, fire normal/skill 1/ultimate) not yet performed.
  evidence: GUI-only check; implementation environment was headless. All headless verification green (38/40 with 2 pre-existing unrelated failures; test_vfx_profiles 6/6). Visual distinctness of the 12 profiles (CLEAVE/LANCE/SPIKE silhouettes, Marisa vertical Master Spark) is unverified by eye.
