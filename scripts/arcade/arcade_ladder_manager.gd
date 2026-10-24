class_name ArcadeLadderManager
extends Node2D

## Koordinator Mode Arcade Gauntlet 4-Stage & Boss Duel (Story 15.1)
## Mengatur sekuens 4 panggung bertingkat, cutscene dialog clash,
## eskalasi kesulitan bot AI (Novice ➔ Veteran ➔ Ace ➔ Nightmare Boss Unit-0),
## pelacakan statistik performa run, dan layar Continue / Ending.

const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const DialogueOverlayScript = preload("res://scripts/arcade/dialogue_overlay.gd")
const ArcadeEndingScript = preload("res://scripts/arcade/arcade_ending.gd")
const PauseMenuScene = preload("res://scenes/pause_menu.tscn")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

@onready var p1: Node2D = $Fighters/P1
@onready var p2: Node2D = $Fighters/P2
@onready var ai_controller: Node = $AIController
@onready var match_manager: Node = $MatchManager
@onready var hud: Node = $UI/CombatHUD
@onready var touch_overlay: Node = $UI/TouchControlsOverlay
@onready var dialogue_overlay: Node = $UI/DialogueOverlay

# UI Stage Banner & Continue
@onready var stage_banner: PanelContainer = $UI/StageBanner
@onready var stage_label: Label = $UI/StageBanner/Margin/VBox/StageLabel
@onready var stage_subtext: Label = $UI/StageBanner/Margin/VBox/SubtextLabel

@onready var continue_overlay: Control = $UI/ContinueOverlay
@onready var continue_timer_label: Label = $UI/ContinueOverlay/Center/VBox/TimerLabel
@onready var btn_continue: Button = $UI/ContinueOverlay/Center/VBox/BtnContinue
@onready var btn_give_up: Button = $UI/ContinueOverlay/Center/VBox/BtnGiveUp

# Runtime Arcade State
var current_stage: int = 1
const TOTAL_STAGES: int = 4
var stages_data: Array[Dictionary] = []

# Tracking Performa Run
var total_elapsed_time: float = 0.0
var continues_used: int = 0
var total_parries: int = 0
var total_ring_outs: int = 0

var _is_running_match: bool = false
var _continue_countdown: float = 9.9
var _is_in_continue_screen: bool = false

func _ready() -> void:
	_build_stages_pipeline()
	_setup_continue_ui()
	_setup_pause_menu()

	if dialogue_overlay and dialogue_overlay.has_signal("dialogue_finished"):
		dialogue_overlay.dialogue_finished.connect(_on_dialogue_finished)

	if match_manager:
		if match_manager.has_signal("match_ended"):
			match_manager.match_ended.connect(_on_match_ended)
		if match_manager.has_signal("round_ended"):
			match_manager.round_ended.connect(_on_round_ended)

	# Mulai Stage 1
	load_stage(1)

func _process(delta: float) -> void:
	if _is_running_match:
		total_elapsed_time += delta

	if _is_in_continue_screen:
		_continue_countdown -= delta
		if continue_timer_label:
			continue_timer_label.text = "%d" % maxi(0, int(ceil(_continue_countdown)))
		if _continue_countdown <= 0.0:
			_is_in_continue_screen = false
			_give_up_and_exit()

func _build_stages_pipeline() -> void:
	var player_char: StringName = MatchConfigScript.p1_character
	var available_rivals: Array[StringName] = []

	var all_chars: Array[StringName] = [&"viper", &"bulwark", &"pulsar", &"kage"]
	for c in all_chars:
		if c != player_char:
			available_rivals.append(c)

	# Pastikan ada 3 rival sebelum Final Boss
	stages_data = [
		{
			"stage_num": 1,
			"opponent": available_rivals[0] if available_rivals.size() > 0 else &"bulwark",
			"difficulty": AIControllerScript.Difficulty.NOVICE,
			"arena": &"skyscraper",
			"title": "STAGE 1 / 4 - SKYSCRAPER DUEL",
			"subtext": "OPPONENT: NOVICE CLASS GLADIATOR"
		},
		{
			"stage_num": 2,
			"opponent": available_rivals[1] if available_rivals.size() > 1 else &"pulsar",
			"difficulty": AIControllerScript.Difficulty.VETERAN,
			"arena": &"highway",
			"title": "STAGE 2 / 4 - NEO-SHIBUYA OVERPASS",
			"subtext": "OPPONENT: VETERAN HIGHWAY ENFORCER"
		},
		{
			"stage_num": 3,
			"opponent": available_rivals[2] if available_rivals.size() > 2 else &"kage",
			"difficulty": AIControllerScript.Difficulty.ACE,
			"arena": &"reactor",
			"title": "STAGE 3 / 4 - REACTOR TRIAL",
			"subtext": "OPPONENT: ACE CLASS CHAMPION"
		},
		{
			"stage_num": 4,
			"opponent": &"unit_zero",
			"difficulty": AIControllerScript.Difficulty.NIGHTMARE,
			"arena": &"orbital",
			"title": "STAGE 4 / 4 - ORBITAL HORIZON",
			"subtext": "BOSS: UNBOUND OVERCLOCK PROTO-CORE"
		}
	]

func load_stage(stage_num: int) -> void:
	current_stage = stage_num
	var stage_info: Dictionary = stages_data[current_stage - 1]
	_is_running_match = false

	# 1. Update Arena
	MatchConfigScript.set_arena(stage_info["arena"])
	_apply_arena(stage_info["arena"])

	# 2. Spawn / Setup Fighters
	_setup_fighters(stage_info["opponent"])

	# 3. Setup AI Profile
	if ai_controller and ai_controller.has_method("setup"):
		ai_controller.setup(p2, p1, stage_info["difficulty"])

	# 4. Bind HUD
	if hud and hud.has_method("bind_fighters"):
		hud.bind_fighters(p1, p2)

	# 5. Bind MatchManager
	if match_manager:
		match_manager.setup_match(p1, p2)

	# 6. Tampilkan Banner Stage Intro
	_show_stage_banner(stage_info["title"], stage_info["subtext"], func():
		# 7. Mulai Clash Dialogue
		if dialogue_overlay and dialogue_overlay.has_method("start_clash_dialogue"):
			var p1_id: StringName = p1.get_archetype() if p1 and p1.has_method("get_archetype") else MatchConfigScript.p1_character
			dialogue_overlay.start_clash_dialogue(p1_id, stage_info["opponent"])
		else:
			_start_active_match()
	)

func _setup_fighters(opp_id: StringName) -> void:
	var fighters_node = get_node_or_null("Fighters")
	if not fighters_node:
		return

	# P1 (Player)
	var p1_char = MatchConfigScript.p1_character
	if not p1 or (p1.has_method("get_archetype") and p1.get_archetype() != p1_char):
		var pos = p1.global_position if p1 else Vector2(200, 300)
		if p1:
			fighters_node.remove_child(p1)
			p1.queue_free()
		p1 = FighterFactoryScript.create_fighter(p1_char, 1)
		p1.global_position = pos
		fighters_node.add_child(p1)

	# P2 (Rival / Boss)
	var pos2 = p2.global_position if p2 else Vector2(440, 300)
	if p2:
		fighters_node.remove_child(p2)
		p2.queue_free()
	p2 = FighterFactoryScript.create_fighter(opp_id, 2)
	p2.global_position = pos2
	fighters_node.add_child(p2)

func _apply_arena(arena_id: StringName) -> void:
	var existing_arena: Node = null
	for child in get_children():
		if child.name.begins_with("Arena"):
			existing_arena = child
			break

	var scene_path: String = "res://scenes/arena_skyscraper.tscn"
	match arena_id:
		&"reactor":
			scene_path = "res://scenes/arena_underground_reactor.tscn"
		&"orbital":
			scene_path = "res://scenes/arena_orbital_station.tscn"
		&"highway":
			scene_path = "res://scenes/arena_cyber_highway.tscn"
		_:
			scene_path = "res://scenes/arena_skyscraper.tscn"

	if existing_arena and not existing_arena.name.to_lower().contains(String(arena_id)):
		var scene = load(scene_path)
		if scene:
			var new_arena = scene.instantiate()
			var idx = existing_arena.get_index()
			existing_arena.name = "Arena_Old"
			existing_arena.queue_free()
			add_child(new_arena)
			move_child(new_arena, idx)

func _show_stage_banner(title: String, subtext: String, on_complete: Callable) -> void:
	if not stage_banner:
		on_complete.call()
		return

	stage_label.text = title
	stage_subtext.text = subtext
	stage_banner.visible = true
	stage_banner.modulate = Color(1, 1, 1, 0)

	var tw := create_tween()
	tw.tween_property(stage_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.2)
	tw.tween_property(stage_banner, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		stage_banner.visible = false
		on_complete.call()
	)

func _on_dialogue_finished() -> void:
	# Jika selesai clash pre-match ➔ jalankan pertandingan
	if not _is_running_match:
		_start_active_match()
	else:
		# Jika selesai victory quote ➔ transisi ke stage berikutnya atau ending
		if current_stage < TOTAL_STAGES:
			load_stage(current_stage + 1)
		else:
			_launch_arcade_ending()

func _start_active_match() -> void:
	_is_running_match = true
	if match_manager and match_manager.has_method("start_match"):
		match_manager.start_match()

func _on_round_ended(winner_id: int, reason: StringName) -> void:
	if reason == &"ring_out" and winner_id == 1:
		total_ring_outs += 1

func _on_match_ended(match_winner_player_id: int) -> void:
	_is_running_match = false

	if match_winner_player_id == 1:
		# P1 Menang!
		var p1_id: StringName = p1.get_archetype() if p1 and p1.has_method("get_archetype") else MatchConfigScript.p1_character
		if dialogue_overlay and dialogue_overlay.has_method("start_victory_quote"):
			dialogue_overlay.start_victory_quote(p1_id)
		else:
			_on_dialogue_finished()
	else:
		# P1 Kalah! Tampilkan Continue Screen
		_show_continue_screen()

func _show_continue_screen() -> void:
	_is_in_continue_screen = true
	_continue_countdown = 9.9
	if continue_overlay:
		continue_overlay.visible = true

func _setup_continue_ui() -> void:
	if continue_overlay:
		continue_overlay.visible = false
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
	if btn_give_up:
		btn_give_up.pressed.connect(_give_up_and_exit)

func _on_continue_pressed() -> void:
	continues_used += 1
	_is_in_continue_screen = false
	if continue_overlay:
		continue_overlay.visible = false
	MenuAudio.play_confirm_chime(self)
	# Muat ulang stage saat ini
	load_stage(current_stage)

func _give_up_and_exit() -> void:
	_is_in_continue_screen = false
	MenuAudio.play_nav_beep(self)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _launch_arcade_ending() -> void:
	var p1_id: StringName = p1.get_archetype() if p1 and p1.has_method("get_archetype") else MatchConfigScript.p1_character
	ArcadeEndingScript.last_run_stats = {
		"character": p1_id,
		"clear_time": total_elapsed_time,
		"continues": continues_used,
		"parries": total_parries,
		"ring_outs": total_ring_outs
	}
	get_tree().change_scene_to_file("res://scenes/arcade_ending.tscn")

func _setup_pause_menu() -> void:
	var pause_menu = PauseMenuScene.instantiate()
	pause_menu.name = "PauseMenu"
	var ui_node = get_node_or_null("UI")
	if ui_node:
		ui_node.add_child(pause_menu)
		pause_menu.rematch_requested.connect(func(): load_stage(current_stage))
