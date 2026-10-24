class_name SettingsManager
extends Node

## Manajer Konfigurasi & Persistensi Pengaturan (Story 5.6 & Epic 14)
## Menyimpan dan memuat preferensi pemain menggunakan ConfigFile di user://settings.cfg

const CONFIG_PATH := "user://settings.cfg"

signal settings_changed(section: String, key: String, value: Variant)
signal settings_loaded()

static var instance: SettingsManager = null

var _config := ConfigFile.new()

# Nilai Default
const DEFAULT_SETTINGS: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"bgm_volume": 0.8,
		"sfx_volume": 1.0,
		"announcer_volume": 1.0,
		"muted": false
	},
	"controls": {
		"p1_input_type": "auto",
		"p2_input_type": "auto",
		"rumble_enabled": true
	},
	"display": {
		"fullscreen": false,
		"screen_shake": true,
		"hitstop_multiplier": 1.0
	}
}

func _init() -> void:
	if instance == null:
		instance = self

static func get_instance() -> SettingsManager:
	if instance == null:
		instance = SettingsManager.new()
		instance.load_settings()
	return instance

func _ready() -> void:
	load_settings()
	apply_all()

func load_settings() -> bool:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		_apply_defaults()
		save_settings()
		settings_loaded.emit()
		return false

	settings_loaded.emit()
	return true

func save_settings() -> Error:
	var err := _config.save(CONFIG_PATH)
	if err != OK and OS.is_debug_build():
		push_warning("[SETTINGS] Gagal menyimpan ke %s: error %d" % [CONFIG_PATH, err])
	return err

func get_setting(section: String, key: String, default_val: Variant = null) -> Variant:
	if _config.has_section_key(section, key):
		return _config.get_value(section, key)
	if default_val != null:
		return default_val
	if DEFAULT_SETTINGS.has(section) and DEFAULT_SETTINGS[section].has(key):
		return DEFAULT_SETTINGS[section][key]
	return null

func set_setting(section: String, key: String, val: Variant) -> void:
	_config.set_value(section, key, val)
	settings_changed.emit(section, key, val)

func reset_to_defaults() -> void:
	_config.clear()
	_apply_defaults()
	save_settings()
	apply_all()

func _apply_defaults() -> void:
	for sec in DEFAULT_SETTINGS:
		for k in DEFAULT_SETTINGS[sec]:
			_config.set_value(sec, k, DEFAULT_SETTINGS[sec][k])

func apply_all() -> void:
	apply_audio_settings()
	apply_display_settings()

func apply_audio_settings() -> void:
	var master_vol: float = float(get_setting("audio", "master_volume", 1.0))
	var bgm_vol: float = float(get_setting("audio", "bgm_volume", 0.8))
	var sfx_vol: float = float(get_setting("audio", "sfx_volume", 1.0))
	var ann_vol: float = float(get_setting("audio", "announcer_volume", 1.0))
	var is_muted: bool = bool(get_setting("audio", "muted", false))

	_set_bus_volume(&"Master", master_vol, is_muted)
	_set_bus_volume(&"BGM", bgm_vol, is_muted)
	_set_bus_volume(&"SFX", sfx_vol, is_muted)
	_set_bus_volume(&"Announcer", ann_vol, is_muted)

func _set_bus_volume(bus_name: StringName, linear_val: float, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted or linear_val <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear_val, 0.001, 1.0)))

func apply_display_settings() -> void:
	var is_fullscreen: bool = bool(get_setting("display", "fullscreen", false))
	if DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS):
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
