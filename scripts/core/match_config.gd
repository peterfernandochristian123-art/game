class_name MatchConfig
extends RefCounted

## Konfigurasi Global Pertandingan (Story 11.1)
## Menyimpan preferensi karakter terpilih dan mode game aktif
## Menghubungkan Character Select Screen dengan Arena Duel (Versus AI / Local 2P / Training)

static var p1_character: StringName = &"viper"
static var p2_character: StringName = &"bulwark"
static var game_mode: StringName = &"versus_ai"
static var ai_difficulty: int = 1 # 0: Novice, 1: Veteran, 2: Ace
static var selected_arena: StringName = &"skyscraper" # &"skyscraper" | &"reactor" | &"orbital" | &"highway"
const AVAILABLE_ARENAS: Array[StringName] = [&"skyscraper", &"reactor", &"orbital", &"highway"]

static func reset_defaults() -> void:
	p1_character = &"viper"
	p2_character = &"bulwark"
	game_mode = &"versus_ai"
	ai_difficulty = 1
	selected_arena = &"skyscraper"

static func set_arena(arena_id: StringName) -> void:
	selected_arena = arena_id

static func cycle_next_arena() -> StringName:
	var idx = AVAILABLE_ARENAS.find(selected_arena)
	if idx == -1:
		selected_arena = &"skyscraper"
	else:
		selected_arena = AVAILABLE_ARENAS[(idx + 1) % AVAILABLE_ARENAS.size()]
	return selected_arena

static func get_arena_scene() -> String:
	match selected_arena:
		&"reactor":
			return "res://scenes/arena_underground_reactor.tscn"
		&"orbital":
			return "res://scenes/arena_orbital_station.tscn"
		&"highway":
			return "res://scenes/arena_cyber_highway.tscn"
		_:
			return "res://scenes/arena_skyscraper.tscn"

static func set_p1(char_id: StringName) -> void:
	p1_character = char_id

static func set_p2(char_id: StringName) -> void:
	p2_character = char_id

static func set_mode(mode: StringName) -> void:
	game_mode = mode

static func get_target_scene() -> String:
	match game_mode:
		&"arcade":
			return "res://scenes/arcade_ladder_mode.tscn"
		&"versus_ai":
			return "res://scenes/versus_ai_mode.tscn"
		&"local_2p":
			return "res://scenes/local_versus_mode.tscn"
		&"training":
			return "res://scenes/training_mode.tscn"
		_:
			return "res://scenes/versus_ai_mode.tscn"
