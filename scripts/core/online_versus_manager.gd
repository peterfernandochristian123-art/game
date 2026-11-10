class_name OnlineVersusManager
extends Node2D

## Manajer mode Online 2-Player Versus (MVP: ENet host/join).
## - Host (peer 1): autoritatif, mensimulasikan match dan broadcast state.
## - Client: mengirim input gerak P2 ke host, menerima state sinkronisasi.

const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const PauseMenuScene = preload("res://scenes/pause_menu.tscn")

@onready var p1: Node2D = $Fighters/P1
@onready var p2: Node2D = $Fighters/P2
@onready var match_manager: Node = $MatchManager
@onready var hud: Node = $UI/CombatHUD

@onready var result_overlay: Control = $UI/ResultOverlay
@onready var result_title: Label = $UI/ResultOverlay/Center/VBox/TitleLabel
@onready var btn_rematch: Button = $UI/ResultOverlay/Center/VBox/BtnRematch
@onready var btn_exit: Button = $UI/ResultOverlay/Center/VBox/BtnExit

var _net: Node = null
var _is_server: bool = true
var _sync_accum: float = 0.0
const SYNC_INTERVAL: float = 1.0 / 20.0

func _ready() -> void:
	if not p1 or not p2:
		return
	_net = get_node_or_null("/root/NetworkManager")
	_is_server = multiplayer.is_server()
	if _net == null:
		_is_server = true

	_apply_arena_selection()
	_apply_roster_selection()

	p1.set("player_index", 1)
	p2.set("player_index", 2)

	if hud and hud.has_method("bind_fighters"):
		hud.bind_fighters(p1, p2)

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
		if _is_server and match_manager.has_method("start_match"):
			match_manager.start_match()

	if result_overlay:
		result_overlay.visible = false
	if btn_rematch:
		btn_rematch.pressed.connect(_on_rematch_pressed)
		btn_rematch.visible = _is_server
	if btn_exit:
		btn_exit.pressed.connect(_return_to_main_menu)

	var pause_menu = PauseMenuScene.instantiate()
	pause_menu.name = "PauseMenu"
	var ui_node = get_node_or_null("UI")
	if ui_node:
		ui_node.add_child(pause_menu)
		pause_menu.rematch_requested.connect(_on_rematch_pressed)

func _physics_process(delta: float) -> void:
	if not _net or not _net.is_network_active():
		return
	if _is_server:
		_sync_accum += delta
		if _sync_accum >= SYNC_INTERVAL:
			_sync_accum = 0.0
			_rpc_sync_state.rpc(_pack_state())
	else:
		_send_local_inputs()

func _pack_state() -> Dictionary:
	return {
		"p1": _pack_fighter(p1),
		"p2": _pack_fighter(p2),
		"p1_wins": match_manager.p1_wins if match_manager and "p1_wins" in match_manager else 0,
		"p2_wins": match_manager.p2_wins if match_manager and "p2_wins" in match_manager else 0,
		"round": match_manager.current_round if match_manager and "current_round" in match_manager else 1,
		"time": match_manager.round_time_remaining if match_manager and "round_time_remaining" in match_manager else 0.0,
	}

func _pack_fighter(f: Node2D) -> Dictionary:
	if not f:
		return {}
	return {
		"pos": f.global_position,
		"vel": f.velocity if "velocity" in f else Vector2.ZERO,
		"hp": f.current_hp if "current_hp" in f else 0,
		"facing": f.facing_direction if "facing_direction" in f else 1,
	}

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_state(state: Dictionary) -> void:
	if _is_server:
		return
	_apply_fighter_state(p1, state.get("p1", {}))
	_apply_fighter_state(p2, state.get("p2", {}))
	if hud:
		if hud.has_method("update_round_wins") and "p1_wins" in state:
			hud.update_round_wins(int(state["p1_wins"]), int(state["p2_wins"]))
		if hud.timer_label and "time" in state:
			hud.timer_label.text = "%d" % int(ceil(float(state["time"])))
		if hud.round_label and "round" in state:
			hud.round_label.text = "ROUND %d" % int(state["round"])

func _apply_fighter_state(f: Node2D, s: Dictionary) -> void:
	if not f or s.is_empty():
		return
	if "pos" in s:
		f.global_position = s["pos"]
	if "vel" in s and "velocity" in f:
		f.velocity = s["vel"]
	if "hp" in s and "current_hp" in f:
		f.current_hp = int(s["hp"])
	if "facing" in s and f.has_method("set_facing_direction"):
		f.set_facing_direction(int(s["facing"]))

func _send_local_inputs() -> void:
	# MVP: kirim vektor gerak dasar ke host (P2). Dapat diperluas untuk aksi/serangan.
	var move := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	rpc_id(1, "_rpc_client_input", move)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_client_input(move: Vector2) -> void:
	if not _is_server or not p2:
		return
	if "velocity" in p2 and "walk_speed" in p2:
		p2.velocity.x = move.x * float(p2.walk_speed)
		if move.y < -0.5 and p2.is_on_floor():
			var jv = p2.jump_velocity if "jump_velocity" in p2 else -420.0
			p2.velocity.y = jv

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
	if not _is_server:
		return
	if result_overlay:
		result_overlay.visible = false
	if match_manager and match_manager.has_method("start_match"):
		match_manager.start_match()

func _return_to_main_menu() -> void:
	if _net:
		_net.reset_connection()
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/main_menu.tscn")

func _apply_roster_selection() -> void:
	var fighters_node = get_node_or_null("Fighters")
	if not fighters_node:
		return
	if p1 and p1.has_method("get_archetype") and p1.get_archetype() != MatchConfigScript.p1_character:
		var pos = p1.global_position
		fighters_node.remove_child(p1)
		p1.queue_free()
		p1 = FighterFactoryScript.create_fighter(MatchConfigScript.p1_character, 1)
		p1.global_position = pos
		fighters_node.add_child(p1)
	if p2 and p2.has_method("get_archetype") and p2.get_archetype() != MatchConfigScript.p2_character:
		var pos = p2.global_position
		fighters_node.remove_child(p2)
		p2.queue_free()
		p2 = FighterFactoryScript.create_fighter(MatchConfigScript.p2_character, 2)
		p2.global_position = pos
		fighters_node.add_child(p2)

func _apply_arena_selection() -> void:
	if MatchConfigScript.selected_arena != &"skyscraper":
		var current_arena = get_node_or_null("ArenaSkyscraper")
		if current_arena:
			var scene_path: String = MatchConfigScript.get_arena_scene()
			var arena_scene = load(scene_path)
			if arena_scene:
				var new_arena = arena_scene.instantiate()
				var idx = current_arena.get_index()
				current_arena.name = "ArenaSkyscraper_Old"
				current_arena.queue_free()
				add_child(new_arena)
				move_child(new_arena, idx)
