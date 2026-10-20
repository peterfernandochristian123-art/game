extends Node

const PerformanceMonitorScript = preload("res://scripts/core/performance_monitor.gd")
const VersusAIModeScene = preload("res://scenes/versus_ai_mode.tscn")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_performance_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 6.4: Performance & 60 FPS Lock...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_engine_60_fps_lock,
		_test_memory_health_baseline,
		_test_combat_simulation_stress_100_cycles,
		_test_diagnostic_report_integrity
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

func _test_engine_60_fps_lock() -> void:
	PerformanceMonitorScript.lock_engine_60_fps()
	_check(Engine.max_fps == 60, "Engine max_fps terkunci pada 60 FPS.")
	_check(Engine.physics_ticks_per_second == 60, "Physics ticks per second terkunci pada 60 Hz.")

func _test_memory_health_baseline() -> void:
	var mem_mb: float = PerformanceMonitorScript.get_memory_usage_mb()
	_log("   [DIAGNOSTIK] Baseline RAM: %.2f MB" % mem_mb)
	_check(PerformanceMonitorScript.is_memory_healthy(), "Penggunaan memori awal sehat (di bawah ambang batas 600 MB).")
	_check(mem_mb < 300.0, "Konsumsi memori 2D awal sangat efisien (< 300 MB).")

func _test_combat_simulation_stress_100_cycles() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	var p1 = scene.p1
	var p2 = scene.p2

	var mem_start: float = PerformanceMonitorScript.get_memory_usage_mb()
	_log("   [STRESS] Memulai 100 siklus kontak tempur & VFX bertubi-tubi...")

	# Jalankan 100 siklus pertarungan intensif
	for cycle in range(100):
		# Pemicu serangan & hit confirmed
		p1.global_position = Vector2(500, 288)
		p2.global_position = Vector2(540, 288)

		if is_instance_valid(EventBus):
			EventBus.hit_confirmed.emit(p1, p2, {"name": "5L", "damage": 40})
			if cycle % 10 == 0:
				EventBus.parry_triggered.emit(p2, p1)

		# Proses frame fisika
		p1._physics_process(1.0 / 60.0)
		p2._physics_process(1.0 / 60.0)

	var mem_end: float = PerformanceMonitorScript.get_memory_usage_mb()
	_log("   [DIAGNOSTIK] RAM akhir setelah 100 siklus: %.2f MB (delta: %+.2f MB)" % [mem_end, mem_end - mem_start])

	_check(mem_end < PerformanceMonitorScript.MAX_SAFE_MEMORY_MB, "Memori tetap terkendali aman di bawah 600 MB setelah stress test.")
	_check(p1.current_hp > 0, "Pertarungan berjalan stabil tanpa crash atau state corruption.")

	scene.queue_free()

func _test_diagnostic_report_integrity() -> void:
	var report: Dictionary = PerformanceMonitorScript.get_diagnostic_report()
	_check(report.has("memory_mb"), "Laporan diagnostik memiliki key memory_mb.")
	_check(report.has("is_healthy") and report["is_healthy"], "Status kesehatan memori terkonfirmasi bernilai true.")
	_check(report.has("max_fps_setting") and report["max_fps_setting"] == 60, "Setting max_fps terverifikasi 60 FPS.")
