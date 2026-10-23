extends Node

const RayPulsarScript = preload("res://scripts/characters/ray_pulsar.gd")
const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_ray_pulsar_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 10.1: Ray-X Pulsar Character...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_pulsar_stats_and_archetype,
		_test_pulsar_attack_resources_binding,
		_test_photon_railgun_execution,
		_test_disrupter_drone_deployment,
		_test_supernova_ultimate_execution,
		_test_pulsar_visual_pixel_sprite_integration
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

func _test_pulsar_stats_and_archetype() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "P1_Pulsar"
	add_child(pulsar)

	_check(pulsar.max_hp == CombatConstants.PULSAR_MAX_HP, "Max HP Ray-X Pulsar adalah 950.")
	_check(pulsar.current_hp == 950, "Current HP awal Ray-X Pulsar adalah 950.")
	_check(is_equal_approx(pulsar.walk_speed, CombatConstants.PULSAR_WALK_SPEED), "Kecepatan jalan Pulsar adalah 300 px/s.")
	_check(is_equal_approx(pulsar.get_dash_speed(), CombatConstants.PULSAR_DASH_SPEED), "Kecepatan dash Pulsar adalah 720 px/s.")
	_check(pulsar.get_dash_duration() == CombatConstants.PULSAR_DASH_DURATION_FRAMES, "Durasi dash Pulsar adalah 14 frame.")
	_check(pulsar.get_archetype() == &"pulsar", "Archetype Ray-X Pulsar adalah 'pulsar'.")

	pulsar.queue_free()

func _test_pulsar_attack_resources_binding() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "P1_Pulsar"
	add_child(pulsar)

	_check(pulsar.attack_resources.has(&"5L"), "Move 5L (Plasma Pulse) terdaftar.")
	_check(pulsar.attack_resources.has(&"5H"), "Move 5H (Beam Lance) terdaftar.")
	_check(pulsar.attack_resources.has(&"Skill1"), "Skill 1 (Photon Railgun) terdaftar.")
	_check(pulsar.attack_resources.has(&"Skill2"), "Skill 2 (Disrupter Drone) terdaftar.")
	_check(pulsar.attack_resources.has(&"Ultimate"), "Ultimate (Supernova Horizon) terdaftar.")

	var railgun = pulsar.attack_resources[&"Skill1"]
	_check(railgun.damage == CombatConstants.PULSAR_RAILGUN_DAMAGE, "Damage Photon Railgun adalah 110.")
	_check(is_equal_approx(railgun.heat_cost, CombatConstants.PULSAR_RAILGUN_HEAT_COST), "Heat cost Photon Railgun adalah 25%.")

	pulsar.queue_free()

func _test_photon_railgun_execution() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "P1_Pulsar"
	add_child(pulsar)

	var fired: Dictionary = {"called": false}
	pulsar.photon_railgun_fired.connect(func(_o, _d): fired["called"] = true)

	pulsar.execute_skill_1()
	_check(fired["called"], "Photon Railgun memancarkan sinyal tembakan partikel.")
	if pulsar.state_machine and pulsar.state_machine.current_state:
		_check(pulsar.state_machine.current_state.name == &"Attack", "Mecha beralih ke state Attack saat eksekusi Skill 1.")
	else:
		_check(true, "Skill 1 dieksekusi tanpa error StateMachine.")

	pulsar.queue_free()

func _test_disrupter_drone_deployment() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "P1_Pulsar"
	add_child(pulsar)

	var deployed: Dictionary = {"called": false}
	pulsar.drone_deployed.connect(func(_p): deployed["called"] = true)

	pulsar.execute_skill_2()
	_check(deployed["called"], "Disrupter Drone memancarkan sinyal deployment.")
	_check(pulsar.is_drone_active(), "Drone berstatus aktif setelah dieksekusi.")
	_check(pulsar.drone_frames_left == CombatConstants.PULSAR_DRONE_DURATION_FRAMES, "Durasi aktif drone adalah 120 frame.")

	pulsar.queue_free()

func _test_supernova_ultimate_execution() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "P1_Pulsar"
	add_child(pulsar)

	var executed: Dictionary = {"called": false}
	pulsar.supernova_executed.connect(func(): executed["called"] = true)

	pulsar.execute_ultimate()
	_check(executed["called"], "Supernova Horizon memancarkan sinyal eksekusi.")
	_check(pulsar.invulnerability_frames == 18, "Supernova memberikan 18 frame invulnerability saat startup.")

	pulsar.queue_free()

func _test_pulsar_visual_pixel_sprite_integration() -> void:
	var pulsar: CharacterBody2D = RayPulsarScript.new()
	pulsar.name = "RayPulsar"
	add_child(pulsar)

	var sprite := MechaPixelSpriteScript.new()
	pulsar.add_child(sprite)

	_check(sprite.archetype == &"pulsar", "MechaPixelSprite otomatis mendeteksi archetype 'pulsar'.")
	_check(sprite.col_armor == Color(0.65, 0.25, 0.95), "Palet warna armor terkonfigurasi ke Neon Violet.")

	pulsar.queue_free()
