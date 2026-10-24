extends Node

## Test Suite untuk Kurogane Trigger (Cyber-Gunslinger), Palette Swatches, & Dramatic Finish

const KuroganeTriggerScript = preload("res://scripts/characters/kurogane_trigger.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")
const VFXDramaticFinishScript = preload("res://scripts/visual/vfx_dramatic_finish.gd")

var _failed: bool = false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		print("   [FAIL] " + msg)
	else:
		print("   [PASS] " + msg)

func _ready() -> void:
	print("==================================================")
	print("[TEST RUNNER] Memulai pengujian Kurogane Trigger & Features...")
	print("==================================================")

	var tests: Array[Callable] = [
		_test_trigger_stats_and_archetype,
		_test_trigger_attack_resources,
		_test_trigger_skills_execution,
		_test_fighter_factory_trigger_roster,
		_test_palette_swatches,
		_test_dramatic_finish_banner
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		print("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			print(" [GAGAL]")
		else:
			passed += 1
			print(" [LULUS]")

	print("\n==================================================")
	print("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	print("==================================================")
	get_tree().quit(0 if passed == tests.size() else 1)

func _test_trigger_stats_and_archetype() -> void:
	var trigger: BaseMecha = KuroganeTriggerScript.new()
	trigger.name = "P1_Trigger"
	add_child(trigger)

	_check(trigger.get_archetype() == &"trigger", "Archetype mecha adalah 'trigger'.")
	_check(trigger.max_hp == 940, "HP Kurogane Trigger bernilai 940.")
	_check(trigger.walk_speed == 340.0, "Kecepatan jalan bernilai 340.0 px/s.")
	_check(trigger.get_dash_speed() == 820.0, "Kecepatan dash bernilai 820.0 px/s.")
	_check(trigger.get_dash_duration() == 12, "Durasi dash bernilai 12 frames.")

	trigger.queue_free()

func _test_trigger_attack_resources() -> void:
	var trigger: BaseMecha = KuroganeTriggerScript.new()
	add_child(trigger)

	_check(trigger.attack_resources.has(&"5L"), "Resource serangan 5L terikat.")
	_check(trigger.attack_resources.has(&"5H"), "Resource serangan 5H terikat.")
	_check(trigger.attack_resources.has(&"Skill1"), "Resource serangan Skill 1 (Ricochet) terikat.")
	_check(trigger.attack_resources.has(&"Skill2"), "Resource serangan Skill 2 (Gunslinger Roll) terikat.")
	_check(trigger.attack_resources.has(&"Ultimate"), "Resource serangan Ultimate (Bullet Hell Zero) terikat.")

	trigger.queue_free()

func _test_trigger_skills_execution() -> void:
	var trigger: KuroganeTrigger = KuroganeTriggerScript.new()
	add_child(trigger)

	var events: Dictionary = {
		"ricochet": false,
		"roll": false,
		"ult": false
	}

	trigger.ricochet_shot_fired.connect(func(_pos, _dir): events["ricochet"] = true)
	trigger.execute_skill_1()
	_check(events["ricochet"], "Skill 1 menembakkan ricochet projectile.")

	trigger.gunslinger_roll_started.connect(func(_dir): events["roll"] = true)
	trigger.execute_skill_2()
	_check(events["roll"], "Skill 2 memicu evasive gunslinger roll.")
	_check(trigger.invulnerability_frames > 0, "Skill 2 memberikan I-Frames selama roll.")

	trigger.bullet_hell_executed.connect(func(): events["ult"] = true)
	trigger.execute_ultimate()
	_check(events["ult"], "Ultimate Bullet Hell Zero berhasil dieksekusi.")

	trigger.queue_free()

func _test_fighter_factory_trigger_roster() -> void:
	var info = FighterFactoryScript.get_character_info(&"trigger")
	_check(info["id"] == &"trigger", "Info karakter Trigger terdaftar di Roster.")
	_check(info["name"] == "Kurogane \"Trigger\"", "Nama petarung terdaftar Kurogane Trigger.")
	_check(info["hp"] == 940, "HP di roster terdaftar 940.")

	var fighter = FighterFactoryScript.create_fighter(&"trigger", 1)
	_check(fighter != null, "FighterFactory berhasil menciptakan instance Trigger.")
	_check(fighter.name == "Trigger_P1", "Nama node adalah Trigger_P1.")
	_check(fighter is KuroganeTriggerScript, "Fighter bertipe KuroganeTriggerScript.")
	fighter.queue_free()

func _test_palette_swatches() -> void:
	var sprite := MechaPixelSpriteScript.new()
	sprite.archetype = &"trigger"
	add_child(sprite)

	sprite.set_palette_index(0) # Default
	_check(sprite.col_armor == Color(0.92, 0.62, 0.15), "Palette 0 (Default) berwarna Amber Gold.")

	sprite.set_palette_index(1) # Void Shadow
	_check(sprite.col_armor == Color(0.20, 0.22, 0.28), "Palette 1 (Void Shadow) berwarna Midnight Noir.")

	sprite.set_palette_index(2) # Monarch Gold
	_check(sprite.col_armor == Color(0.92, 0.90, 0.85), "Palette 2 (Monarch Gold) berwarna Ivory Marshal.")

	sprite.set_palette_index(3) # Cyber Neon
	_check(sprite.col_armor == Color(0.15, 0.92, 0.80), "Palette 3 (Cyber Neon) berwarna Turquoise.")

	_check(MatchConfigScript.PALETTE_NAMES.size() == 4, "MatchConfig menyediakan 4 nama palet warna.")
	sprite.queue_free()

func _test_dramatic_finish_banner() -> void:
	var finish_layer := VFXDramaticFinishScript.new()
	finish_layer.setup_finish(1, &"ko")
	add_child(finish_layer)
	_check(finish_layer != null, "VFXDramaticFinish berhasil diinstansiasi.")
	_check(finish_layer.layer == 120, "CanvasLayer bernilai 120 untuk prioritas sinematik.")
	finish_layer.queue_free()
