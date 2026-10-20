class_name LocalVersusManager
extends Node2D

## Koordinator Mode Local 2-Player Versus (Story 5.6)
## Mengatur pertarungan 2 pemain pada satu layar (PC/Konsol)
## Mengintegrasikan Arena Skyscraper, P1 (Player 1 Input), P2 (Player 2 Input),
## MatchManager, CombatHUD, dan Result Overlay.

@onready var p1: Node2D = $Fighters/P1
@onready var p2: Node2D = $Fighters/P2
@onready var match_manager: Node = $MatchManager
@onready var hud: Node = $UI/CombatHUD

# Result Overlay
@onready var result_overlay: Control = $UI/ResultOverlay
@onready var result_title: Label = $UI/ResultOverlay/Center/VBox/TitleLabel
@onready var btn_rematch: Button = $UI/ResultOverlay/Center/VBox/BtnRematch
@onready var btn_exit: Button = $UI/ResultOverlay/Center/VBox/BtnExit

func _ready() -> void:
	if not p1 or not p2:
		return

	# 1. Konfigurasi Player Index
	p1.set("player_index", 1)
	p2.set("player_index", 2)

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

	# 4. Bind Result Overlay
	if result_overlay:
		result_overlay.visible = false
	if btn_rematch:
		btn_rematch.pressed.connect(_on_rematch_pressed)
	if btn_exit:
		btn_exit.pressed.connect(_return_to_main_menu)

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
		result_title.text = "VICTORY!\nPLAYER 2 WINS"
		result_title.modulate = Color(1.0, 0.45, 0.2)

func _on_rematch_pressed() -> void:
	if result_overlay:
		result_overlay.visible = false
	if match_manager and match_manager.has_method("start_match"):
		match_manager.start_match()

func _return_to_main_menu() -> void:
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/main_menu.tscn")
