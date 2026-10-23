extends Node

const PhantomKageScript = preload("res://scripts/characters/phantom_kage.gd")
const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")

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

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_phantom_kage_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 13.1: Phantom-9 Kage Character...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_kage_stats_and_archetype,
		_test_kage_attack_resources_binding,
		_test_kage_stance_shift_mechanics,
		_test_kage_skills_and_ultimate_execution,
		_test_kage_visual_pixel_sprite_integration,
		_test_kage_fighter_factory_integration
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			passed += 1
			_log(" [LULUS]")

	_log("\n==================================================")
	_log("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	_log("==================================================")

	if log_file:
		log_file.close()

	if passed == tests.size():
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _test_kage_stats_and_archetype() -> void:
	var kage: CharacterBody2D = PhantomKageScript.new()
	kage.name = "P1_Kage"
	add_child(kage)

	_check(kage.max_hp == CombatConstants.KAGE_MAX_HP, "Max HP Phantom-9 Kage adalah 920.")
	_check(kage.current_hp == 920, "Current HP awal Phantom-9 Kage adalah 920.")
	_check(is_equal_approx(kage.walk_speed, CombatConstants.KAGE_WALK_SPEED), "Kecepatan jalan Kage adalah 320 px/s.")
	_check(is_equal_approx(kage.get_dash_speed(), CombatConstants.KAGE_DASH_SPEED), "Kecepatan dash Kage adalah 780 px/s.")
	_check(kage.get_dash_duration() == CombatConstants.KAGE_DASH_DURATION_FRAMES, "Durasi dash Kage adalah 14 frame.")
	_check(kage.get_archetype() == &"kage", "Archetype Phantom-9 Kage adalah 'kage'.")
	_check(kage.current_stance == &"kenjutsu", "Stance awal Kage adalah 'kenjutsu'.")

	kage.queue_free()

func _test_kage_attack_resources_binding() -> void:
	var kage: CharacterBody2D = PhantomKageScript.new()
	kage.name = "P1_Kage"
	add_child(kage)

	_check(kage.attack_resources.has(&"5L"), "Move 5L (Kenjutsu Slash) terdaftar.")
	_check(kage.attack_resources.has(&"5H"), "Move 5H (Kenjutsu Cleave) terdaftar.")
	_check(kage.attack_resources.has(&"Skill1"), "Skill 1 (Stance Shift & Feint) terdaftar.")
	_check(kage.attack_resources.has(&"Skill2"), "Skill 2 (Iaido Crescent) terdaftar.")
	_check(kage.attack_resources.has(&"Ultimate"), "Ultimate (Tsukuyomi Shadow Blossom) terdaftar.")

	var slash = kage.attack_resources[&"5L"]
	_check(slash.damage == 60, "Damage Katana Slash adalah 60.")

	var iaido = kage.attack_resources[&"Skill2"]
	_check(iaido.damage == CombatConstants.KAGE_IAIDO_DAMAGE, "Damage Iaido Crescent adalah 120.")
	_check(is_equal_approx(iaido.heat_cost, CombatConstants.KAGE_IAIDO_HEAT_COST), "Heat cost Iaido Crescent adalah 25%.")

	var ulti = kage.attack_resources[&"Ultimate"]
	_check(ulti.damage == CombatConstants.KAGE_SHADOW_BLOSSOM_DAMAGE, "Damage Shadow Blossom adalah 420.")

	kage.queue_free()

func _test_kage_stance_shift_mechanics() -> void:
	var kage: CharacterBody2D = PhantomKageScript.new()
	kage.name = "P1_Kage"
	add_child(kage)

	var stance_history: Array[StringName] = []
	kage.stance_changed.connect(func(st): stance_history.append(st))

	# Eksekusi Skill 1 untuk beralih ke Shinobi
	kage.execute_skill_1()
	_check(kage.current_stance == &"shinobi", "Kage bertransisi ke Stance 'shinobi'.")
	_check(stance_history.size() == 1 and stance_history[0] == &"shinobi", "Sinyal stance_changed memancarkan 'shinobi'.")
	_check(kage.invulnerability_frames == CombatConstants.KAGE_STANCE_FEINT_FRAMES, "Stance Shift memberikan 12 frame invulnerability.")

	# Pastikan jurus 5L, 5H, dan Skill2 diperbarui ke kit Shinobi
	var kunai = kage.attack_resources[&"5L"]
	_check(kunai.damage == 50, "Move 5L Shinobi adalah Kunai Poke (Damage 50).")
	var flurry = kage.attack_resources[&"5H"]
	_check(flurry.damage == 85, "Move 5H Shinobi adalah Kunai Flurry (Damage 85).")
	var storm = kage.attack_resources[&"Skill2"]
	_check(storm.damage == CombatConstants.KAGE_SHURIKEN_STORM_DAMAGE, "Skill 2 Shinobi adalah Shuriken Storm (Damage 105).")

	# Eksekusi Skill 1 lagi untuk kembali ke Kenjutsu
	kage.execute_skill_1()
	_check(kage.current_stance == &"kenjutsu", "Kage bertransisi kembali ke Stance 'kenjutsu'.")
	_check(stance_history.size() == 2 and stance_history[1] == &"kenjutsu", "Sinyal stance_changed memancarkan 'kenjutsu'.")

	var katana_slash = kage.attack_resources[&"5L"]
	_check(katana_slash.damage == 60, "Move 5L kembali ke Katana Slash (Damage 60).")

	kage.queue_free()

func _test_kage_skills_and_ultimate_execution() -> void:
	var kage: CharacterBody2D = PhantomKageScript.new()
	kage.name = "P1_Kage"
	add_child(kage)

	var events: Dictionary = {
		"iaido": false,
		"shuriken": false,
		"blossom": false
	}

	kage.iaido_strike_executed.connect(func(): events["iaido"] = true)
	kage.shuriken_storm_thrown.connect(func(): events["shuriken"] = true)
	kage.shadow_blossom_executed.connect(func(): events["blossom"] = true)

	# 1. Eksekusi Skill 2 pada Kenjutsu
	kage.execute_skill_2()
	_check(events["iaido"], "Kenjutsu Skill 2 memancarkan iaido_strike_executed.")
	_check(not events["shuriken"], "Shuriken storm tidak terpanggil pada Kenjutsu.")

	# 2. Beralih ke Shinobi dan eksekusi Skill 2
	kage.set_stance(&"shinobi")
	kage.execute_skill_2()
	_check(events["shuriken"], "Shinobi Skill 2 memancarkan shuriken_storm_thrown.")

	# 3. Eksekusi Ultimate
	kage.execute_ultimate()
	_check(events["blossom"], "Tsukuyomi Shadow Blossom memancarkan shadow_blossom_executed.")
	_check(kage.invulnerability_frames == 16, "Ultimate memberikan 16 frame invulnerability startup.")

	kage.queue_free()

func _test_kage_visual_pixel_sprite_integration() -> void:
	var kage: CharacterBody2D = PhantomKageScript.new()
	kage.name = "PhantomKage"
	add_child(kage)

	var sprite := MechaPixelSpriteScript.new()
	kage.add_child(sprite)

	_check(sprite.archetype == &"kage", "MechaPixelSprite otomatis mendeteksi archetype 'kage'.")
	_check(sprite.col_armor == Color(0.95, 0.15, 0.25), "Palet warna armor terkonfigurasi ke Crimson Red.")

	kage.queue_free()

func _test_kage_fighter_factory_integration() -> void:
	_check(FighterFactoryScript.get_roster_count() == 4, "Roster FighterFactory kini berisi 4 petarung.")
	
	var info = FighterFactoryScript.get_character_info(&"kage")
	_check(info["id"] == &"kage", "Info karakter Kage ditemukan di Roster.")
	_check(info["name"] == "Phantom-9 \"Kage\"", "Nama karakter terdaftar dengan tepat.")
	_check(info["hp"] == 920, "HP terdaftar di info roster adalah 920.")

	var fighter = FighterFactoryScript.create_fighter(&"kage", 1)
	_check(fighter != null, "FighterFactory berhasil menginstansiasi Kage.")
	_check(fighter.name == "Kage_P1", "Nama node fighter P1 adalah Kage_P1.")
	_check(fighter is PhantomKageScript, "Instance mecha bertipe PhantomKage.")
	_check(fighter.get_archetype() == &"kage", "Archetype mecha adalah 'kage'.")

	fighter.queue_free()
