class_name CharacterSelect
extends Control

## Character Select Screen & Roster Selector (Story 11.1)
## Antarmuka pemilihan mecha arcade 32-bit retro cyberpunk
## Mendukung rotasi 3 petarung (Viper, Bulwark, Pulsar), inspeksi statistik,
## live pixel sprite preview, konfirmasi duel, dan transisi mulus ke arena.

const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

signal p1_selection_changed(index: int, char_id: StringName)
signal p2_selection_changed(index: int, char_id: StringName)
signal selection_confirmed(p1_char_id: StringName, p2_char_id: StringName)
signal cancelled()

var p1_index: int = 0
var p2_index: int = 1
var p1_locked: bool = false
var p2_locked: bool = false
var is_transitioning: bool = false

@onready var title_label: Label = $TopBar/TitleLabel
@onready var mode_label: Label = $TopBar/ModeLabel
@onready var stage_label: Label = $TopBar/StageLabel

# Roster Cards Container
@onready var cards_container: HBoxContainer = $RosterArea/CardsContainer

# Preview & Details Area
@onready var p1_preview_mount: Control = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/SpriteMount
@onready var p1_name_label: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/NameLabel
@onready var p1_archetype_label: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/ArchetypeLabel
@onready var p1_ready_badge: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/ReadyBadge
@onready var p1_stats_label: Label = $DetailsArea/P1Panel/Margin/VBox/StatsLabel
@onready var p1_moves_label: Label = $DetailsArea/P1Panel/Margin/VBox/MovesLabel

@onready var p2_preview_mount: Control = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/SpriteMount
@onready var p2_name_label: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/NameLabel
@onready var p2_archetype_label: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/ArchetypeLabel
@onready var p2_ready_badge: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/ReadyBadge
@onready var p2_stats_label: Label = $DetailsArea/P2Panel/Margin/VBox/StatsLabel
@onready var p2_moves_label: Label = $DetailsArea/P2Panel/Margin/VBox/MovesLabel

@onready var prompt_label: Label = $BottomBar/PromptLabel
@onready var fade_rect: ColorRect = $FadeOverlay

var _p1_sprite: Node2D = null
var _p2_sprite: Node2D = null
var _card_nodes: Array[PanelContainer] = []

func _ready() -> void:
	_setup_audio()
	_build_roster_cards()
	_update_p1_display()
	_update_p2_display()
	_update_stage_ui()
	if MatchConfigScript.game_mode == &"arcade" and mode_label:
		mode_label.text = "MODE: ARCADE GAUNTLET (4-STAGE)"
	_fade_in()

func _setup_audio() -> void:
	if AudioManagerScript.instance != null:
		AudioManagerScript.instance.play_bgm(&"title")

func _build_roster_cards() -> void:
	_card_nodes.clear()
	for child in cards_container.get_children():
		child.queue_free()

	for i in range(FighterFactoryScript.get_roster_count()):
		var char_data = FighterFactoryScript.get_character_at(i)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(170, 70)
		card.name = "Card_" + String(char_data["id"])

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var lbl_name := Label.new()
		lbl_name.name = "LabelName"
		lbl_name.text = char_data["name"]
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_name.add_theme_color_override("font_color", char_data["theme_color"])

		var lbl_arch := Label.new()
		lbl_arch.name = "LabelArch"
		lbl_arch.text = char_data["archetype"]
		lbl_arch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_arch.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.7))
		lbl_arch.add_theme_font_size_override("font_size", 9)

		vbox.add_child(lbl_name)
		vbox.add_child(lbl_arch)
		card.add_child(vbox)

		cards_container.add_child(card)
		_card_nodes.append(card)

	_highlight_cards()

func _highlight_cards() -> void:
	for i in range(_card_nodes.size()):
		var card = _card_nodes[i]
		var border_color: Color = Color(0.3, 0.4, 0.5, 0.4)
		if i == p1_index and i == p2_index:
			border_color = Color(1.0, 0.9, 0.2, 1.0) # P1 & P2 sama
		elif i == p1_index:
			border_color = Color(0.2, 0.95, 1.0, 1.0) # P1 Cyan
		elif i == p2_index:
			border_color = Color(1.0, 0.4, 0.3, 1.0) # P2 Red/Orange

		card.modulate = Color(1.2, 1.2, 1.2, 1.0) if (i == p1_index or i == p2_index) else Color(0.7, 0.7, 0.8, 0.8)

func _update_p1_display() -> void:
	var char_data = FighterFactoryScript.get_character_at(p1_index)
	p1_name_label.text = "P1: " + char_data["name"]
	p1_name_label.add_theme_color_override("font_color", char_data["theme_color"])
	p1_archetype_label.text = char_data["archetype"]
	p1_stats_label.text = "HP: %d | SPD: %s | DEF: %s | RNG: %s" % [
		char_data["hp"], char_data["speed_grade"], char_data["defense_grade"], char_data["range_grade"]
	]
	p1_moves_label.text = "\n".join(char_data["signature_moves"])

	if p1_ready_badge:
		p1_ready_badge.visible = p1_locked
		p1_ready_badge.text = "[ READY ]" if p1_locked else ""

	# Live Pixel Sprite Preview
	if is_instance_valid(_p1_sprite):
		_p1_sprite.queue_free()
	var spr := MechaPixelSpriteScript.new()
	spr.name = "P1Sprite"
	spr.archetype = char_data["id"]
	spr.position = Vector2(40, 50)
	spr.scale = Vector2(2.5, 2.5)
	p1_preview_mount.add_child(spr)
	_p1_sprite = spr

	_highlight_cards()
	p1_selection_changed.emit(p1_index, char_data["id"])

func _update_p2_display() -> void:
	if MatchConfigScript.game_mode == &"arcade":
		p2_name_label.text = "ARCADE RIVALS & BOSS"
		p2_name_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.35, 1.0))
		p2_archetype_label.text = "4-Stage Gauntlet"
		p2_stats_label.text = "Stage 1-3: Rivals | Stage 4: Unit-0"
		p2_moves_label.text = "Defeat all challengers to conquer the Zero Circuit!"
		if p2_ready_badge:
			p2_ready_badge.visible = true
			p2_ready_badge.text = "[ READY ]"
		return

	var char_data = FighterFactoryScript.get_character_at(p2_index)
	p2_name_label.text = "P2: " + char_data["name"]
	p2_name_label.add_theme_color_override("font_color", char_data["theme_color"])
	p2_archetype_label.text = char_data["archetype"]
	p2_stats_label.text = "HP: %d | SPD: %s | DEF: %s | RNG: %s" % [
		char_data["hp"], char_data["speed_grade"], char_data["defense_grade"], char_data["range_grade"]
	]
	p2_moves_label.text = "\n".join(char_data["signature_moves"])

	if p2_ready_badge:
		p2_ready_badge.visible = p2_locked
		p2_ready_badge.text = "[ READY ]" if p2_locked else ""

	if is_instance_valid(_p2_sprite):
		_p2_sprite.queue_free()
	var spr := MechaPixelSpriteScript.new()
	spr.name = "P2Sprite"
	spr.archetype = char_data["id"]
	spr.position = Vector2(40, 50)
	spr.scale = Vector2(-2.5, 2.5) # Hadap kiri
	p2_preview_mount.add_child(spr)
	_p2_sprite = spr

	_highlight_cards()
	p2_selection_changed.emit(p2_index, char_data["id"])

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	# P1 Navigasi: A / D, Panah Kiri / Kanan
	if not p1_locked:
		if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
			_change_p1_index(-1)
		elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
			_change_p1_index(1)

	# P2 Navigasi (Untuk mode Local 2P / AI pick): J / L atau Up/Down
	if not p2_locked and MatchConfigScript.game_mode == &"local_2p":
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_J or event.keycode == KEY_LEFT:
				_change_p2_index(-1)
			elif event.keycode == KEY_L or event.keycode == KEY_RIGHT:
				_change_p2_index(1)

	# Ganti Arena: Tab / T
	if event is InputEventKey and event.pressed and (event.keycode == KEY_TAB or event.keycode == KEY_T):
		toggle_stage()

	# Konfirmasi: Space / Enter
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_confirm_selection()

	# Batal / Kembali: Esc
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_cancel_or_return()

func toggle_stage() -> void:
	if MatchConfigScript.selected_arena == &"skyscraper":
		MatchConfigScript.set_arena(&"reactor")
	else:
		MatchConfigScript.set_arena(&"skyscraper")
	MenuAudio.play_nav_beep(self)
	_update_stage_ui()

func _update_stage_ui() -> void:
	if not stage_label:
		return
	if MatchConfigScript.selected_arena == &"reactor":
		stage_label.text = "[TAB] ARENA: UNDERGROUND REACTOR (HAZARD ACTIVE)"
		stage_label.modulate = Color(1.0, 0.45, 0.1, 1.0)
	else:
		stage_label.text = "[TAB] ARENA: ZERO-G SKYSCRAPER (OPEN CLIFF)"
		stage_label.modulate = Color(0.2, 0.9, 1.0, 1.0)

func _change_p1_index(delta: int) -> void:
	var total = FighterFactoryScript.get_roster_count()
	p1_index = (p1_index + delta + total) % total
	MenuAudio.play_nav_beep(self)
	_update_p1_display()

func _change_p2_index(delta: int) -> void:
	var total = FighterFactoryScript.get_roster_count()
	p2_index = (p2_index + delta + total) % total
	MenuAudio.play_nav_beep(self)
	_update_p2_display()

func _confirm_selection() -> void:
	if not p1_locked:
		p1_locked = true
		MenuAudio.play_confirm_chime(self)
		_update_p1_display()
		if MatchConfigScript.game_mode == &"versus_ai" or MatchConfigScript.game_mode == &"arcade":
			p2_locked = true
			_update_p2_display()

	if MatchConfigScript.game_mode == &"local_2p" and not p2_locked:
		p2_locked = true
		MenuAudio.play_confirm_chime(self)
		_update_p2_display()

	if p1_locked and p2_locked:
		_launch_match()

func _cancel_or_return() -> void:
	if p1_locked or p2_locked:
		p1_locked = false
		p2_locked = false
		MenuAudio.play_nav_beep(self)
		_update_p1_display()
		_update_p2_display()
	else:
		cancelled.emit()
		_fade_out_and_execute(func():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)

func _launch_match() -> void:
	is_transitioning = true
	var p1_id = FighterFactoryScript.get_character_at(p1_index)["id"]
	var p2_id = FighterFactoryScript.get_character_at(p2_index)["id"]
	MatchConfigScript.set_p1(p1_id)
	MatchConfigScript.set_p2(p2_id)
	selection_confirmed.emit(p1_id, p2_id)

	prompt_label.text = "LAUNCHING ARCADE..." if MatchConfigScript.game_mode == &"arcade" else "LAUNCHING ARENA..."
	prompt_label.modulate = Color(0.2, 0.95, 1.0, 1.0)

	_fade_out_and_execute(func():
		var target_scene = MatchConfigScript.get_target_scene()
		get_tree().change_scene_to_file(target_scene)
	)

func _fade_in() -> void:
	if not fade_rect:
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.3)
	tw.tween_callback(func(): fade_rect.visible = false)

func _fade_out_and_execute(callable: Callable) -> void:
	if not fade_rect:
		callable.call()
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(callable)
