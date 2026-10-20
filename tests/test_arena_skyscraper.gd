extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const ArenaSkyscraper = preload("res://scripts/arena/arena_skyscraper.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_arena_skyscraper_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 4.1: Arena Skyscraper...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_platform_dimensions_and_layers,
		_test_boundary_positions,
		_test_mecha_on_platform_bounds,
		_test_airborne_ledge_crossing_detection
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
	get_tree().quit(0 if passed == tests.size() else 1)

func _create_arena() -> ArenaSkyscraper:
	var scene: PackedScene = load("res://scenes/arena_skyscraper.tscn")
	var arena = scene.instantiate() as ArenaSkyscraper
	add_child(arena)
	return arena

func _test_platform_dimensions_and_layers() -> void:
	var arena = _create_arena()

	_check(is_equal_approx(arena.platform_width, CombatConstants.ARENA_PLATFORM_WIDTH), "Platform width harus 1280.0 px")
	_check(arena.platform_body != null, "Node Platform StaticBody2D harus ada")
	if arena.platform_body:
		_check(arena.platform_body.collision_layer == 1, "Platform collision layer harus 1 (World)")
		var shape_node = arena.platform_body.get_node_or_null("CollisionShape2D")
		_check(shape_node != null and shape_node.shape is RectangleShape2D, "Collision shape harus RectangleShape2D")
		if shape_node and shape_node.shape is RectangleShape2D:
			var rect = shape_node.shape as RectangleShape2D
			_check(is_equal_approx(rect.size.x, 1280.0), "Lebar shape platform harus 1280.0 px")

	arena.queue_free()

func _test_boundary_positions() -> void:
	var arena = _create_arena()

	_check(is_equal_approx(arena.left_bound, CombatConstants.ARENA_LEFT_BOUND), "Batas kiri harus X = 64.0")
	_check(is_equal_approx(arena.right_bound, CombatConstants.ARENA_RIGHT_BOUND), "Batas kanan harus X = 1344.0")

	# Pengecekan interval platform
	_check(arena.is_within_platform(704.0) == true, "Titik tengah X=704 harus berada di dalam platform")
	_check(arena.is_within_platform(64.0) == true, "Bibir kiri X=64 harus berada di dalam platform")
	_check(arena.is_within_platform(1344.0) == true, "Bibir kanan X=1344 harus berada di dalam platform")
	_check(arena.is_within_platform(63.9) == false, "X=63.9 harus berada di luar platform (tebing kiri)")
	_check(arena.is_within_platform(1344.1) == false, "X=1344.1 harus berada di luar platform (tebing kanan)")

	arena.queue_free()

func _test_mecha_on_platform_bounds() -> void:
	var arena = _create_arena()

	var mecha := CharacterBody2D.new()
	mecha.name = "TestMecha"
	arena.add_child(mecha)
	mecha.global_position = Vector2(704.0, 280.0)

	_check(arena.is_within_platform(mecha.global_position.x), "Mecha di tengah panggung harus terdeteksi di dalam platform")

	mecha.queue_free()
	arena.queue_free()

func _test_airborne_ledge_crossing_detection() -> void:
	var arena = _create_arena()

	var tracker := {"received": false, "side": &""}
	arena.ledge_reached.connect(func(_mecha, side):
		tracker["received"] = true
		tracker["side"] = side
	)

	var airborne_mecha := CharacterBody2D.new()
	airborne_mecha.name = "AirborneMecha"
	arena.add_child(airborne_mecha)
	airborne_mecha.global_position = Vector2(50.0, 320.0) # X < 64

	arena.notify_ledge_cross(airborne_mecha, &"left")
	_check(tracker["received"] and tracker["side"] == &"left", "Ledge cross kiri harus memancarkan signal dengan side 'left'")

	tracker["received"] = false
	tracker["side"] = &""
	airborne_mecha.global_position = Vector2(1360.0, 320.0) # X > 1344
	arena.notify_ledge_cross(airborne_mecha, &"right")
	_check(tracker["received"] and tracker["side"] == &"right", "Ledge cross kanan harus memancarkan signal dengan side 'right'")

	airborne_mecha.queue_free()
	arena.queue_free()
