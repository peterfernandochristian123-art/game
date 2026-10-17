extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const JumpState = preload("res://scripts/combat/fsm/jump_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")

## Automated Test Suite untuk Story 1.1:
## Autoload Infrastructure, Combat Constants, Hierarchical State Machine & Movement

var log_file: FileAccess = null

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 1.1...")
	_log("==================================================")
	
	var total_tests: int = 0
	var passed_tests: int = 0

	# 1. Test Combat Constants
	total_tests += 1
	if _test_combat_constants():
		passed_tests += 1

	# 2. Test Autoloads (EventBus & InputBuffer)
	total_tests += 1
	if _test_autoloads():
		passed_tests += 1

	# 3. Test Physics Collision Layers
	total_tests += 1
	if _test_collision_layers():
		passed_tests += 1

	# 4. Test StateMachine Lifecycle & Safe Fallback
	total_tests += 1
	if _test_state_machine_logic():
		passed_tests += 1

	# 5. Test TestArena Scene Composition
	total_tests += 1
	if _test_test_arena_scene():
		passed_tests += 1

	_log("==================================================")
	_log("[TEST RUNNER] Hasil Pengujian: %d / %d Lulus" % [passed_tests, total_tests])
	_log("==================================================")

	if passed_tests == total_tests:
		_log(">>> SEMUA TES STORY 1.1 BERHASIL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(0)
	else:
		_log(">>> BEBERAPA TES GAGAL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(1)

func _test_combat_constants() -> bool:
	_log("\n--- Test 1: Combat Constants ---")
	assert(CombatConstants.TICK_RATE == 60, "TICK_RATE harus 60")
	assert(CombatConstants.DEFAULT_WALK_SPEED == 280.0, "DEFAULT_WALK_SPEED harus 280.0")
	assert(CombatConstants.JUMP_VELOCITY == -420.0, "JUMP_VELOCITY harus -420.0")
	assert(CombatConstants.GRAVITY == 980.0, "GRAVITY harus 980.0")
	assert(CombatConstants.ARENA_LEFT_BOUND == 64.0, "ARENA_LEFT_BOUND harus 64.0")
	assert(CombatConstants.ARENA_RIGHT_BOUND == 1344.0, "ARENA_RIGHT_BOUND harus 1344.0")
	_log(" [PASS] Seluruh nilai CombatConstants terverifikasi sesuai spesifikasi.")
	return true

func _test_autoloads() -> bool:
	_log("\n--- Test 2: Autoloads ---")
	var bus := get_node_or_null("/root/EventBus")
	assert(bus != null, "EventBus autoload harus terdaftar di /root/EventBus")
	
	var buffer := get_node_or_null("/root/InputBuffer")
	assert(buffer != null, "InputBuffer autoload harus terdaftar di /root/InputBuffer")
	
	# Test buffer functionality
	buffer.clear_buffer()
	buffer.buffer_action(&"jump", Vector2.UP)
	assert(buffer.has_action(&"jump"), "InputBuffer harus mendeteksi input jump yang baru dibuffer")
	var consumed: bool = buffer.consume_action(&"jump")
	assert(consumed == true, "InputBuffer harus berhasil mengonsumsi action jump")
	assert(buffer.has_action(&"jump") == false, "InputBuffer tidak boleh lagi memiliki action jump setelah dikonsumsi")
	
	_log(" [PASS] Autoload EventBus dan InputBuffer berfungsi dengan benar.")
	return true

func _test_collision_layers() -> bool:
	_log("\n--- Test 3: Physics Collision Layers ---")
	var l1 = ProjectSettings.get_setting("layer_names/2d_physics/layer_1")
	var l2 = ProjectSettings.get_setting("layer_names/2d_physics/layer_2")
	var l3 = ProjectSettings.get_setting("layer_names/2d_physics/layer_3")
	var l4 = ProjectSettings.get_setting("layer_names/2d_physics/layer_4")
	var l5 = ProjectSettings.get_setting("layer_names/2d_physics/layer_5")

	assert(l1 == "World", "Layer 1 harus 'World', dapat: " + str(l1))
	assert(l2 == "Hurtbox", "Layer 2 harus 'Hurtbox', dapat: " + str(l2))
	assert(l3 == "StrikeHitbox", "Layer 3 harus 'StrikeHitbox', dapat: " + str(l3))
	assert(l4 == "GrabHitbox", "Layer 4 harus 'GrabHitbox', dapat: " + str(l4))
	assert(l5 == "LedgeSensor", "Layer 5 harus 'LedgeSensor', dapat: " + str(l5))
	_log(" [PASS] Layer names 2D physics terkonfigurasi sesuai matrix arsitektur.")
	return true

func _test_state_machine_logic() -> bool:
	_log("\n--- Test 4: State Machine Lifecycle & Safe Fallback ---")
	var mecha := BaseMecha.new()
	mecha.name = "TestMecha"
	
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)
	
	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)
	
	var walk := WalkState.new()
	walk.name = "Walk"
	fsm.add_child(walk)

	var jump := JumpState.new()
	jump.name = "Jump"
	fsm.add_child(jump)

	var fall := FallState.new()
	fall.name = "Fall"
	fsm.add_child(fall)
	
	add_child(mecha)

	assert(fsm.current_state != null, "State awal harus terinisialisasi")
	assert(fsm.current_state.name == "Idle", "State awal harus Idle")

	# Test transisi ke Walk
	fsm.change_state(&"Walk")
	assert(fsm.current_state.name == "Walk", "State harus bertransisi ke Walk")

	# Test transisi ke Jump
	fsm.change_state(&"Jump")
	assert(fsm.current_state.name == "Jump", "State harus bertransisi ke Jump")
	assert(mecha.velocity.y == mecha.jump_velocity, "Velocity Y mecha harus diset ke jump_velocity saat enter JumpState")

	# Test transisi ke Fall
	fsm.change_state(&"Fall")
	assert(fsm.current_state.name == "Fall", "State harus bertransisi ke Fall")

	# Test fallback safe degradation untuk state yang tidak terdaftar
	fsm.change_state(&"InvalidStateThatDoesNotExist")
	assert(fsm.current_state.name == "Idle", "FSM harus fallback otomatis ke Idle saat target state tidak terdaftar")

	mecha.queue_free()
	_log(" [PASS] FSM lifecycle, transisi gerak, dan safe degradation terverifikasi sukses.")
	return true

func _test_test_arena_scene() -> bool:
	_log("\n--- Test 5: TestArena Scene Composition ---")
	var arena_scene = load("res://scenes/test_arena.tscn")
	assert(arena_scene != null, "Scene test_arena.tscn harus dapat dimuat")
	
	var arena_instance = arena_scene.instantiate()
	assert(arena_instance != null, "Instance test_arena harus berhasil dibuat")
	
	var player = arena_instance.get_node_or_null("Player")
	assert(player != null, "Node Player harus ada di test_arena")
	assert(player is BaseMecha, "Node Player harus meng-extend BaseMecha")
	
	var fsm = player.get_node_or_null("StateMachine")
	assert(fsm != null, "Node StateMachine harus ada sebagai child Player")
	assert(fsm.has_node("Idle"), "StateMachine harus memiliki child Idle state")
	assert(fsm.has_node("Walk"), "StateMachine harus memiliki child Walk state")
	assert(fsm.has_node("Jump"), "StateMachine harus memiliki child Jump state")
	assert(fsm.has_node("Fall"), "StateMachine harus memiliki child Fall state")
	
	arena_instance.free()
	_log(" [PASS] Scene test_arena.tscn terverifikasi menggunakan hierarki BaseMecha dan FSM.")
	return true
