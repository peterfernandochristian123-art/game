class_name DialogueOverlay
extends Control

## Antarmuka Dialog Pre-Match & Victory Quotes (Story 15.2)
## Menampilkan kartu potret pixel petarung, teks dialog berjalan (typer effect),
## dan tombol pintas konfirmasi keyboard / gamepad / touch.

const DialogueDBScript = preload("res://scripts/arcade/dialogue_db.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

signal dialogue_finished()

@onready var clash_panel: Control = $ClashPanel
@onready var p1_card: PanelContainer = $ClashPanel/P1Card
@onready var p1_name: Label = $ClashPanel/P1Card/Margin/VBox/NameLabel
@onready var p1_title: Label = $ClashPanel/P1Card/Margin/VBox/TitleLabel
@onready var p1_symbol: Label = $ClashPanel/P1Card/Margin/VBox/SymbolLabel
@onready var p1_dialogue: Label = $ClashPanel/P1Card/Margin/VBox/DialogueLabel

@onready var vs_badge: Label = $ClashPanel/VSBadge

@onready var p2_card: PanelContainer = $ClashPanel/P2Card
@onready var p2_name: Label = $ClashPanel/P2Card/Margin/VBox/NameLabel
@onready var p2_title: Label = $ClashPanel/P2Card/Margin/VBox/TitleLabel
@onready var p2_symbol: Label = $ClashPanel/P2Card/Margin/VBox/SymbolLabel
@onready var p2_dialogue: Label = $ClashPanel/P2Card/Margin/VBox/DialogueLabel

@onready var victory_panel: Control = $VictoryPanel
@onready var vic_name: Label = $VictoryPanel/Margin/VBox/WinnerName
@onready var vic_quote: Label = $VictoryPanel/Margin/VBox/QuoteLabel

@onready var prompt_label: Label = $BottomPrompt/PromptLabel

var _is_typing: bool = false
var _full_p1_text: String = ""
var _full_p2_text: String = ""
var _full_vic_text: String = ""
var _mode: StringName = &"clash" # &"clash" | &"victory"
var _active_tween: Tween = null

func _ready() -> void:
	visible = false
	if clash_panel:
		clash_panel.visible = false
	if victory_panel:
		victory_panel.visible = false

func start_clash_dialogue(p1_id: StringName, p2_id: StringName) -> void:
	_mode = &"clash"
	visible = true
	clash_panel.visible = true
	victory_panel.visible = false
	prompt_label.text = "[SPACE / ENTER / A] TO ADVANCE"

	var p1_info: Dictionary = DialogueDBScript.PORTRAITS.get(p1_id, DialogueDBScript.PORTRAITS[&"viper"])
	var p2_info: Dictionary = DialogueDBScript.PORTRAITS.get(p2_id, DialogueDBScript.PORTRAITS[&"bulwark"])
	var matchup: Dictionary = DialogueDBScript.get_matchup_intro(p1_id, p2_id)

	# Setup P1 visual
	p1_name.text = p1_info["name"]
	p1_name.add_theme_color_override("font_color", p1_info["theme_color"])
	p1_title.text = p1_info["title"]
	p1_symbol.text = p1_info["bust_symbol"]
	_full_p1_text = matchup["p1"]
	p1_dialogue.text = ""

	# Setup P2 visual
	p2_name.text = p2_info["name"]
	p2_name.add_theme_color_override("font_color", p2_info["theme_color"])
	p2_title.text = p2_info["title"]
	p2_symbol.text = p2_info["bust_symbol"]
	_full_p2_text = matchup["p2"]
	p2_dialogue.text = ""

	# Animasi typer
	_is_typing = true
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	# Reveal P1 line
	_active_tween.tween_method(func(count: int):
		p1_dialogue.text = _full_p1_text.substr(0, count)
	, 0, _full_p1_text.length(), 0.6)
	_active_tween.tween_interval(0.2)
	# Reveal P2 line
	_active_tween.tween_method(func(count: int):
		p2_dialogue.text = _full_p2_text.substr(0, count)
	, 0, _full_p2_text.length(), 0.6)
	_active_tween.tween_callback(func():
		_is_typing = false
	)

func start_victory_quote(winner_id: StringName, custom_quote: String = "") -> void:
	_mode = &"victory"
	visible = true
	clash_panel.visible = false
	victory_panel.visible = true
	prompt_label.text = "[SPACE / ENTER / A] TO CONTINUE"

	var win_info: Dictionary = DialogueDBScript.PORTRAITS.get(winner_id, DialogueDBScript.PORTRAITS[&"viper"])
	vic_name.text = "VICTORY: " + win_info["name"]
	vic_name.add_theme_color_override("font_color", win_info["theme_color"])

	_full_vic_text = custom_quote if custom_quote != "" else DialogueDBScript.get_random_victory_quote(winner_id)
	vic_quote.text = ""

	_is_typing = true
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_method(func(count: int):
		vic_quote.text = '"' + _full_vic_text.substr(0, count) + '"'
	, 0, _full_vic_text.length(), 0.7)
	_active_tween.tween_callback(func():
		_is_typing = false
	)

func advance_or_skip() -> void:
	if _is_typing:
		# Instantly complete text
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		_is_typing = false
		if _mode == &"clash":
			p1_dialogue.text = _full_p1_text
			p2_dialogue.text = _full_p2_text
		else:
			vic_quote.text = '"' + _full_vic_text + '"'
	else:
		# Finish dialogue
		close()

func close() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	visible = false
	dialogue_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack_light") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		advance_or_skip()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_or_skip()
		get_viewport().set_input_as_handled()
