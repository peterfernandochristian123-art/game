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

## Automated Test Suite untuk Story 1.3:
## Unified 5-Frame Input Buffer & Coyote Time

var log_file: FileAccess = null

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_buffer_coyote_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 1.3...")
	_log("==================================================")

	var total_tests: int = 0
	var passed_tests: int = 0

	# 1. Test InputBuffer 5-Frame Window & Expiration (AC: 1)
	total_tests += 1
	if _test_buffer_window_and_pruning():
		passed_tests += 1

	# 2. Test InputBuffer Consumption & Direction Persistence (AC: 1, 3)
	total_tests += 1
	if _test_buffer_consumption_and_direction():
		passed_tests += 1

	# 3. Test Buffered Action Execution on Actionable Recovery (AC: 1, 3)
	total_tests += 1
	if _test_buffered_recovery_execution():
		passed_tests += 1

	# 4. Test Coyote Time 5-Frame Window on Ledge Departure (AC: 2, 3)
	total_tests += 1
	if _test_coyote_time_window():
		passed_tests += 1

	# 5. Test Coyote Time Expiration & Double Jump Prevention (AC: 2)
	total_tests += 1
	if _test_coyote_expiration_and_double_jump_prevention():
		passed_tests += 1

	_log("==================================================")
	_log("[TEST RUNNER] Hasil Pengujian: %d / %d Lulus" % [passed_tests, total_tests])
	_log("==================================================")

	if passed_tests == total_tests:
		_log(">>> SEMUA TES STORY 1.3 BERHASIL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(0)
	else:
		_log(">>> BEBERAPA TES GAGAL! <<<")
		if log_file:
			log_file.close()
		get_tree().quit(1)

func _test_buffer_window_and_pruning() -> bool:
	_log("\n--- Test 1: InputBuffer 5-Frame Retention & Expiration ---")
	var buffer = get_node_or_null("/root/InputBuffer")
	assert(buffer != null, "Autoload InputBuffer harus terdaftar di /root/InputBuffer")
	buffer.clear_buffer()

	buffer.buffer_action(&"jump")
	assert(buffer.has_action(&"jump") == true, "Aksi jump harus tersimpan di buffer")

	# Simulasikan 5 frame fisika (window aktif)
	for f in range(CombatConstants.INPUT_BUFFER_WINDOW_FRAMES):
		assert(buffer.has_action(&"jump") == true, "Pada frame ke-%d aksi harus masih aktif" % f)
		buffer._physics_process(CombatConstants.FRAME_DURATION)

	# Pada frame ke-6 (lewat batas 5 frame), aksi harus otomatis kedaluwarsa
	buffer._physics_process(CombatConstants.FRAME_DURATION)
	assert(buffer.has_action(&"jump") == false, "Pada frame ke-6 aksi harus dipangkas karena kedaluwarsa")

	_log(" [PASS] Buffer menyimpan input selama 5 frame dan kedaluwarsa tepat pada frame ke-6.")
	return true

func _test_buffer_consumption_and_direction() -> bool:
	_log("\n--- Test 2: InputBuffer Consumption & Direction Vector ---")
	var buffer = get_node_or_null("/root/InputBuffer")
	buffer.clear_buffer()

	var test_dir := Vector2(1, -1).normalized()
	buffer.buffer_action(&"dash", test_dir)

	assert(buffer.has_action(&"dash") == true, "Aksi dash harus terdeteksi di buffer")

	# Ambil data input beserta arahnya
	var consumed_data: Dictionary = buffer.consume_action_with_data(&"dash")
	assert(consumed_data.is_empty() == false, "Data konsumsi tidak boleh kosong")
	assert(consumed_data["action"] == &"dash", "Aksi harus 'dash'")
	assert(consumed_data["vector"].is_equal_approx(test_dir), "Arah vektor harus tersimpan akurat")

	# Panggilan konsumsi kedua harus gagal (single-use)
	assert(buffer.has_action(&"dash") == false, "Buffer harus kosong setelah dikonsumsi")
	var second_consume: bool = buffer.consume_action(&"dash")
	assert(second_consume == false, "Aksi yang sudah dikonsumsi tidak boleh bisa dikonsumsi lagi")

	_log(" [PASS] Konsumsi berarah dan jaminan single-use action terverifikasi.")
	return true

func _test_buffered_recovery_execution() -> bool:
	_log("\n--- Test 3: Buffered Action Execution on Actionable Recovery ---")
	var buffer = get_node_or_null("/root/InputBuffer")
	buffer.clear_buffer()

	var mecha := BaseMecha.new()
	mecha.name = "MechaBufferRecovery"
	
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var jump := JumpState.new()
	jump.name = "Jump"
	fsm.add_child(jump)

	var dash := DashState.new()
	dash.name = "Dash"
	fsm.add_child(dash)

	add_child(mecha)

	# Mulai dari Dash (kondisi non-actionable untuk lompat)
	fsm.change_state(&"Dash")
	assert(fsm.current_state.name == "Dash", "Harus berada di Dash")

	# Pemain menekan jump pada frame ke-12 (2 frame sebelum dash selesai)
	for f in range(12):
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Simulasikan buffer input jump saat dash masih aktif
	buffer.buffer_action(&"jump")
	assert(buffer.has_action(&"jump") == true, "Jump harus tersimpan di buffer saat dash aktif")

	# Selesaikan 2 frame tersisa dari Dash (total 14 frame)
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	fsm.physics_update(CombatConstants.FRAME_DURATION)

	# Begitu Dash selesai dan mecha mendarat di Idle, Idle harus mengonsumsi buffered jump dan transisi ke Jump
	assert(fsm.current_state.name == "Jump", "Mecha harus segera melompat (JumpState) dari input buffer saat Dash berakhir")
	assert(buffer.has_action(&"jump") == false, "Input jump harus telah dikonsumsi")

	mecha.queue_free()
	_log(" [PASS] Input jump yang dibuffer saat dash berhasil dieksekusi instan pada frame pertama actionable.")
	return true

func _test_coyote_time_window() -> bool:
	_log("\n--- Test 4: Coyote Time 5-Frame Window on Ledge Departure ---")
	var buffer = get_node_or_null("/root/InputBuffer")
	buffer.clear_buffer()

	var mecha := BaseMecha.new()
	mecha.name = "MechaCoyoteTest"
	
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

	assert(fsm.current_state.name == "Idle", "State awal harus Idle")

	# Simulasikan mecha melangkah keluar platform (lepas kontak tanah tanpa lompat)
	mecha.notify_ledge_drop()
	assert(mecha.coyote_frames_left == CombatConstants.COYOTE_TIME_FRAMES, "Coyote frames harus diset ke 5 saat jatuh dari platform")

	# Masuk ke FallState
	fsm.change_state(&"Fall")
	assert(fsm.current_state.name == "Fall", "Harus berada di Fall")

	# Simulasikan 3 frame jatuh di udara (Coyote time masih aktif: 5 -> 4 -> 3 -> 2)
	for f in range(3):
		mecha.tick_coyote_time()
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	assert(mecha.can_coyote_jump() == true, "Pada frame ke-3 jatuh, coyote jump harus masih diizinkan")

	# Pemain menekan lompat saat frame ke-3 di udara -> harus berhasil Jump
	buffer.buffer_action(&"jump")
	fsm.physics_update(CombatConstants.FRAME_DURATION)

	assert(fsm.current_state.name == "Jump", "Lompatan harus berhasil dieksekusi dari udara berkat Coyote Time")
	assert(mecha.coyote_frames_left == 0, "Coyote frames harus direset ke 0 setelah lompat dieksekusi")

	mecha.queue_free()
	_log(" [PASS] Mecha dapat melompat selama jendela 5 frame Coyote Time setelah jatuh dari tebing.")
	return true

func _test_coyote_expiration_and_double_jump_prevention() -> bool:
	_log("\n--- Test 5: Coyote Time Expiration & Double Jump Prevention ---")
	var buffer = get_node_or_null("/root/InputBuffer")
	buffer.clear_buffer()

	var mecha := BaseMecha.new()
	mecha.name = "MechaCoyoteExpire"
	
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var jump := JumpState.new()
	jump.name = "Jump"
	fsm.add_child(jump)

	var fall := FallState.new()
	fall.name = "Fall"
	fsm.add_child(fall)

	add_child(mecha)

	# Kasus 1: Coyote Time Kedaluwarsa setelah 5 frame
	mecha.notify_ledge_drop()
	fsm.change_state(&"Fall")

	# Habiskan 5 frame Coyote Time
	for f in range(CombatConstants.COYOTE_TIME_FRAMES):
		mecha.tick_coyote_time()
		fsm.physics_update(CombatConstants.FRAME_DURATION)

	assert(mecha.coyote_frames_left == 0, "Coyote frames harus 0 setelah 5 tick")
	assert(mecha.can_coyote_jump() == false, "Tidak boleh bisa coyote jump lagi setelah 5 frame")

	# Coba lompat di frame ke-6 -> harus ditolak, tetap berada di FallState
	buffer.buffer_action(&"jump")
	fsm.physics_update(CombatConstants.FRAME_DURATION)
	assert(fsm.current_state.name == "Fall", "Mecha harus tetap FallState saat input jump ditekan setelah coyote time habis")

	# Kasus 2: Lompatan normal dari tanah tidak boleh mengaktifkan coyote time (pencegahan double jump)
	fsm.change_state(&"Jump")
	assert(mecha.coyote_frames_left == 0, "Lompatan sengaja dari tanah tidak boleh memberi coyote time")
	assert(mecha.can_coyote_jump() == false, "Tidak boleh ada double jump di udara")

	mecha.queue_free()
	_log(" [PASS] Kedaluwarsa Coyote Time pada frame ke-6 dan proteksi double jump terverifikasi.")
	return true
