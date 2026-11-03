extends Node

## Test Tekken 2 Attack VFX: resolusi VfxProfile per fighter roster.
## Menjaga regresi di mana 6 crossover fighter tidak mendapat efek skill sama sekali.

const VFXManagerScript = preload("res://scripts/visual/vfx_manager.gd")
const VFXImpactBurstScript = preload("res://scripts/visual/vfx_impact_burst.gd")
const VfxProfileScript = preload("res://resources/vfx_profile.gd")

const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")
const RayPulsarScript = preload("res://scripts/characters/ray_pulsar.gd")
const PhantomKageScript = preload("res://scripts/characters/phantom_kage.gd")
const KuroganeTriggerScript = preload("res://scripts/characters/kurogane_trigger.gd")
const BossUnitZeroScript = preload("res://scripts/characters/boss_unit_zero.gd")
const MikuHatsuneScript = preload("res://scripts/characters/miku_hatsune.gd")
const ReimuHakureiScript = preload("res://scripts/characters/reimu_hakurei.gd")
const MarisaKirisameScript = preload("res://scripts/characters/marisa_kirisame.gd")
const RemiliaScarletScript = preload("res://scripts/characters/remilia_scarlet.gd")
const SasukeUchihaScript = preload("res://scripts/characters/sasuke_uchiha.gd")
const Yorha2BScript = preload("res://scripts/characters/yorha_2b.gd")

const PROFILE_IDS: Array[StringName] = [
	&"viper", &"bulwark", &"pulsar", &"kage", &"trigger", &"unit_zero",
	&"miku", &"reimu", &"marisa", &"remilia", &"sasuke", &"yorha_2b",
]

var log_file: FileAccess = null
var _failed: bool = false

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		_log("   [FAIL] " + msg)
	else:
		_log("   [PASS] " + msg)

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_vfx_profiles_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)

	_log("==================================================")
	_log("[TEST RUNNER] Tekken 2 Attack VFX — VfxProfile Resolution...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_every_roster_fighter_resolves_profile,
		_test_roster_tres_loads_and_impact_style_in_range,
		_test_skill_cast_spawns_effect_for_every_fighter,
		_test_real_cast_names_spawn_effect_for_every_fighter,
		_test_hit_confirmed_uses_profile_colors,
		_test_blocked_hit_spawns_zero_level_impact_burst,
		_test_unknown_fighter_gets_generic_profile,
		_test_missing_resource_falls_back_to_generic,
		_test_skill_hit_emits_extra_punch_normal_does_not
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			_log(" [BERHASIL]")
			passed += 1

	_log("\n==================================================")
	_log("HASIL AKHIR: %d/%d Pengujian Lolos." % [passed, tests.size()])
	_log("==================================================")

	if passed == tests.size():
		_log("SEMUA PENGUJIAN VFX PROFILE BERHASIL (100% SUKSES)!")
	else:
		_log("BEBERAPA PENGUJIAN VFX PROFILE GAGAL!")

	if log_file:
		log_file.close()

	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if passed == tests.size() else 1)

func _roster_scripts() -> Dictionary:
	return {
		"Viper": ApexViperScript,
		"Bulwark": TitanBulwarkScript,
		"Pulsar": RayPulsarScript,
		"Kage": PhantomKageScript,
		"Trigger": KuroganeTriggerScript,
		"UnitZero": BossUnitZeroScript,
		"Miku_P1": MikuHatsuneScript,
		"Reimu_P1": ReimuHakureiScript,
		"Marisa_P1": MarisaKirisameScript,
		"Remilia_P1": RemiliaScarletScript,
		"Sasuke_P1": SasukeUchihaScript,
		"Yorha2B_P1": Yorha2BScript,
	}

func _expected_character_ids() -> Dictionary:
	# Nama node roster → character_id yang WAJIB ada di .tres yang di-preload script itu
	return {
		"Viper": &"viper",
		"Bulwark": &"bulwark",
		"Pulsar": &"pulsar",
		"Kage": &"kage",
		"Trigger": &"trigger",
		"UnitZero": &"unit_zero",
		"Miku_P1": &"miku",
		"Reimu_P1": &"reimu",
		"Marisa_P1": &"marisa",
		"Remilia_P1": &"remilia",
		"Sasuke_P1": &"sasuke",
		"Yorha2B_P1": &"yorha_2b",
	}

func _real_cast_names() -> Dictionary:
	# Nama cast yang benar-benar dipancarkan tiap fighter (tres attack_name atau nama
	# ult yang diemit langsung oleh script karakter). Core fighter mengenai cabang named
	# (Blink/Orbital/Supernova/Blossom/BulletHell). Nama ult crossover (WorldIsMine,
	# FantasySeal, FinalMasterSpark, KirinDragon, SpearTheGungnir, PodGravityHammer)
	# sengaja dibiarkan cocok DENGAN TIDAK ADA cabang manapun — ini REGRESSION GUARD
	# untuk blok `if not handled:`; menghapus blok itu HARUS membuat suite ini merah.
	# Catatan: Trigger tidak punya "GunslingerVault"; nama ult aslinya "BulletHellZero"
	# (trigger_bullet_hell.tres). Unit-0 mengarah ke kage_shadow_blossom.tres.
	return {
		"Viper": &"BlinkSlash",
		"Bulwark": &"OrbitalSiegeCannon",
		"Pulsar": &"SupernovaHorizon",
		"Kage": &"ShadowBlossom",
		"Trigger": &"BulletHellZero",
		"UnitZero": &"ShadowBlossom",
		"Miku_P1": &"WorldIsMine",
		"Reimu_P1": &"FantasySeal",
		"Marisa_P1": &"FinalMasterSpark",
		"Remilia_P1": &"SpearTheGungnir",
		"Sasuke_P1": &"KirinDragon",
		"Yorha2B_P1": &"PodGravityHammer",
	}

func _spawn_roster() -> Array[Node]:
	var nodes: Array[Node] = []
	for node_name in _roster_scripts():
		var n: Node = _roster_scripts()[node_name].new()
		n.name = node_name
		add_child(n)
		nodes.append(n)
	return nodes

func _free_roster(nodes: Array[Node]) -> void:
	# free() langsung (bukan queue_free) — semua suite berjalan sinkron dalam satu
	# frame, queue_free belum pernah flush sehingga nama node bentrok antar-suite.
	for n in nodes:
		n.free()

func _test_every_roster_fighter_resolves_profile() -> void:
	var nodes := _spawn_roster()
	var expected_ids := _expected_character_ids()
	for n in nodes:
		var script_name := String(n.get_script().resource_path).get_file()
		var profile: Variant = n.get("vfx_profile")
		_check(profile != null, "%s punya vfx_profile tidak null." % script_name)
		if profile is VfxProfileScript:
			_check(profile.character_id != &"", "%s vfx_profile punya character_id '%s'." % [script_name, profile.character_id])
			_check(profile.primary_color != Color.TRANSPARENT, "%s vfx_profile punya primary_color." % script_name)
			# Mis-wiring: script preloaded dengan .tres fighter LAIN harus gagal di sini
			var expected: StringName = expected_ids.get(n.name, &"")
			_check(profile.character_id == expected, "%s vfx_profile character_id '%s' cocok dengan roster '%s'." % [script_name, profile.character_id, expected])
		else:
			_check(false, "%s vfx_profile bukan VfxProfile." % script_name)

	# Tier 1: VFXManager meresolusikan lewat var vfx_profile eksplisit hasil wiring karakter
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)
	for n in nodes:
		var p: VfxProfile = mgr.get_profile_for(n)
		_check(p != null, "VFXManager meresolusikan profil untuk %s." % n.name)
		if n.get("vfx_profile") is VfxProfileScript:
			_check(p == n.get("vfx_profile"), "VFXManager memakai profil wiring (bukan fallback) untuk %s." % n.name)
	mgr.queue_free()
	_free_roster(nodes)

func _test_roster_tres_loads_and_impact_style_in_range() -> void:
	for id in PROFILE_IDS:
		var path := "res://resources/vfx_profiles/%s.tres" % id
		_check(ResourceLoader.exists(path), "%s.tres ada di disk." % id)
		var res: Resource = ResourceLoader.load(path)
		_check(res is VfxProfileScript, "%s.tres parse sebagai VfxProfile." % id)
		if res is VfxProfileScript:
			_check(res.impact_style >= 0 and res.impact_style <= 5, "%s impact_style %d dalam range ImpactStyle (0-5)." % [id, res.impact_style])

func _test_skill_cast_spawns_effect_for_every_fighter() -> void:
	var nodes := _spawn_roster()
	for n in nodes:
		var mgr: Node2D = VFXManagerScript.new()
		add_child(mgr)
		var before := mgr.get_child_count()
		# Gunakan nama skill generik 'Skill1' — cabang fallback wajib memicu minimal
		# 2 node baru (shockwave + minimal satu node signature) untuk semua fighter
		mgr._on_skill_cast(n, &"Skill1", Vector2(320, 200), 1)
		_check(mgr.get_child_count() >= before + 2, "Skill1 cast oleh %s memunculkan shockwave + node signature (growth %d >= 2)." % [n.name, mgr.get_child_count() - before])
		mgr.queue_free()
	_free_roster(nodes)

func _test_real_cast_names_spawn_effect_for_every_fighter() -> void:
	var nodes := _spawn_roster()
	var cast_names := _real_cast_names()
	for n in nodes:
		var mgr: Node2D = VFXManagerScript.new()
		add_child(mgr)
		var before := mgr.get_child_count()
		var cast_name: StringName = cast_names.get(n.name, &"Skill1")
		mgr._on_skill_cast(n, cast_name, Vector2(320, 200), 1)
		_check(mgr.get_child_count() > before, "Cast '%s' oleh %s memunculkan efek (tidak senyap)." % [cast_name, n.name])
		mgr.queue_free()
	_free_roster(nodes)

func _test_hit_confirmed_uses_profile_colors() -> void:
	var nodes := _spawn_roster()
	var victim := Node2D.new()
	victim.name = "Victim"
	victim.global_position = Vector2(400, 100)
	add_child(victim)
	for n in nodes:
		n.global_position = Vector2(300, 100)
		var mgr: Node2D = VFXManagerScript.new()
		add_child(mgr)
		mgr._on_hit_confirmed(n, victim, {"name": "Skill1", "damage": 120, "chain_level": 3})
		var found_burst := false
		var burst_color := Color.TRANSPARENT
		for child in mgr.get_children():
			if child is VFXImpactBurstScript:
				found_burst = true
				burst_color = child.primary_color
				break
		_check(found_burst, "%s melahirkan VFXImpactBurst saat hit terkonfirmasi." % n.name)
		var expected: VfxProfile = n.get("vfx_profile")
		if found_burst and expected != null:
			_check(burst_color == expected.primary_color, "%s impact burst memakai warna profil (%s)." % [n.name, expected.character_id])
		mgr.queue_free()
	victim.queue_free()
	_free_roster(nodes)

func _test_blocked_hit_spawns_zero_level_impact_burst() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)
	var attacker := Node2D.new()
	attacker.name = "Viper_TestBlock"
	attacker.global_position = Vector2(300, 100)
	var victim := Node2D.new()
	victim.name = "Target_TestBlock"
	victim.global_position = Vector2(400, 100)
	add_child(attacker)
	add_child(victim)
	# Payload blocked persis seperti yang dipancarkan base_mecha.gd:
	# blocked_data["blocked"] = true (key "blocked", bukan "is_blocked")
	mgr._on_hit_confirmed(attacker, victim, {"name": "5L", "damage": 40, "chain_level": 1, "blocked": true})
	var zero_burst: VFXImpactBurstScript = null
	for child in mgr.get_children():
		if child is VFXImpactBurstScript:
			zero_burst = child
			break
	_check(zero_burst != null, "Blocked hit memunculkan VFXImpactBurst.")
	if zero_burst != null:
		_check(zero_burst.intensity_level == 0, "Blocked hit impact burst intensity_level == 0 (bukan hit level penuh).")
	attacker.queue_free()
	victim.queue_free()
	mgr.queue_free()

func _test_unknown_fighter_gets_generic_profile() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)
	var stranger := Node2D.new()
	stranger.name = "TidakDikenal_XYZ"
	add_child(stranger)
	var profile: VfxProfile = mgr.get_profile_for(stranger)
	_check(profile != null, "Fighter tak dikenal tetap mendapat profil (generic).")
	_check(profile.character_id == &"generic", "Fighter tak dikenal memakai profil generic.")

	var victim := Node2D.new()
	victim.name = "TargetDummy"
	victim.global_position = Vector2(400, 100)
	stranger.global_position = Vector2(300, 100)
	add_child(victim)
	var before := mgr.get_child_count()
	mgr._on_hit_confirmed(stranger, victim, {"name": "5L", "damage": 40, "chain_level": 1})
	_check(mgr.get_child_count() > before, "Hit oleh fighter tanpa profil tidak crash dan tetap spawn VFX.")
	victim.queue_free()
	stranger.queue_free()
	mgr.queue_free()

func _test_missing_resource_falls_back_to_generic() -> void:
	var profile: VfxProfile = VfxProfileScript.load_or_generic("res://resources/vfx_profiles/tidak_ada_12345.tres")
	_check(profile != null, "Resource .tres yang hilang jatuh ke profil generic (tidak null).")
	_check(profile.character_id == &"generic", "Fallback .tres rusak/hilang menghasilkan profil generic.")

	# .tres ada di disk tapi BUKAN VfxProfile (mis. PackedScene) → harus generic, tidak crash
	var wrong_type: VfxProfile = VfxProfileScript.load_or_generic("res://scenes/vfx/vfx_energy_slash.tscn")
	_check(wrong_type != null, "Resource non-VfxProfile yang ada tetap menghasilkan profil (tidak null).")
	_check(wrong_type.character_id == &"generic", "Resource non-VfxProfile jatuh ke profil generic.")

func _test_skill_hit_emits_extra_punch_normal_does_not() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)

	var attacker := Node2D.new()
	attacker.name = "Viper_TestPunch"
	var victim := Node2D.new()
	victim.name = "Target_TestPunch"
	attacker.global_position = Vector2(300, 100)
	victim.global_position = Vector2(400, 100)
	add_child(attacker)
	add_child(victim)

	var shake_events: Array = []
	var hitstop_events: Array = []
	var on_shake := func(intensity: float, frames: int):
		shake_events.append({"intensity": intensity, "frames": frames})
	var on_hitstop := func(frames: int):
		hitstop_events.append(frames)

	EventBus.screen_shake_requested.connect(on_shake)
	EventBus.hitstop_requested.connect(on_hitstop)

	# Normal attack (chain_level 1) — TIDAK ada punch ekstra dari VFXManager
	mgr._on_hit_confirmed(attacker, victim, {"name": "5L", "damage": 40, "chain_level": 1})
	var normal_shakes := shake_events.size()
	var normal_hitstops := hitstop_events.size()
	_check(normal_hitstops == 0, "Normal attack tidak memancarkan hitstop_requested ekstra dari VFXManager.")

	# Skill hit (chain_level 3) — punch ekstra
	mgr._on_hit_confirmed(attacker, victim, {"name": "Skill1", "damage": 120, "chain_level": 3})
	_check(hitstop_events.size() > normal_hitstops, "Skill hit memancarkan hitstop_requested ekstra.")
	_check(shake_events.size() > normal_shakes, "Skill hit memancarkan screen_shake_requested ekstra.")

	# Ultimate hit (chain_level 4) — punch lebih besar dari skill
	var skill_hitstop_frames: int = int(hitstop_events[hitstop_events.size() - 1])
	mgr._on_hit_confirmed(attacker, victim, {"name": "Ultimate", "damage": 380, "chain_level": 4})
	var ult_hitstop_frames: int = int(hitstop_events[hitstop_events.size() - 1])
	_check(ult_hitstop_frames >= skill_hitstop_frames, "Ultimate hit punch >= skill hit punch (%d >= %d)." % [ult_hitstop_frames, skill_hitstop_frames])

	# Putus koneksi EventBus agar suites lain di proses yang sama tidak menerima emisi nyasar
	EventBus.screen_shake_requested.disconnect(on_shake)
	EventBus.hitstop_requested.disconnect(on_hitstop)

	attacker.queue_free()
	victim.queue_free()
	mgr.queue_free()
