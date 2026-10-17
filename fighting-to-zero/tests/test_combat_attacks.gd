extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunState = preload("res://scripts/combat/fsm/hitstun_state.gd")

## Automated Test Suite untuk Story 1.4:
## Base Normal Attacks & Frame-Based Hit/Hurtbox Collision

var log_file: FileAccess = null

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_combat_attacks_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 1.4...")
	_log("==================================================")

	var total_tests: int = 0
	var passed_tests: int = 0

	# 1. Test Frame Data Constants (AC: 1)
	total_tests += 1
	if _test_frame_data_constants():
		passed_tests += 1

	# 2. Test Hitbox & Hurtbox Physics Layers (AC: 2)
	total_tests += 1
	if _test_collision_matrix():
		passed_tests += 1

	# 3. Test AttackState Frame Lifecycle & Hitbox Window (AC: 1, 2)
	total_tests += 1
	if _test_attack_state_lifecycle():
		passed_tests += 1

	# 4. Test Hit Confirmation, Damage & Hitstun Recovery (AC: 3, 4)
	total_tests += 1
	if _test_hit_confirmation_and_hitstun():
		passed_tests += 1

	# 5. Test Attack Triggering from Actionable States (AC: 1, 4)
	total_tests += 1
	if _test_attack_fsm_integration():
		passed_tests += 1

	_log("==================================================")
	_log("[TEST RUNNER] Hasil Pengujian: %d / %d Lulus" % [passed_tests, total_tests])
	_log("==================================================")

	if passed_tests == total_tests:
		_log(">>> SEMUA TES STORY 1.4 BERHASIL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(0)
	else:
		_log(">>> BEBERAPA TES GAGAL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(1)

func _test_frame_data_constants() -> bool:
	_log("\n--- Test 1: Frame Data Constants ---")
	assert("LIGHT_ATTACK" in CombatConstants, "CombatConstants harus mendefinisikan LIGHT_ATTACK")
	assert("HEAVY_ATTACK" in CombatConstants, "CombatConstants harus mendefinisikan HEAVY_ATTACK")

	var la: Dictionary = CombatConstants.LIGHT_ATTACK
	assert(la["startup"] == 5, "Light Attack startup harus 5 frame")
	assert(la["active"] == 3, "Light Attack active harus 3 frame")
	assert(la["recovery"] == 8, "Light Attack recovery harus 8 frame")
	assert(la["damage"] == 40, "Light Attack damage harus 40")
	assert(la["hitstun"] == 14, "Light Attack hitstun harus 14 frame")

	var ha: Dictionary = CombatConstants.HEAVY_ATTACK
	assert(ha["startup"] == 10, "Heavy Attack startup harus 10 frame")
	assert(ha["active"] == 4, "Heavy Attack active harus 4 frame")
	assert(ha["recovery"] == 16, "Heavy Attack recovery harus 16 frame")
	assert(ha["damage"] == 90, "Heavy Attack damage harus 90")
	assert(ha["hitstun"] == 22, "Heavy Attack hitstun harus 22 frame")

	_log(" [PASS] Parameter frame data Light dan Heavy Attack terverifikasi presisi.")
	return true

func _test_collision_matrix() -> bool:
	_log("\n--- Test 2: Hitbox & Hurtbox Physics Layers ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaLayersTest"
	add_child(mecha)

	assert(mecha.hurtbox != null, "BaseMecha harus memiliki komponen Hurtbox Area2D")
	assert(mecha.hitbox != null, "BaseMecha harus memiliki komponen Hitbox Area2D")

	# Layer 2 = Hurtbox (bitmask 2)
	assert(mecha.hurtbox.collision_layer == (1 << (CombatConstants.LAYER_HURTBOX - 1)), "Hurtbox collision_layer harus Layer 2 (bitmask 2)")
	assert(mecha.hurtbox.collision_mask == 0, "Hurtbox tidak boleh memantau layer lain (mask 0)")

	# Layer 3 = StrikeHitbox (bitmask 4)
	assert(mecha.hitbox.collision_layer == (1 << (CombatConstants.LAYER_STRIKE_HITBOX - 1)), "Hitbox collision_layer harus Layer 3 (bitmask 4)")
	assert(mecha.hitbox.collision_mask == (1 << (CombatConstants.LAYER_HURTBOX - 1)), "Hitbox collision_mask harus mendeteksi Layer 2 Hurtbox")

	mecha.queue_free()
	_log(" [PASS] Layer 2D physics untuk Hitbox dan Hurtbox sesuai spesifikasi arsitektur.")
	return true

func _test_attack_state_lifecycle() -> bool:
	_log("\n--- Test 3: AttackState Frame Lifecycle & Hitbox Window ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaAttackLifecycle"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	add_child(mecha)

	attack.setup_attack(CombatConstants.LIGHT_ATTACK)
	fsm.change_state(&"Attack")

	# Startup frames (0 s/d 4): Hitbox harus non-aktif
	for f in range(CombatConstants.LIGHT_ATTACK["startup"]):
		assert(mecha.is_hitbox_active() == false, "Hitbox harus non-aktif selama startup frame %d" % f)
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Active frames (5 s/d 7): Hitbox harus aktif
	for f in range(CombatConstants.LIGHT_ATTACK["active"]):
		assert(mecha.is_hitbox_active() == true, "Hitbox harus aktif selama active frame %d" % f)
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Recovery frames (8 s/d 15): Hitbox harus kembali non-aktif
	for f in range(CombatConstants.LIGHT_ATTACK["recovery"] - 1):
		assert(mecha.is_hitbox_active() == false, "Hitbox harus non-aktif selama recovery frame %d" % f)
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Frame terakhir recovery -> transisi kembali ke Idle
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(fsm.current_state.name == "Idle", "Setelah total durasi serangan, harus kembali ke IdleState")

	mecha.queue_free()
	_log(" [PASS] Siklus hidup frame data startup/active/recovery dan aktivasi hitbox eksklusif terverifikasi.")
	return true

func _test_hit_confirmation_and_hitstun() -> bool:
	_log("\n--- Test 4: Hit Confirmation, Damage & Hitstun Recovery ---")
	var attacker := BaseMecha.new()
	attacker.name = "Attacker"

	var victim := BaseMecha.new()
	victim.name = "Victim"

	var victim_fsm := StateMachine.new()
	victim_fsm.name = "StateMachine"
	victim.add_child(victim_fsm)

	var victim_idle := IdleState.new()
	victim_idle.name = "Idle"
	victim_fsm.add_child(victim_idle)

	var victim_hitstun := HitstunState.new()
	victim_hitstun.name = "Hitstun"
	victim_fsm.add_child(victim_hitstun)

	add_child(attacker)
	add_child(victim)

	var initial_hp: int = victim.current_hp
	var hit_tracker: Dictionary = {
		"received": false,
		"damage": 0
	}

	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(func(_att, _vic, hit_data):
			hit_tracker["received"] = true
			if hit_data is Dictionary and "damage" in hit_data:
				hit_tracker["damage"] = hit_data["damage"]
		)
	else:
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.hit_confirmed.connect(func(_att, _vic, hit_data):
				hit_tracker["received"] = true
				if hit_data is Dictionary and "damage" in hit_data:
					hit_tracker["damage"] = hit_data["damage"]
			)

	# Eksekusi take_hit pada victim dengan parameter Light Attack
	victim.take_hit(attacker, CombatConstants.LIGHT_ATTACK)

	assert(victim.current_hp == initial_hp - CombatConstants.LIGHT_ATTACK["damage"], "HP victim harus berkurang 40 poin")
	assert(victim_fsm.current_state.name == "Hitstun", "Victim harus masuk ke HitstunState")
	assert(hit_tracker["received"] == true, "EventBus harus memancarkan sinyal hit_confirmed")
	assert(hit_tracker["damage"] == 40, "Damage yang terpancar pada hit_confirmed harus 40")

	# Simulasikan durasi hitstun 14 frame
	for f in range(CombatConstants.LIGHT_ATTACK["hitstun"] - 1):
		assert(victim_fsm.current_state.name == "Hitstun", "Victim harus terkunci di Hitstun pada frame %d" % f)
		victim_fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Frame ke-14: pulih kembali ke IdleState
	victim_fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(victim_fsm.current_state.name == "Idle", "Setelah 14 frame hitstun, victim harus kembali ke IdleState")

	attacker.queue_free()
	victim.queue_free()
	_log(" [PASS] Pengurangan HP, transisi Hitstun, emisi EventBus, dan pemulihan ke Idle terverifikasi.")
	return true

func _test_attack_fsm_integration() -> bool:
	_log("\n--- Test 5: Attack Triggering from Actionable States ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaAttackInput"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var walk := WalkState.new()
	walk.name = "Walk"
	fsm.add_child(walk)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	add_child(mecha)

	assert(InputMap.has_action("attack_light"), "InputMap harus memiliki action 'attack_light'")
	assert(InputMap.has_action("attack_heavy"), "InputMap harus memiliki action 'attack_heavy'")

	# Simulasikan request light attack
	mecha.request_attack(CombatConstants.LIGHT_ATTACK)
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(fsm.current_state.name == "Attack", "Mecha harus bertransisi ke Attack dari Idle")

	mecha.queue_free()
	_log(" [PASS] Input attack terdaftar dan memicu transisi ke AttackState secara deterministik.")
	return true
