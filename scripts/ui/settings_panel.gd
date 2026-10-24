class_name SettingsPanel
extends Control

## Panel Pengaturan Interaktif Audio, Display, dan Efek Visual (Epic 14)
## Terhubung langsung ke SettingsManager dan AudioServer dengan dukungan Keyboard/Gamepad/Touch

const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

signal closed()

@onready var master_slider: HSlider = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/MasterRow/HSlider
@onready var master_val_label: Label = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/MasterRow/ValLabel

@onready var bgm_slider: HSlider = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/BgmRow/HSlider
@onready var bgm_val_label: Label = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/BgmRow/ValLabel

@onready var sfx_slider: HSlider = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/SfxRow/HSlider
@onready var sfx_val_label: Label = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/SfxRow/ValLabel

@onready var ann_slider: HSlider = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/AnnRow/HSlider
@onready var ann_val_label: Label = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/AnnRow/ValLabel

@onready var fullscreen_check: CheckBox = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/FullscreenRow/CheckBox
@onready var shake_check: CheckBox = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsVBox/ShakeRow/CheckBox

@onready var btn_reset: Button = $CenterContainer/Panel/Margin/VBox/ButtonsHBox/BtnReset
@onready var btn_records: Button = $CenterContainer/Panel/Margin/VBox/ButtonsHBox/BtnRecords
@onready var btn_close: Button = $CenterContainer/Panel/Margin/VBox/ButtonsHBox/BtnClose

const RecordsPanelScene = preload("res://scenes/records_panel.tscn")
var _records_panel: Control = null

var _settings_mgr: SettingsManager = null

func _ready() -> void:
	_settings_mgr = SettingsManager.get_instance()
	_sync_ui_from_settings()
	_connect_signals()

func _sync_ui_from_settings() -> void:
	if not _settings_mgr:
		return

	var m_vol: float = float(_settings_mgr.get_setting("audio", "master_volume", 1.0))
	var b_vol: float = float(_settings_mgr.get_setting("audio", "bgm_volume", 0.8))
	var s_vol: float = float(_settings_mgr.get_setting("audio", "sfx_volume", 1.0))
	var a_vol: float = float(_settings_mgr.get_setting("audio", "announcer_volume", 1.0))

	if master_slider:
		master_slider.value = m_vol * 100.0
		master_val_label.text = "%d%%" % int(master_slider.value)

	if bgm_slider:
		bgm_slider.value = b_vol * 100.0
		bgm_val_label.text = "%d%%" % int(bgm_slider.value)

	if sfx_slider:
		sfx_slider.value = s_vol * 100.0
		sfx_val_label.text = "%d%%" % int(sfx_slider.value)

	if ann_slider:
		ann_slider.value = a_vol * 100.0
		ann_val_label.text = "%d%%" % int(ann_slider.value)

	if fullscreen_check:
		fullscreen_check.button_pressed = bool(_settings_mgr.get_setting("display", "fullscreen", false))

	if shake_check:
		shake_check.button_pressed = bool(_settings_mgr.get_setting("display", "screen_shake", true))

func _connect_signals() -> void:
	if master_slider and not master_slider.value_changed.is_connected(_on_master_slider_changed):
		master_slider.value_changed.connect(_on_master_slider_changed)

	if bgm_slider and not bgm_slider.value_changed.is_connected(_on_bgm_slider_changed):
		bgm_slider.value_changed.connect(_on_bgm_slider_changed)

	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	if ann_slider and not ann_slider.value_changed.is_connected(_on_ann_slider_changed):
		ann_slider.value_changed.connect(_on_ann_slider_changed)

	if fullscreen_check and not fullscreen_check.toggled.is_connected(_on_fullscreen_toggled):
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	if shake_check and not shake_check.toggled.is_connected(_on_shake_toggled):
		shake_check.toggled.connect(_on_shake_toggled)

	if btn_reset and not btn_reset.pressed.is_connected(_on_reset_pressed):
		btn_reset.pressed.connect(_on_reset_pressed)

	if btn_records and not btn_records.pressed.is_connected(_on_records_pressed):
		btn_records.pressed.connect(_on_records_pressed)

	if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)

func _on_records_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	if not _records_panel:
		_records_panel = RecordsPanelScene.instantiate()
		_records_panel.hide()
		add_child(_records_panel)
		if _records_panel.has_signal("closed"):
			_records_panel.closed.connect(func():
				if visible and btn_records:
					btn_records.grab_focus()
			)
	if _records_panel and _records_panel.has_method("open"):
		_records_panel.open()
	elif _records_panel:
		_records_panel.show()

func _on_master_slider_changed(val: float) -> void:
	var normalized := val / 100.0
	master_val_label.text = "%d%%" % int(val)
	_settings_mgr.set_setting("audio", "master_volume", normalized)
	_settings_mgr.apply_audio_settings()

func _on_bgm_slider_changed(val: float) -> void:
	var normalized := val / 100.0
	bgm_val_label.text = "%d%%" % int(val)
	_settings_mgr.set_setting("audio", "bgm_volume", normalized)
	_settings_mgr.apply_audio_settings()

func _on_sfx_slider_changed(val: float) -> void:
	var normalized := val / 100.0
	sfx_val_label.text = "%d%%" % int(val)
	_settings_mgr.set_setting("audio", "sfx_volume", normalized)
	_settings_mgr.apply_audio_settings()

func _on_ann_slider_changed(val: float) -> void:
	var normalized := val / 100.0
	ann_val_label.text = "%d%%" % int(val)
	_settings_mgr.set_setting("audio", "announcer_volume", normalized)
	_settings_mgr.apply_audio_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings_mgr.set_setting("display", "fullscreen", pressed)
	_settings_mgr.apply_display_settings()

func _on_shake_toggled(pressed: bool) -> void:
	_settings_mgr.set_setting("display", "screen_shake", pressed)

func _on_reset_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	_settings_mgr.reset_to_defaults()
	_sync_ui_from_settings()

func _on_close_pressed() -> void:
	MenuAudio.play_cancel_chime(self)
	_settings_mgr.save_settings()
	closed.emit()
	hide()

func open() -> void:
	_sync_ui_from_settings()
	show()
	if btn_close:
		btn_close.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
