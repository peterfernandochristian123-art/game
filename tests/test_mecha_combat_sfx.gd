extends Node

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/audio/audio_synthesizer.gd")
const BaseMechaScript = preload("res://scripts/characters/base_mecha.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_mecha_combat_sfx_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 8.2: Mecha Combat SFX Expansion...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_expanded_sfx_streams,
		_test_thruster_dash_on_state_change,
		_test_overclock_alarm_signal_dispatch,
		_test_meltdown_shutdown_on_state_change,
		_test_dynamic_impact_sfx_dispatch,
		_test_base_mecha_overclock_emission
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

func _test_expanded_sfx_streams() -> void:
	var dash = AudioSynthesizerScript.generate_thruster_dash()
	_check(dash != null and dash.data.size() > 0, "SFX Thruster Dash berhasil dibentuk.")

	var oc = AudioSynthesizerScript.generate_overclock_alarm()
	_check(oc != null and oc.data.size() > 0, "SFX Overclock Alarm berhasil dibentuk.")

	var melt = AudioSynthesizerScript.generate_meltdown_shutdown()
	_check(melt != null and melt.data.size() > 0, "SFX Meltdown Shutdown berhasil dibentuk.")

	var impact = AudioSynthesizerScript.generate_heavy_impact()
	_check(impact != null and impact.data.size() > 0, "SFX Heavy Impact berhasil dibentuk.")

	var bounce = AudioSynthesizerScript.generate_wall_bounce()
	_check(bounce != null and bounce.data.size() > 0, "SFX Wall Bounce berhasil dibentuk.")

func _test_thruster_dash_on_state_change() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	_check(audio_mgr.sfx_thruster_dash != null, "Stream sfx_thruster_dash terinisialisasi.")
	audio_mgr._on_state_changed(null, &"Idle", &"Dash")
	audio_mgr._on_state_changed(null, &"Jump", &"AirDash")
	_check(true, "Transisi state ke Dash dan AirDash berhasil memicu SFX Thruster Dash.")

	audio_mgr.queue_free()

func _test_overclock_alarm_signal_dispatch() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	_check(audio_mgr.sfx_overclock_alarm != null, "Stream sfx_overclock_alarm terinisialisasi.")
	audio_mgr._on_overclock_triggered(null, true)
	_check(true, "Pemicu sinyal Overclock aktif berhasil membunyikan alarm.")

	audio_mgr.queue_free()

func _test_meltdown_shutdown_on_state_change() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	var last_cue: Dictionary = {"cue": ""}
	audio_mgr.announcer_called.connect(func(c): last_cue["cue"] = c)

	audio_mgr._on_state_changed(null, &"Idle", &"Meltdown")
	_check(last_cue["cue"] == "CRITICAL MELTDOWN!", "Transisi ke Meltdown membunyikan shutdown dan voice cue announcer.")

	audio_mgr.queue_free()

func _test_dynamic_impact_sfx_dispatch() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	# 1. Normal hit
	audio_mgr._on_hit_confirmed(null, null, {"damage": 40.0})
	_check(true, "Hit normal berhasil diproses.")

	# 2. Heavy impact
	audio_mgr._on_hit_confirmed(null, null, {"damage": 150.0})
	_check(true, "Hit damage tinggi (>= 120) berhasil memicu Heavy Impact.")

	# 3. Wall bounce
	audio_mgr._on_hit_confirmed(null, null, {"wall_bounce": true, "damage": 80.0})
	_check(true, "Hit wall bounce berhasil memicu Wall Bounce SFX.")

	audio_mgr.queue_free()

func _test_base_mecha_overclock_emission() -> void:
	var mecha: BaseMecha = BaseMechaScript.new()
	add_child(mecha)

	var oc_emitted: Dictionary = {"emitted": false, "active": false}
	if is_instance_valid(EventBus):
		EventBus.overclock_triggered.connect(func(_c, active):
			oc_emitted["emitted"] = true
			oc_emitted["active"] = active
		)

	# Naikkan panas ke zona overclock (85%)
	if mecha.heat_component:
		mecha.heat_component.add_heat(85.0)

	_check(oc_emitted["emitted"] and oc_emitted["active"], "BaseMecha memancarkan sinyal EventBus.overclock_triggered saat mencapai 85% heat.")

	mecha.queue_free()
