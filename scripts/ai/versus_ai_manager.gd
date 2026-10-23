class_name VersusAIManager
extends Node2D

## Koordinator Mode Versus AI (Story 5.5)
## Mengintegrasikan Arena Skyscraper, Petarung P1 (Manusia), Petarung P2 (AI Bot),
## MatchRules, CombatHUD, Dual-Input Touch Overlay, dan Pengatur Tingkat Kesulitan.

const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")

@onready var p1: Node2D = $Fighters/P1
@onready var p2: Node2D = $Fighters/P2
@onready var ai_controller: Node = $AIController
@onready var match_manager: Node = $MatchManager
@onready var hud: Node = $UI/CombatHUD
@onready var touch_overlay: Node = $UI/TouchControlsOverlay

# UI Difficulty Selection
@onready var difficulty_label: Label = $UI/DifficultyPanel/Margin/HBox/CurrentDiffLabel
@onready var btn_novice: Button = $UI/DifficultyPanel/Margin/HBox/BtnNovice
@onready var btn_veteran: Button = $UI/DifficultyPanel/Margin/HBox/BtnVeteran
@onready var btn_ace: Button = $UI/DifficultyPanel/Margin/HBox/BtnAce
@onready var btn_back_menu: Button = $UI/DifficultyPanel/Margin/HBox/BtnBackMenu

# Match Result Overlay
@onready var result_overlay: Control = $UI/ResultOverlay
@onready var result_title: Label = $UI/ResultOverlay/Center/VBox/TitleLabel
@onready var btn_rematch: Button = $UI/ResultOverlay/Center/VBox/BtnRematch
@onready var btn_exit: Button = $UI/ResultOverlay/Center/VBox/BtnExit

func _ready() -> void:
	if not p1 or not p2:
		return

	_apply_roster_selection()

	# 1. Setup AI Controller
	if ai_controller and ai_controller.has_method("setup"):
		ai_controller.setup(p2, p1, AIControllerScript.Difficulty.VETERAN)
		_update_difficulty_ui(AIControllerScript.Difficulty.VETERAN)

	# 2. Setup HUD Bindings
	if hud and hud.has_method("bind_fighters"):
		hud.bind_fighters(p1, p2)

	# 3. Setup MatchManager Bindings
	if match_manager:
		match_manager.setup_match(p1, p2)
		if match_manager.has_signal("match_ended"):
			match_manager.match_ended.connect(_on_match_ended)
		if match_manager.has_signal("round_started"):
			match_manager.round_started.connect(_on_round_started)
		if match_manager.has_signal("timer_updated"):
			match_manager.timer_updated.connect(_on_timer_updated)
		if match_manager.has_signal("round_ended"):
			match_manager.round_ended.connect(_on_round_ended)
		if match_manager.has_method("start_match"):
			match_manager.start_match()

	# 4. Bind Difficulty Buttons
	if btn_novice:
		btn_novice.pressed.connect(func(): _set_ai_difficulty(AIControllerScript.Difficulty.NOVICE))
	if btn_veteran:
		btn_veteran.pressed.connect(func(): _set_ai_difficulty(AIControllerScript.Difficulty.VETERAN))
	if btn_ace:
		btn_ace.pressed.connect(func(): _set_ai_difficulty(AIControllerScript.Difficulty.ACE))
	if btn_back_menu:
		btn_back_menu.pressed.connect(_return_to_main_menu)

	# 5. Bind Result Overlay
	if result_overlay:
		result_overlay.visible = false
	if btn_rematch:
		btn_rematch.pressed.connect(_on_rematch_pressed)
	if btn_exit:
		btn_exit.pressed.connect(_return_to_main_menu)

func _set_ai_difficulty(diff: int) -> void:
	if ai_controller and ai_controller.has_method("set_difficulty"):
		ai_controller.set_difficulty(diff)
		_update_difficulty_ui(diff)

func _update_difficulty_ui(diff: int) -> void:
	if not difficulty_label:
		return
	match diff:
		AIControllerScript.Difficulty.NOVICE:
			difficulty_label.text = "AI: NOVICE"
			difficulty_label.modulate = Color(0.3, 1.0, 0.4)
		AIControllerScript.Difficulty.VETERAN:
			difficulty_label.text = "AI: VETERAN"
			difficulty_label.modulate = Color(1.0, 0.85, 0.2)
		AIControllerScript.Difficulty.ACE:
			difficulty_label.text = "AI: ACE (NIGHTMARE)"
			difficulty_label.modulate = Color(1.0, 0.2, 0.3)

func _on_round_started(round_num: int) -> void:
	if hud and hud.round_label:
		hud.round_label.text = "ROUND %d" % round_num

func _on_timer_updated(seconds_left: float) -> void:
	if hud and hud.timer_label:
		hud.timer_label.text = "%d" % int(ceil(seconds_left))

func _on_round_ended(_winner_id: int, _reason: StringName) -> void:
	if hud and hud.has_method("update_round_wins") and match_manager:
		hud.update_round_wins(match_manager.p1_wins, match_manager.p2_wins)

func _on_match_ended(winner_player_id: int) -> void:
	if not result_overlay:
		return
	result_overlay.visible = true
	if winner_player_id == 1:
		result_title.text = "VICTORY!\nPLAYER 1 WINS"
		result_title.modulate = Color(0.2, 1.0, 0.5)
	else:
		result_title.text = "DEFEAT!\nAI WINS"
		result_title.modulate = Color(1.0, 0.25, 0.25)

func _on_rematch_pressed() -> void:
	if result_overlay:
		result_overlay.visible = false
	if match_manager and match_manager.has_method("start_match"):
		match_manager.start_match()

func _return_to_main_menu() -> void:
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/main_menu.tscn")

func _apply_roster_selection() -> void:
	var fighters_node = get_node_or_null("Fighters")
	if not fighters_node:
		return

	# Cek apakah P1 perlu diganti sesuai MatchConfig
	if p1 and p1.has_method("get_archetype") and p1.get_archetype() != MatchConfigScript.p1_character:
		var pos = p1.global_position
		fighters_node.remove_child(p1)
		p1.queue_free()
		p1 = FighterFactoryScript.create_fighter(MatchConfigScript.p1_character, 1)
		p1.global_position = pos
		fighters_node.add_child(p1)

	# Cek apakah P2 perlu diganti sesuai MatchConfig
	if p2 and p2.has_method("get_archetype") and p2.get_archetype() != MatchConfigScript.p2_character:
		var pos = p2.global_position
		fighters_node.remove_child(p2)
		p2.queue_free()
		p2 = FighterFactoryScript.create_fighter(MatchConfigScript.p2_character, 2)
		p2.global_position = pos
		fighters_node.add_child(p2)

