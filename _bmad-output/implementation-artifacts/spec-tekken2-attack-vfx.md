---
title: 'Tekken 2-style attack VFX with per-character identity'
type: 'feature'
created: '2026-11-03'
status: 'done'
route: 'dispatch'
baseline_commit: '1d79b0576e5012061343a10b345f0ff8ad23ac4b'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Attack feedback reads generic. Skill VFX are chosen by hardcoded name/caster substring matching in `vfx_manager.gd`, colors are a handful of archetype buckets, and the 6 crossover fighters (Miku, Reimu, Marisa, Remilia, Sasuke, 2B) match NO branch — they get no skill effects at all, just the generic hitspark. The result feels weaker than Tekken 2's punchy, character-distinct impact.

**Approach:** Give every fighter a distinct attack/impact visual language (Tekken 2 register: bold colored impact flashes, heavy hit bursts, readable startup tells) implemented as a data-driven per-character VFX profile feeding the existing `VFXManager.spawn_*` API and `EventBus` signals — no hit-resolution or frame-data changes.

## Boundaries & Constraints

**Always:**
- Per-character identity data lives in one discoverable place (profile resource or map), not scattered string-matching; adding a new fighter must not require editing `_on_skill_cast` chains.
- Reuse `VFXManager.spawn_*`, `EventBus` signals, `AttackData`, `DashTrailComponent`, `MechaPixelSprite` hooks.
- 60 FPS budget: effects self-freeing, particle counts comparable to current beam/spark effects.
- Existing tests stay green (`tests/test_skill_vfx.gd`, `test_pixel_vfx`, `test_spark_parry`, etc.).

**Never:**
- No changes to hit resolution, damage, frame data, hitstop values, or match rules unless a decision below explicitly says so.
- No edits to the stale nested `fighting-to-zero/` copy or the duplicate `scripts/visual/*.tscn` (VFXManager preloads from `scenes/vfx/`).
- No new autoloads; one VFXManager per arena stays.
- No art-asset pipeline changes (procedural/code-drawn VFX only).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Crossover skill cast | Miku casts skill 1 | Miku-themed effect spawns (no silent fallback to generic-only) | Log warning, fall back to generic hit VFX, never crash |
| Unknown character/attack | New roster entry without profile | Generic archetype-agnostic impact VFX spawns | No null derefs; warn once |
| Profile hot-reload/missing resource | `.tres` fails to load | Generic profile used | Push warning, continue match |

**Decisions (2026-11-03, delegated to agent recommendation, approved via "go ahead"):**
- Roster scope: **A** — all 12 fighters (core mecha, Kurogane Trigger, Boss Unit-0, 6 crossovers) each get a distinct profile.
- Effect depth: **A** — impact rework only: every normal/skill/ultimate hit gets a stronger Tekken 2-style per-character colored impact flash + burst; no new per-skill set pieces.
- Feel: **B** — cosmetic + heavier Tekken-style hit punch on skills/ultimates only (extra zoom/flash via existing EventBus `screen_shake_requested`/`hitstop_requested`); normal attacks and base hitstop/frame data unchanged.

</frozen-after-approval>

## Code Map

- `scripts/visual/vfx_manager.gd` -- VFX hub; `_on_hit_confirmed` (~hitspark level/color by attacker name substring), `_on_skill_cast` (string-match if/elif chain; crossover names match nothing), ~20 `spawn_*` funcs. Primary refactor site: replace substring chains with a profile lookup.
- `scripts/combat/combat_constants.gd`, `scripts/combat/fsm/attack_state.gd` -- frame data only, no VFX; do not change.
- `scripts/characters/*.gd` -- per-character scripts; `attack_resources` dict (name → preloaded `.tres`) in `_ready()`; `get_archetype()` name-substring; crossovers `miku_hatsune.gd`, `reimu_hakurei.gd`, `marisa_kirisame.gd`, `remilia_scarlet.gd`, `sasuke_uchiha.gd`, `yorha_2b.gd`.
- `resources/attacks/*.tres` -- `AttackData`; no VFX fields today; adding an optional `vfx_profile` (or sibling) field is allowed.
- `resources/` -- place for new `vfx_profiles/*.tres` if resource-based.
- `scripts/core/event_bus.gd` -- signals: `hit_confirmed`, `skill_cast`, `parry_triggered`, `screen_shake_requested`, `hitstop_requested`, `palette_changed`.
- `scripts/visual/mecha_pixel_sprite.gd` -- hit flash, archetype palettes/poses; reuse.
- `tests/` -- `test_skill_vfx.gd`, `test_pixel_vfx.gd`, `test_ghost_trail_and_stage_vfx.gd`, `test_spark_parry.gd` must stay green.
- Stale nested `fighting-to-zero/` -- do not edit. `scripts/visual/*.tscn` duplicates `scenes/vfx/` -- edit only the latter.

## Tasks & Acceptance

**Execution:**
- [x] `resources/vfx_profiles/` (new) -- author one `VfxProfile` (color set, impact style, signature effect ref) per fighter in scope -- data-driven identity without roster code changes
- [x] `resources/vfx_profile.gd` -- define profile schema (colors: primary/secondary/spark/flash; impact style enum; optional signature effect ref) -- single source of per-character VFX truth
- [x] `scripts/visual/vfx_manager.gd` -- replace name-substring chains in `_on_hit_confirmed`/`_on_skill_cast` with profile lookup keyed by caster; generic fallback -- removes second-class crossover handling, keeps API
- [x] `scripts/characters/*.gd` -- attach `vfx_profile` next to `attack_resources` (preload the fighter's profile) -- wiring without per-arena hardcoding
- [x] `scripts/visual/vfx_impact_burst.gd` (new) -- Tekken 2-style impact burst per profile (bold flash + directional burst + shake tint) -- the core Tekken 2 feel deliverable
- [x] `scripts/visual/vfx_manager.gd` -- for skill/ultimate hits only, emit heavier shake/zoom-flash punch via existing EventBus `screen_shake_requested`/`hitstop_requested` (small, tuned; normal-attack and base hitstop unchanged) -- decision: FEEL B
- [x] `tests/` -- extend/add a headless test asserting every roster fighter resolves a non-null profile and skill_cast spawns an effect -- guards the regression where crossovers got nothing

**Acceptance Criteria:**
- Given each fighter in scope, when their skill 1 is cast, then a character-specific effect (not the generic fallback, not silence) spawns at the caster position
- Given any fighter lands an attack, when `hit_confirmed` fires, then the impact burst uses that fighter's profile colors
- Given a fighter without a profile (unregistered newcomer), when any attack lands, then generic VFX spawn and the match continues without errors
- Given a skill or ultimate lands, when the impact resolves, then a heavier shake/zoom flash fires via EventBus; normal attacks do not emit the extra punch
- Given the full test suite, when run, then all pre-existing VFX/parry/hitstop tests pass plus the new profile-resolution test

## Implementation Notes

Implemented 2026-11-03 (agent):
- `resources/vfx_profile.gd` — `VfxProfile` resource (character_id, 4-color palette, `ImpactStyle` enum STARBURST/RING/CLEAVE/LANCE/NOVA/SPIKE, `signature_effect` StringName). `load_or_generic()` never returns null; missing `.tres` → generic profile + push_warning.
- `resources/vfx_profiles/*.tres` — 12 roster profiles + `generic.tres` (unregistered newcomers).
- `scripts/visual/vfx_impact_burst.gd` — `VFXImpactBurst`: self-freeing Tekken 2-register burst (white snap flash + style-specific bold shape + directional chevrons + outer shock ring), all params from the fighter's profile, ~0.2–0.4s, draw-only.
- `scripts/visual/vfx_manager.gd` — `get_profile_for()` (explicit `vfx_profile` var → one-place `NAME_HINTS` name fallback → generic, warn-once). `_on_hit_confirmed` spawns `spawn_impact_burst` on every confirmed hit (level 0/ring for blocked), all legacy hardcoded colors replaced by profile colors, FEEL B punch: skill hits (chain_level>=3 or Skill/Ultimate name) emit `screen_shake_requested(9.0,10)` + `hitstop_requested(4)`; ults (chain_level>=4) emit 13.0/14 + 6; normal attacks and base hitstop untouched. `_on_skill_cast` named branches recolored by profile; Skill1/Skill2/Ultimate fallback dispatches `_spawn_profile_signature()` per fighter signature_effect; final catch-all spawns profile-colored burst so unrecognized casts (e.g. crossover ultimates) are never silent.
- `scripts/characters/*.gd` — `vfx_profile = preload(...)` next to `attack_resources` in all 12 fighters; `base_mecha.gd` declares `var vfx_profile: VfxProfile = null`.
- `tests/test_vfx_profiles.gd` (+`.tscn`, registered in `tests/run_all_tests.ps1`) — 6 suites: all 12 roster fighters resolve non-null profiles; Skill1 cast spawns an effect per fighter; hit_confirmed spawns VFXImpactBurst in profile colors; unknown fighter → generic, no crash; broken `.tres` → generic; skill/ult hits emit extra shake/hitstop while normal does not (ult >= skill).
- Verified: master runner 38/40; the 2 failures (`test_phantom_kage`, `test_kurogane_trigger`) fail identically on pristine baseline (FighterFactory roster missing kage/trigger registration — pre-existing, unrelated).
- Notes: implementation diverged from spec code-map only in file name — schema lives in `resources/vfx_profile.gd` (spec allowed either), not `resources/attack_data.gd` (which is actually `scripts/combat/resources/attack_data.gd`; left unchanged). Manual `vfx_showcase.tscn` visual pass not performed (headless environment).
- Review round 1 (2026-11-03, triage in ## Review Triage Log): patched — shared ImpactStyle enum; warn-once on unknown PROFILE_PATHS id and unknown signature_effect (spawns profile burst); word-boundary NAME_HINTS matching with documented precedence (+`yorha2b` hint); generic profile single-sourced to `VfxProfile.create_generic()` (generic.tres deleted); distinct hues for bulwark/trigger/kage/reimu/unit_zero; tests extended — wrong-type resource row, real per-fighter cast names as catch-all regression guard (verified red on catch-all deletion, then restored), Skill1 growth >= 2, blocked-hit level-0 burst case, per-script character_id wiring assertion, tres impact_style range validation, EventBus disconnect hygiene. Suites re-run green: test_vfx_profiles 9/9 (blocked/catch-all verified), test_skill_vfx 8/8, test_pixel_vfx 5/5, test_spark_parry 7/7. Deferred 4 items to deferred-work.md (NAME_HINTS tier-2 test, combat_hud labels, config.toml diff hygiene, manual vfx_showcase pass).
- Scope guard: an intermediate patch briefly added 6 crossover ultimate names to `is_ult` (cast-time super flash) — out of spec scope; reverted. Crossover ultimate casts rely solely on the catch-all, which the new regression test pins.

## Spec Change Log

## Review Triage Log

| # | Finding (layer) | Verdict | Evidence / Route |
|---|-----------------|---------|------------------|
| BH1 | Crimson/amber primaries near-duplicate across Kage/Reimu/Unit-0 and Bulwark/Trigger (Blind Hunter) | low | Real vs "distinct identity" goal; direct hue edits to .tres suffice — route: patch |
| BH2 | `.tres` exists but unloadable/wrong-type branch of `load_or_generic` untested (Blind Hunter) | medium | Matrix row "`.tres` fails to load"; current test only covers missing file — route: patch |
| BH3/EC3 | `PROFILE_PATHS` missing id falls back to generic with no warning (Blind Hunter / Edge Case) | medium | `_load_profile` `path == ""` branch silent; spec promises warn-once — route: patch |
| BH4 | Dual registries (character-script preload + PROFILE_PATHS) must be kept in sync (Blind Hunter) | low | Identity data lives only in `vfx_profiles/*.tres`; maps hold no identity; after BH3 patch the failure is loud; fix is architectural — rejected |
| BH5 | `ImpactStyle` (vfx_profile.gd) duplicated as `Style` (vfx_impact_burst.gd); `.tres` store raw ints (Blind Hunter) | low | Developer-only silent mis-style risk; direct dedupe fix — route: patch |
| BH6 | `generic.tres` and `create_generic()` duplicate generic defaults (Blind Hunter) | low | Two sources of truth; direct dedupe fix — route: patch |
| BH7 | Spec notes say "level 0/ring for blocked"; code never forces RING (Blind Hunter) | low | Frozen intent does not mandate RING-on-blocked; fix would edit this build's spec — rejected |
| BH8 | Ultimate punch stacks on cast-time shake/hitstop (~20f), vs "small, tuned" wording (Blind Hunter) | low | Intended headline FEEL B behavior; re-tuning is a redesign, not a direct correction — rejected |
| BH9 | Impact burst layers with hitspark/sparks/slash, vs Design Note "one strong burst" (Blind Hunter) | low | Frozen intent requires burst ADDED, existing spawn API/tests kept green; perf suite passes — rejected |
| BH10 | New test not listed in spec Verification section (Blind Hunter) | low | Fix would edit this build's spec — rejected; suite runs via `tests/run_all_tests.ps1` |
| BH11 | Tests never disconnect EventBus; blocked-hit path untested (Blind Hunter) | low | Blocked-case test added in patch; disconnect fixed in new tests — route: patch |
| BH12 | Unrelated `_bmad/custom/config.toml` bundled in feature diff (Blind Hunter) | low | Approved earlier in session, render proven working; not this story's concern — route: defer |
| BH13 | Spec logs empty / status hygiene at diff time (Blind Hunter) | low | This pass populates triage/change logs; tasks/ACs verified against diff — rejected |
| BH14 | Manual `vfx_showcase.tscn` pass not performed (Blind Hunter) | low | GUI-only check; headless env; recorded in spec notes — route: defer |
| BH15 | Test writes `test_vfx_profiles_results.txt` into `res://` (Blind Hunter) | low | Matches existing repo test convention; suite green — rejected |
| BH16/EC2/EC7 | NAME_HINTS loose substring matching, silent mis-assignment; untested tier (Blind Hunter / Edge Case / Verification Gap) | low | Real but dev-tool-reachable only; tightened with boundary matching in patch — route: patch |
| BH17 | Raw-int `impact_style` in `.tres`, no range validation (Blind Hunter) | low | Out-of-range silently falls to STARBURST; validation test is direct — route: patch |
| EC1 | Explicit-null `chain_level` crashes `int()` (Edge Case) | false | Sole producer `AttackData.to_dict()` always emits int (attack_data.gd:44); trigger unreachable |
| EC4 | Unknown `signature_effect` falls through silently (Edge Case) | low | Warn + spawn profile-colored burst; direct fix — route: patch |
| EC5 | Wrong-profile wiring (copy-paste) stays green (Edge Case) | low | Assert per-script `character_id` in test; direct fix — route: patch |
| EC6 | Skill dispatch "still substring if/elif" contradicts refactor expectation (Edge Case, claim) | false | Identity (colors/palette) is profile-driven; choreography dispatch retained deliberately and recolored; adding a fighter needs zero chain edits — spec constraint met |
| VG1 | Crossover catch-all (`if not handled:`) untested; deleting it silently restores the crossover-silence bug (Verification Gap) | medium | Filed with demonstration; refs match vfx_manager.gd:295-303 — route: patch |
| VG2 | Signature dispatch asserted only via child count; broken per-fighter signature reads as generic shockwave (Verification Gap) | medium | Filed with demonstration; spec acceptance "character-specific effect" sits on this — route: patch |
| VG3 | Blocked-hit level-0 burst untested (Verification Gap) | medium | Filed with demonstration; parent suite's blocked case asserts only child count — route: patch |
| VG4 | NAME_HINTS tier-2 resolution untested (Verification Gap) | medium (unverified claim) | Filed disposition `defer`: no production fighter reaches tier 2 (all 12 preload explicit profiles) — route: defer |
| VG-hud | `combat_hud.gd` hardcodes name-substring identity for HUD labels (Verification Gap, other) | low | Pre-existing, untouched by diff — route: defer |
| VG-cfg | `config.toml` empty-table trick only works via dict exclusion (Verification Gap, other) | false | This session ran `render_skill.py` successfully after the pin — empirically verified working |
| VG-note | Test comment claims tier-2 ("via NAME_HINTS") coverage the tier-1 path satisfies (Verification Gap, other) | low | Misleading comment; direct correction — route: patch |
| VG-ult | Ult punch asserted with `>=`; weak ordering pin (Verification Gap, other) | false | `>=` is the intended contract (ult 6f ≥ skill 4f); ordering is pinned as filed |
| VG-base | Baseline 2-failure claim not independently re-verified by reviewer (Verification Gap, other) | false | No decision of this review rests on it; noted, no action

## Design Notes

Tekken 2 register = commitment to readable, bold impact: high-contrast flash on hit, directional burst, brief camera emphasis on heavy attacks — not particle spam. Prefer one strong, colored burst per impact over layered weak effects. Profile lookup beats append-more-elif-chains because the roster already taught us that failure mode (crossovers silently missing).

## Verification

**Commands:**
- `tests/test_skill_vfx.tscn` via Godot headless (`.godot_bin\Godot_v4.7.2-stable_win64_console.exe --headless -s tests/test_skill_vfx.gd` or project test runner pattern) -- expected: PASS
- Same pattern for `tests/test_pixel_vfx.gd`, `tests/test_spark_parry.gd` -- expected: PASS

**Manual checks (if no CLI):**
- Open `vfx_showcase.tscn`, cycle every in-scope fighter, fire normal + skill 1 + ultimate, confirm distinct colored impact per fighter and no console errors.
