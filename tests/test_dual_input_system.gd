extends Node

const TouchControlsOverlayScript = preload("res://scripts/ui/touch_controls_overlay.gd")
const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_dual_input_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.2: Dual-Input System...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_overlay_structure,
		_test_virtual_joystick_dynamic_floating,
		_test_virtual_joystick_vector_and_input_actions,
		_test_six_action_buttons_interaction,
		_test_input_mode_autodetect_switching,
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

func _instantiate_overlay() -> Control:
	var scene: PackedScene = load("res://scenes/touch_controls_overlay.tscn")
	var overlay = scene.instantiate()
	add_child(overlay)
	return overlay

func _test_overlay_structure() -> void:
	var overlay := _instantiate_overlay()
	_check(overlay != null, "Scene touch_controls_overlay.tscn berhasil diinstansiasi.")
	_check(overlay.joystick != null, "VirtualJoystick node ditemukan dan terikat.")

	var expected_actions := [&"attack_light", &"dash", &"skill1", &"skill2", &"parry", &"ultimate"]
	for act in expected_actions:
		_check(overlay.is_action_mapped(act), "Tombol aksi '%s' terdaftar dan terpetakan." % act)

	overlay.queue_free()

func _test_virtual_joystick_dynamic_floating() -> void:
	var overlay := _instantiate_overlay()
	var js = overlay.joystick
	_check(js != null, "VirtualJoystick tersedia.")

	var touch_pos := Vector2(100, 200)
	js.handle_touch_down(touch_pos, 1)

	_check(js.is_active == true, "Joystick aktif setelah touch down.")
	_check(js.active_touch_index == 1, "Touch finger index terekam (index 1).")

	var base_center: Vector2 = js.joystick_base.global_position + (js.joystick_base.size / 2.0)
	_check(base_center.distance_to(touch_pos) < 1.0, "Dynamic floating: Dasar joystick otomatis berpindah ke posisi sentuhan.")

	js.handle_touch_up(1)
	_check(js.is_active == false, "Joystick kembali non-aktif setelah touch up.")

	overlay.queue_free()

func _test_virtual_joystick_vector_and_input_actions() -> void:
	var overlay := _instantiate_overlay()
	var js = overlay.joystick

	var start_pos := Vector2(100, 200)
	js.handle_touch_down(start_pos, 0)

	# Seret ke kanan sejauh 48 px (radius penuh)
	var drag_right := start_pos + Vector2(48, 0)
	js.handle_touch_drag(drag_right, 0)

	_check(js.output_vector.x > 0.9, "Vektor X mengarah ke kanan penuh (Hasil: %.2f)." % js.output_vector.x)
	_check(absf(js.output_vector.y) < 0.1, "Vektor Y mendekati 0 saat seret horizontal murni (Hasil: %.2f)." % js.output_vector.y)
	_check(Input.is_action_pressed("move_right"), "Aksi input 'move_right' aktif.")

	# Seret ke atas-kiri secara diagonal
	var drag_diag := start_pos + Vector2(-48, -48).normalized() * 48.0
	js.handle_touch_drag(drag_diag, 0)
	_check(js.output_vector.x < -0.6 and js.output_vector.y < -0.6, "Vektor diagonal atas-kiri terdeteksi (Hasil: %s)." % js.output_vector)
	_check(Input.is_action_pressed("move_left"), "Aksi input 'move_left' aktif.")
	_check(Input.is_action_pressed("move_up"), "Aksi input 'move_up' aktif.")

	# Lepas sentuhan
	js.handle_touch_up(0)
	_check(js.output_vector == Vector2.ZERO, "Vektor ter-reset ke Vector2.ZERO saat sentuhan dilepas.")
	_check(not Input.is_action_pressed("move_left"), "Aksi 'move_left' otomatis dilepas.")
	_check(not Input.is_action_pressed("move_up"), "Aksi 'move_up' otomatis dilepas.")

	overlay.queue_free()

func _test_six_action_buttons_interaction() -> void:
	var overlay := _instantiate_overlay()
	var emitted_press := {"act": &""}
	var emitted_release := {"act": &""}

	overlay.action_button_pressed.connect(func(act): emitted_press["act"] = act)
	overlay.action_button_released.connect(func(act): emitted_release["act"] = act)

	var actions := [&"attack_light", &"dash", &"skill1", &"skill2", &"parry", &"ultimate"]
	for act in actions:
		var btn: Button = overlay.get_button_for_action(act)
		_check(btn != null, "Button untuk aksi '%s' ditemukan." % act)

		# Tekan tombol
		btn.button_down.emit()
		_check(emitted_press["act"] == act, "Sinyal action_button_pressed terpancar untuk '%s'." % act)
		_check(Input.is_action_pressed(act), "Input.action_press terpicu untuk '%s'." % act)

		# Lepas tombol
		btn.button_up.emit()
		_check(emitted_release["act"] == act, "Sinyal action_button_released terpancar untuk '%s'." % act)
		_check(not Input.is_action_pressed(act), "Input.action_release terpicu untuk '%s'." % act)

	overlay.queue_free()

func _test_input_mode_autodetect_switching() -> void:
	var overlay := _instantiate_overlay()
	var mode_record := {"name": &""}
	overlay.input_mode_changed.connect(func(m): mode_record["name"] = m)

	# Beralih ke Gamepad
	overlay.set_input_mode(TouchControlsOverlayScript.InputMode.GAMEPAD)
	_check(mode_record["name"] == &"gamepad", "Event mode berganti ke 'gamepad'.")
	_check(overlay.visible == false, "Overlay sentuh disembunyikan saat mode Gamepad aktif.")

	# Beralih kembali ke Touch
	overlay.set_input_mode(TouchControlsOverlayScript.InputMode.TOUCH)
	_check(mode_record["name"] == &"touch", "Event mode berganti kembali ke 'touch'.")
	_check(overlay.visible == true, "Overlay sentuh ditampilkan kembali saat mode Touch aktif.")

	overlay.queue_free()
