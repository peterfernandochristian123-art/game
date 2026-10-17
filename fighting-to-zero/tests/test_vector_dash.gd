extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const JumpState = preload("res://scripts/combat/fsm/jump_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")
const DashState = preload("res://scripts/combat/fsm/dash_state.gd")
const AirDashState = preload("res://scripts/combat/fsm/air_dash_state.gd")

## Automated Test Suite untuk Story 1.2:
## 8-Way Thruster Vector Dash System

var log_file: FileAccess = null

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_dash_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 1.2...")
	_log("==================================================")

	var total_tests: int = 0
	var passed_tests: int = 0

	# 1. Test 8-Way Vector Resolution & Fallbacks (AC: 1)
	total_tests += 1
	if _test_vector_resolution():
		passed_tests += 1

	# 2. Test Ground Dash Execution, Speed & Duration (AC: 2, 4)
	total_tests += 1
	if _test_ground_dash_execution():
		passed_tests += 1

	# 3. Test Air Dash Execution & Single-use Constraint (AC: 2, 3)
	total_tests += 1
	if _test_air_dash_execution():
		passed_tests += 1

	# 4. Test Cooldown Window (AC: 4)
	total_tests += 1
	if _test_dash_cooldown():
		passed_tests += 1

	# 5. Test FSM Transitions & Scene Composition (AC: 5)
	total_tests += 1
	if _test_fsm_integration():
		passed_tests += 1

	_log("==================================================")
	_log("[TEST RUNNER] Hasil Pengujian: %d / %d Lulus" % [passed_tests, total_tests])
	_log("==================================================")

	if passed_tests == total_tests:
		_log(">>> SEMUA TES STORY 1.2 BERHASIL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(0)
	else:
		_log(">>> BEBERAPA TES GAGAL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(1)

func _test_vector_resolution() -> bool:
	_log("\n--- Test 1: 8-Way Vector Resolution & Fallbacks ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaVectorTest"
	add_child(mecha)

	assert(mecha.has_method("get_dash_vector"), "BaseMecha harus memiliki method get_dash_vector()")
	assert(mecha.has_method("resolve_dash_vector"), "BaseMecha harus memiliki method resolve_dash_vector(raw_input: Vector2)")

	# Cardinal & diagonal resolution checks
	var right_vec: Vector2 = mecha.resolve_dash_vector(Vector2(1, 0))
	assert(right_vec.is_equal_approx(Vector2(1, 0)), "Arah kanan harus (1, 0)")

	var left_vec: Vector2 = mecha.resolve_dash_vector(Vector2(-1, 0))
	assert(left_vec.is_equal_approx(Vector2(-1, 0)), "Arah kiri harus (-1, 0)")

	var up_vec: Vector2 = mecha.resolve_dash_vector(Vector2(0, -1))
	assert(up_vec.is_equal_approx(Vector2(0, -1)), "Arah atas harus (0, -1)")

	var diag_ru: Vector2 = mecha.resolve_dash_vector(Vector2(1, -1))
	assert(diag_ru.is_equal_approx(Vector2(1, -1).normalized()), "Kanan-Atas harus ternormalisasi")

	var diag_rd: Vector2 = mecha.resolve_dash_vector(Vector2(1, 1))
	assert(diag_rd.is_equal_approx(Vector2(1, 1).normalized()), "Kanan-Bawah harus ternormalisasi")

	var diag_lu: Vector2 = mecha.resolve_dash_vector(Vector2(-1, -1))
	assert(diag_lu.is_equal_approx(Vector2(-1, -1).normalized()), "Kiri-Atas harus ternormalisasi")

	var diag_ld: Vector2 = mecha.resolve_dash_vector(Vector2(-1, 1))
	assert(diag_ld.is_equal_approx(Vector2(-1, 1).normalized()), "Kiri-Bawah harus ternormalisasi")

	# Test fallback ke facing_direction jika input adalah Vector2.ZERO
	mecha.facing_direction = 1
	var zero_fallback_right: Vector2 = mecha.resolve_dash_vector(Vector2.ZERO)
	assert(zero_fallback_right.is_equal_approx(Vector2(1, 0)), "Fallback input nol saat hadap kanan harus (1, 0)")

	mecha.facing_direction = -1
	var zero_fallback_left: Vector2 = mecha.resolve_dash_vector(Vector2.ZERO)
	assert(zero_fallback_left.is_equal_approx(Vector2(-1, 0)), "Fallback input nol saat hadap kiri harus (-1, 0)")

	# Test ground pure-down constraint
	# Jika mecha di tanah (is_on_floor() simulated) dan input adalah pure down (0, 1),
	# tidak boleh menembus tanah (fallback ke horizontal facing_direction)
	var pure_down_ground: Vector2 = mecha.resolve_dash_vector(Vector2(0, 1), true)
	assert(pure_down_ground.is_equal_approx(Vector2(mecha.facing_direction, 0)), "Pure down di darat harus dialihkan ke horizontal hadap mecha")

	# Di udara, pure down tetap diizinkan
	var pure_down_air: Vector2 = mecha.resolve_dash_vector(Vector2(0, 1), false)
	assert(pure_down_air.is_equal_approx(Vector2(0, 1)), "Pure down di udara harus tetap (0, 1)")

	# Input mapping check
	assert(InputMap.has_action("dash"), "InputMap harus memiliki action 'dash'")

	mecha.queue_free()
	_log(" [PASS] Resolusi vektor 8 arah, fallback facing_direction, dan batasan dash bawah di darat terverifikasi.")
	return true

func _test_ground_dash_execution() -> bool:
	_log("\n--- Test 2: Ground Dash Execution, Speed & Duration ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaGroundDash"
	
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var walk := WalkState.new()
	walk.name = "Walk"
	fsm.add_child(walk)

	var dash := DashState.new()
	dash.name = "Dash"
	fsm.add_child(dash)

	add_child(mecha)

	# Inisialisasi awal ke Idle
	assert(fsm.current_state.name == "Idle", "State awal harus Idle")

	# Transisi ke DashState
	mecha.facing_direction = 1
	fsm.change_state(&"Dash")
	assert(fsm.current_state.name == "Dash", "State harus bertransisi ke Dash")

	# Kecepatan harus DASH_SPEED (750.0 px/s)
	assert(is_equal_approx(mecha.velocity.x, CombatConstants.DASH_SPEED), "Kecepatan dash horizontal harus 750 px/s, dapat: %f" % mecha.velocity.x)
	assert(is_equal_approx(mecha.velocity.y, 0.0), "Kecepatan vertikal harus 0")

	# Simulasi 14 frame fisika (DASH_DURATION_FRAMES)
	# Selama 13 frame pertama, state tetap Dash dan gravitasi diabaikan
	for frame in range(CombatConstants.DASH_DURATION_FRAMES - 1):
		fsm.physics_update(CombatConstants.FRAME_DURATION)
		assert(fsm.current_state.name == "Dash", "Pada frame ke-%d state harus tetap Dash" % (frame + 1))
		assert(is_equal_approx(mecha.velocity.y, 0.0), "Gravitasi tidak boleh mempengaruhi velocity Y saat Dash")

	# Frame ke-14: dash selesai, harus bertransisi kembali ke Idle (karena tidak ada input jalan)
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(fsm.current_state.name == "Idle", "Setelah 14 frame, DashState harus bertransisi ke Idle")

	# Pada saat exit Dash, mecha harus memulai cooldown 18 frame
	assert(mecha.dash_cooldown_frames == CombatConstants.DASH_COOLDOWN_FRAMES, "Cooldown mecha harus bernilai 18 frame saat exit Dash")

	mecha.queue_free()
	_log(" [PASS] Kecepatan 750 px/s, durasi tepat 14 frame, proteksi gravitasi, dan inisialisasi cooldown terverifikasi.")
	return true

func _test_air_dash_execution() -> bool:
	_log("\n--- Test 3: Air Dash Execution & Single-use Constraint ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaAirDash"
	
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var jump := JumpState.new()
	jump.name = "Jump"
	fsm.add_child(jump)

	var fall := FallState.new()
	fall.name = "Fall"
	fsm.add_child(fall)

	var air_dash := AirDashState.new()
	air_dash.name = "AirDash"
	fsm.add_child(air_dash)

	add_child(mecha)

	assert(mecha.can_air_dash == true, "Mecha harus memulai dengan can_air_dash = true")

	# Masuk ke Jump
	fsm.change_state(&"Jump")
	assert(fsm.current_state.name == "Jump", "Harus berada di Jump")

	# Pemicu Air Dash diagonal kanan-atas
	mecha.facing_direction = 1
	air_dash.override_direction = Vector2(1, -1).normalized()
	fsm.change_state(&"AirDash")
	assert(fsm.current_state.name == "AirDash", "Harus bertransisi ke AirDash")

	# can_air_dash harus menjadi false setelah digunakan
	assert(mecha.can_air_dash == false, "can_air_dash harus bernilai false saat AirDash aktif")

	# Periksa kecepatan vektor 750 px/s pada sudut diagonal
	var expected_vel: Vector2 = Vector2(1, -1).normalized() * CombatConstants.DASH_SPEED
	assert(mecha.velocity.is_equal_approx(expected_vel), "Kecepatan vektor air dash harus sesuai arah diagonal x 750 px/s")

	# Simulasikan hingga frame ke-14
	for frame in range(CombatConstants.DASH_DURATION_FRAMES - 1):
		fsm.physics_update(CombatConstants.FRAME_DURATION)
		assert(fsm.current_state.name == "AirDash", "Harus tetap AirDash selama durasi aktif")

	# Frame 14 selesai -> harus bertransisi ke FallState
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(fsm.current_state.name == "Fall", "Setelah air dash selesai di udara, harus bertransisi ke FallState")
	assert(mecha.can_air_dash == false, "can_air_dash tetap false selama di udara")

	# Simulasi pendaratan di tanah -> can_air_dash harus ter-reset
	mecha.reset_air_dash()
	assert(mecha.can_air_dash == true, "can_air_dash harus ter-reset saat mendarat")

	mecha.queue_free()
	_log(" [PASS] Air dash 1x per sesi melayang, preservasi vektor di udara, transisi ke Fall, dan reset mendarat terverifikasi.")
	return true

func _test_dash_cooldown() -> bool:
	_log("\n--- Test 4: Cooldown Window (18 Frames) ---")
	var mecha := BaseMecha.new()
	mecha.name = "MechaCooldownTest"
	add_child(mecha)

	mecha.dash_cooldown_frames = CombatConstants.DASH_COOLDOWN_FRAMES
	assert(mecha.can_dash() == false, "Saat dash_cooldown_frames > 0, can_dash() harus bernilai false")

	# Simulasikan ticking cooldown
	for f in range(CombatConstants.DASH_COOLDOWN_FRAMES):
		assert(mecha.can_dash() == false, "Frame cooldown ke-%d belum boleh dash" % f)
		mecha.tick_cooldowns()

	assert(mecha.dash_cooldown_frames == 0, "Cooldown harus mencapai 0 setelah 18 tick")
	assert(mecha.can_dash() == true, "Saat cooldown 0, can_dash() harus bernilai true")

	mecha.queue_free()
	_log(" [PASS] Cooldown 18 frame deterministik dan pencegahan re-dash terverifikasi.")
	return true

func _test_fsm_integration() -> bool:
	_log("\n--- Test 5: FSM Transitions & Scene Composition ---")
	var arena_scene = load("res://scenes/test_arena.tscn")
	assert(arena_scene != null, "Scene test_arena.tscn harus dapat dimuat")
	
	var arena_instance = arena_scene.instantiate()
	assert(arena_instance != null, "Instance test_arena harus berhasil dibuat")
	
	var player = arena_instance.get_node_or_null("Player")
	assert(player != null, "Node Player harus ada di test_arena")
	
	var fsm = player.get_node_or_null("StateMachine")
	assert(fsm != null, "StateMachine harus ada di Player")
	assert(fsm.has_node("Dash"), "StateMachine harus memiliki child state Dash")
	assert(fsm.has_node("AirDash"), "StateMachine harus memiliki child state AirDash")

	var dash_node = fsm.get_node("Dash")
	var air_dash_node = fsm.get_node("AirDash")
	assert(dash_node is DashState, "Node Dash harus instance dari DashState")
	assert(air_dash_node is AirDashState, "Node AirDash harus instance dari AirDashState")

	arena_instance.free()
	_log(" [PASS] Scene test_arena.tscn memiliki node DashState dan AirDashState yang terhubung valid.")
	return true
