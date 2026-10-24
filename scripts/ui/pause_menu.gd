class_name PauseMenu
extends Control

## Menu Jeda Pertarungan (In-Match Pause Menu - Epic 14)
## Menghentikan simulasi game deterministik, menyediakan navigasi Resume, Settings, Rematch, dan Exit

const MenuAudio = preload("res://scripts/ui/menu_audio.gd")
const SettingsPanelScene = preload("res://scenes/settings_panel.tscn")

signal resumed()
signal rematch_requested()
signal character_select_requested()
signal main_menu_requested()

@onready var btn_resume: Button = $CenterContainer/Panel/Margin/VBox/MenuOptions/BtnResume
@onready var btn_settings: Button = $CenterContainer/Panel/Margin/VBox/MenuOptions/BtnSettings
@onready var btn_rematch: Button = $CenterContainer/Panel/Margin/VBox/MenuOptions/BtnRematch
@onready var btn_char_select: Button = $CenterContainer/Panel/Margin/VBox/MenuOptions/BtnCharSelect
@onready var btn_main_menu: Button = $CenterContainer/Panel/Margin/VBox/MenuOptions/BtnMainMenu

var _settings_panel: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_settings_panel()
	_connect_signals()
	hide()

func _setup_settings_panel() -> void:
	if not _settings_panel:
		_settings_panel = SettingsPanelScene.instantiate()
		_settings_panel.hide()
		add_child(_settings_panel)
		if _settings_panel.has_signal("closed"):
			_settings_panel.closed.connect(func():
				if visible and btn_settings:
					btn_settings.grab_focus()
			)

func _connect_signals() -> void:
	if btn_resume and not btn_resume.pressed.is_connected(resume):
		btn_resume.pressed.connect(resume)
	if btn_settings and not btn_settings.pressed.is_connected(_on_settings_pressed):
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_rematch and not btn_rematch.pressed.is_connected(_on_rematch_pressed):
		btn_rematch.pressed.connect(_on_rematch_pressed)
	if btn_char_select and not btn_char_select.pressed.is_connected(_on_char_select_pressed):
		btn_char_select.pressed.connect(_on_char_select_pressed)
	if btn_main_menu and not btn_main_menu.pressed.is_connected(_on_main_menu_pressed):
		btn_main_menu.pressed.connect(_on_main_menu_pressed)

func pause() -> void:
	MenuAudio.play_nav_beep(self)
	get_tree().paused = true
	show()
	if btn_resume:
		btn_resume.grab_focus()

func resume() -> void:
	MenuAudio.play_cancel_chime(self)
	if _settings_panel and _settings_panel.visible:
		_settings_panel.hide()
	get_tree().paused = false
	hide()
	resumed.emit()

func _on_settings_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	if _settings_panel and _settings_panel.has_method("open"):
		_settings_panel.open()
	elif _settings_panel:
		_settings_panel.show()

func _on_rematch_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	get_tree().paused = false
	hide()
	rematch_requested.emit()

func _on_char_select_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	get_tree().paused = false
	hide()
	character_select_requested.emit()
	if ResourceLoader.exists("res://scenes/character_select.tscn"):
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_main_menu_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	get_tree().paused = false
	hide()
	main_menu_requested.emit()
	if ResourceLoader.exists("res://scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			if _settings_panel and _settings_panel.visible:
				_settings_panel.hide()
			else:
				resume()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused:
			pause()
			get_viewport().set_input_as_handled()
