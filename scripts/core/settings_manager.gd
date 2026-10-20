class_name SettingsManager
extends Node

## Manajer Konfigurasi & Persistensi Pengaturan (Story 5.6)
## Menyimpan dan memuat preferensi pemain menggunakan ConfigFile di user://settings.cfg

const CONFIG_PATH := "user://settings.cfg"

signal settings_changed(section: String, key: String, value: Variant)
signal settings_loaded()

var _config := ConfigFile.new()

# Nilai Default
const DEFAULT_SETTINGS: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"bgm_volume": 0.8,
		"sfx_volume": 1.0,
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

func _ready() -> void:
	load_settings()

func load_settings() -> bool:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		# Gunakan default dan simpan
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

func _apply_defaults() -> void:
	for sec in DEFAULT_SETTINGS:
		for k in DEFAULT_SETTINGS[sec]:
			_config.set_value(sec, k, DEFAULT_SETTINGS[sec][k])
