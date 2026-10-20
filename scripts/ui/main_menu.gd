class_name MainMenu
extends Control

const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

## Pengendali Navigasi Main Menu (Story 5.1)
## Menyediakan antarmuka 32-bit retro arcade dengan dukungan Gamepad, Keyboard, dan Layar Sentuh

signal focus_changed(index: int)
signal option_selected(index: int, item_id: StringName)
signal transition_completed(target_scene: String)

enum MenuItem {
	VERSUS_AI = 0,
	TRAINING_MODE = 1,
	LOCAL_2P = 2,
	SETTINGS = 3,
	EXIT = 4
}

const MENU_DATA: Array[Dictionary] = [
	{"id": &"versus_ai", "label": "VERSUS AI", "scene": "res://scenes/arena_skyscraper.tscn", "subtext": "SOLO DUEL VS AI (NOVICE / VETERAN / ACE)"},
	{"id": &"training", "label": "TRAINING MODE", "scene": "res://scenes/training_mode.tscn", "subtext": "PRACTICE LAB & FRAME DATA INSPECTOR"},
	{"id": &"local_2p", "label": "LOCAL 2P VERSUS", "scene": "res://scenes/arena_skyscraper.tscn", "subtext": "2-PLAYER BATTLE ON A SINGLE SCREEN"},
	{"id": &"settings", "label": "SETTINGS", "scene": "", "subtext": "AUDIO BUSSES, CONTROLS & DISPLAY"},
	{"id": &"exit", "label": "EXIT", "scene": "", "subtext": "SHUTDOWN SYSTEM & EXIT GAME"}
]

const COLOR_NORMAL := Color(0.75, 0.8, 0.9, 0.85)
const COLOR_FOCUSED := Color(0.2, 0.95, 1.0, 1.0) # Neon Cyan
const COLOR_SUBTEXT := Color(0.4, 0.6, 0.7, 0.9)

@export var can_navigate: bool = true
@export var transition_duration: float = 0.35

var current_focus_index: int = 0
var is_transitioning: bool = false
var button_nodes: Array[Button] = []

@onready var menu_container: VBoxContainer = $MenuContainer/OptionsList
@onready var subtext_label: Label = $MenuContainer/SubtextLabel
@onready var fade_rect: ColorRect = $FadeOverlay

func _ready() -> void:
	_setup_buttons()
	_update_visual_focus(0, false)
	_fade_in_menu()

func _setup_buttons() -> void:
	button_nodes.clear()
	if not menu_container:
		return

	# Dapatkan atau bind tombol anak
	var children := menu_container.get_children()
	for i in range(MENU_DATA.size()):
		var btn: Button = null
		if i < children.size() and children[i] is Button:
			btn = children[i] as Button
		else:
			btn = Button.new()
			menu_container.add_child(btn)

		btn.text = MENU_DATA[i]["label"]
		btn.focus_mode = Control.FOCUS_NONE # Kita kelola fokus secara manual untuk multi-input seragam
		var item_idx := i
		btn.pressed.connect(func(): _select_item(item_idx))
		btn.mouse_entered.connect(func():
			if can_navigate and not is_transitioning and current_focus_index != item_idx:
				set_focus_index(item_idx)
		)
		button_nodes.append(btn)

func _unhandled_input(event: InputEvent) -> void:
	if not can_navigate or is_transitioning:
		return

	# 1. Navigasi Ke Bawah (Down)
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
	# 2. Navigasi Ke Atas (Up)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	# 3. Konfirmasi / Accept
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack_light"):
		_select_current()
		get_viewport().set_input_as_handled()
	# 4. Kembali / Cancel (Escape atau B Button)
	elif event.is_action_pressed("ui_cancel"):
		# Jika di pilihan bukan exit, arahkan ke exit
		if current_focus_index != MenuItem.EXIT:
			set_focus_index(MenuItem.EXIT)
		else:
			_select_item(MenuItem.EXIT)
		get_viewport().set_input_as_handled()

func _move_focus(direction: int) -> void:
	var total := MENU_DATA.size()
	var new_index := (current_focus_index + direction + total) % total
	set_focus_index(new_index)

func set_focus_index(index: int, play_sfx: bool = true) -> void:
	if index < 0 or index >= MENU_DATA.size():
		return
	if index == current_focus_index and button_nodes.size() > 0:
		return

	current_focus_index = index
	_update_visual_focus(current_focus_index, true)
	if play_sfx:
		MenuAudio.play_nav_beep(self)
	EventBus.menu_navigated.emit()
	focus_changed.emit(current_focus_index)

func _update_visual_focus(index: int, animate: bool = true) -> void:
	for i in range(button_nodes.size()):
		var btn := button_nodes[i]
		var label_text: String = MENU_DATA[i]["label"]
		if i == index:
			btn.text = "> [ " + label_text + " ] <"
			btn.modulate = COLOR_FOCUSED
			if animate and is_inside_tree():
				var tw := create_tween()
				tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08)
				tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
		else:
			btn.text = "   " + label_text + "   "
			btn.modulate = COLOR_NORMAL
			btn.scale = Vector2(1.0, 1.0)

	if subtext_label and index < MENU_DATA.size():
		subtext_label.text = MENU_DATA[index]["subtext"]
		subtext_label.modulate = COLOR_SUBTEXT

func _select_current() -> void:
	_select_item(current_focus_index)

func _select_item(index: int) -> void:
	if not can_navigate or is_transitioning:
		return
	if index < 0 or index >= MENU_DATA.size():
		return

	var item := MENU_DATA[index]
	var item_id: StringName = item["id"]
	is_transitioning = true
	can_navigate = false

	MenuAudio.play_confirm_chime(self)
	EventBus.game_mode_selected.emit(item_id)
	option_selected.emit(index, item_id)

	# Animasi kedip konfirmasi
	var btn := button_nodes[index]
	var tw := create_tween()
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.05)
	tw.tween_property(btn, "modulate", COLOR_FOCUSED, 0.05)
	tw.tween_interval(0.1)
	tw.tween_callback(func(): _execute_selection_flow(item_id, item["scene"]))

func _execute_selection_flow(item_id: StringName, target_scene_path: String) -> void:
	if item_id == &"exit":
		_fade_out_and_execute(func(): get_tree().quit())
	elif item_id == &"settings":
		# Settings placeholder or modal
		_open_settings_panel()
	elif target_scene_path != "":
		_fade_out_and_execute(func():
			if ResourceLoader.exists(target_scene_path):
				get_tree().change_scene_to_file(target_scene_path)
			else:
				push_warning("[MAIN_MENU] Scene tidak ditemukan: " + target_scene_path)
				is_transitioning = false
				can_navigate = true
		)
	else:
		is_transitioning = false
		can_navigate = true

func _open_settings_panel() -> void:
	# Buka popup/info sederhana untuk setting dan pulihkan navigasi
	if subtext_label:
		subtext_label.text = "SETTINGS: AUDIO MASTER 100% | RESOLUTION 640x360 | (ESC TO RETURN)"
	is_transitioning = false
	can_navigate = true

func _fade_in_menu() -> void:
	if not fade_rect:
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, transition_duration)
	tw.tween_callback(func(): fade_rect.visible = false)

func _fade_out_and_execute(on_complete: Callable) -> void:
	if not fade_rect:
		on_complete.call()
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, transition_duration)
	tw.tween_callback(func():
		transition_completed.emit(MENU_DATA[current_focus_index]["scene"])
		on_complete.call()
	)
