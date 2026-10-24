class_name RecordsManager
extends RefCounted

## Manajer Rekor & Statistik Pertarungan Pemain (NFR8 & GDD 6.1)
## Menyimpan dan mengelola data karir pemain di user://records.cfg menggunakan ConfigFile

const RECORDS_PATH := "user://records.cfg"

signal records_updated()

static var _instance: RecordsManager = null

static func get_instance() -> RecordsManager:
	if _instance == null:
		_instance = RecordsManager.new()
		_instance.load_records()
	return _instance

var _config := ConfigFile.new()

const DEFAULT_RECORDS: Dictionary = {
	"stats": {
		"total_matches": 0,
		"wins": 0,
		"losses": 0,
		"ring_outs": 0,
		"parries_executed": 0,
		"meltdowns_triggered": 0,
		"favorite_character": "viper"
	},
	"characters": {
		"viper": 0,
		"bulwark": 0,
		"pulsar": 0,
		"kage": 0
	}
}

func _init() -> void:
	load_records()

func load_records() -> bool:
	var err := _config.load(RECORDS_PATH)
	if err != OK:
		_apply_defaults()
		save_records()
		return false
	return true

func save_records() -> Error:
	var err := _config.save(RECORDS_PATH)
	if err != OK and OS.is_debug_build():
		push_warning("[RECORDS] Gagal menyimpan ke %s: error %d" % [RECORDS_PATH, err])
	return err

func _apply_defaults() -> void:
	for section in DEFAULT_RECORDS:
		for key in DEFAULT_RECORDS[section]:
			_config.set_value(section, key, DEFAULT_RECORDS[section][key])

func get_stat(key: String, default_val: Variant = 0) -> Variant:
	if _config.has_section_key("stats", key):
		return _config.get_value("stats", key)
	return default_val

func get_char_usage(char_id: String) -> int:
	if _config.has_section_key("characters", char_id):
		return _config.get_value("characters", char_id)
	return 0

func get_win_rate() -> float:
	var total: int = get_stat("total_matches", 0)
	if total <= 0:
		return 0.0
	var wins: int = get_stat("wins", 0)
	return (float(wins) / float(total)) * 100.0

func record_match(p1_won: bool, p1_char: StringName, _p2_char: StringName, is_ring_out: bool = false, parries: int = 0, meltdowns: int = 0) -> void:
	var total: int = get_stat("total_matches", 0) + 1
	_config.set_value("stats", "total_matches", total)

	if p1_won:
		_config.set_value("stats", "wins", get_stat("wins", 0) + 1)
	else:
		_config.set_value("stats", "losses", get_stat("losses", 0) + 1)

	if is_ring_out:
		_config.set_value("stats", "ring_outs", get_stat("ring_outs", 0) + 1)

	if parries > 0:
		_config.set_value("stats", "parries_executed", get_stat("parries_executed", 0) + parries)

	if meltdowns > 0:
		_config.set_value("stats", "meltdowns_triggered", get_stat("meltdowns_triggered", 0) + meltdowns)

	# Update character usage
	var char_key := String(p1_char).to_lower()
	var current_usage := get_char_usage(char_key) + 1
	_config.set_value("characters", char_key, current_usage)

	# Update favorite character
	var max_usage := 0
	var fav_char := "viper"
	if _config.has_section("characters"):
		for c_id in _config.get_section_keys("characters"):
			var usage: int = _config.get_value("characters", c_id)
			if usage > max_usage:
				max_usage = usage
				fav_char = c_id
	_config.set_value("stats", "favorite_character", fav_char)

	save_records()
	records_updated.emit()

func reset_records() -> void:
	_config.clear()
	_apply_defaults()
	save_records()
	records_updated.emit()
