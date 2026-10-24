class_name RecordsPanel
extends Control

## Panel Tampilan Rekor Pertarungan & Statistik Karir Pemain (Epic 14)
## Menampilkan data dari RecordsManager (user://records.cfg)

const RecordsManagerScript = preload("res://scripts/core/records_manager.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

signal closed()

@onready var matches_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/MatchesVal
@onready var winloss_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/WinLossVal
@onready var winrate_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/WinRateVal
@onready var parry_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/ParryVal
@onready var ringout_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/RingOutVal
@onready var meltdown_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/MeltdownVal
@onready var fav_char_label: Label = $CenterContainer/Panel/Margin/VBox/Grid/FavCharVal

@onready var btn_reset: Button = $CenterContainer/Panel/Margin/VBox/ButtonsHBox/BtnReset
@onready var btn_close: Button = $CenterContainer/Panel/Margin/VBox/ButtonsHBox/BtnClose

var _records_mgr: RecordsManager = null

func _ready() -> void:
	_records_mgr = RecordsManager.get_instance()
	_sync_display()
	_connect_signals()

func _connect_signals() -> void:
	if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	if btn_reset and not btn_reset.pressed.is_connected(_on_reset_pressed):
		btn_reset.pressed.connect(_on_reset_pressed)
	if _records_mgr and not _records_mgr.records_updated.is_connected(_sync_display):
		_records_mgr.records_updated.connect(_sync_display)

func _sync_display() -> void:
	if not _records_mgr:
		return

	var total: int = _records_mgr.get_stat("total_matches", 0)
	var wins: int = _records_mgr.get_stat("wins", 0)
	var losses: int = _records_mgr.get_stat("losses", 0)
	var winrate: float = _records_mgr.get_win_rate()
	var parries: int = _records_mgr.get_stat("parries_executed", 0)
	var ringouts: int = _records_mgr.get_stat("ring_outs", 0)
	var meltdowns: int = _records_mgr.get_stat("meltdowns_triggered", 0)
	var fav_char: String = String(_records_mgr.get_stat("favorite_character", "viper")).to_upper()

	if matches_label:
		matches_label.text = str(total)
	if winloss_label:
		winloss_label.text = "%d W / %d L" % [wins, losses]
	if winrate_label:
		winrate_label.text = "%.1f%%" % winrate
	if parry_label:
		parry_label.text = str(parries)
	if ringout_label:
		ringout_label.text = str(ringouts)
	if meltdown_label:
		meltdown_label.text = str(meltdowns)
	if fav_char_label:
		fav_char_label.text = fav_char

func open() -> void:
	_sync_display()
	show()
	if btn_close:
		btn_close.grab_focus()

func _on_close_pressed() -> void:
	MenuAudio.play_cancel_chime(self)
	closed.emit()
	hide()

func _on_reset_pressed() -> void:
	MenuAudio.play_confirm_chime(self)
	_records_mgr.reset_records()
	_sync_display()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
