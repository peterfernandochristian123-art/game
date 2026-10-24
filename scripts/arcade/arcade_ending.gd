class_name ArcadeEnding
extends Control

## Layar Tamat & Evaluasi Peringkat Arcade Gauntlet (Story 15.4)
## Menghitung skor akhir, memberikan peringkat S/A/B/C,
## menampilkan epilog cerita karakter unik, dan mencatat rekor ke RecordsManager.

const DialogueDBScript = preload("res://scripts/arcade/dialogue_db.gd")
const RecordsManagerScript = preload("res://scripts/core/records_manager.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

@onready var rank_label: Label = $CenterContainer/Panel/Margin/VBox/RankBox/RankLabel
@onready var rank_title_label: Label = $CenterContainer/Panel/Margin/VBox/RankBox/RankTitleLabel
@onready var score_label: Label = $CenterContainer/Panel/Margin/VBox/StatsGrid/ScoreVal
@onready var time_label: Label = $CenterContainer/Panel/Margin/VBox/StatsGrid/TimeVal
@onready var continues_label: Label = $CenterContainer/Panel/Margin/VBox/StatsGrid/ContinuesVal
@onready var parries_label: Label = $CenterContainer/Panel/Margin/VBox/StatsGrid/ParriesVal
@onready var ringouts_label: Label = $CenterContainer/Panel/Margin/VBox/StatsGrid/RingoutsVal

@onready var epilogue_headline: Label = $CenterContainer/Panel/Margin/VBox/EpilogueBox/HeadlineLabel
@onready var epilogue_body: Label = $CenterContainer/Panel/Margin/VBox/EpilogueBox/BodyLabel

@onready var btn_play_again: Button = $CenterContainer/Panel/Margin/VBox/HBoxButtons/BtnPlayAgain
@onready var btn_main_menu: Button = $CenterContainer/Panel/Margin/VBox/HBoxButtons/BtnMainMenu

static var last_run_stats: Dictionary = {
	"character": &"viper",
	"clear_time": 180.0,
	"continues": 0,
	"parries": 5,
	"ring_outs": 2
}

func _ready() -> void:
	_setup_buttons()
	display_run_results(last_run_stats)

func _setup_buttons() -> void:
	if btn_play_again:
		btn_play_again.pressed.connect(_on_play_again)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu)

static func evaluate_run(time_sec: float, continues: int, parries: int, ring_outs: int) -> Dictionary:
	var base_score := 1000000
	var time_bonus: int = maxi(0, int((300.0 - time_sec) * 1500))
	var continue_penalty: int = continues * 150000
	var parry_bonus: int = parries * 25000
	var ringout_bonus: int = ring_outs * 50000

	var total_score: int = maxi(50000, base_score + time_bonus + parry_bonus + ringout_bonus - continue_penalty)

	var rank_str := "C"
	var rank_title := "SURVIVOR PILOT"
	var rank_color := Color(0.7, 0.7, 0.7, 1.0)

	if continues == 0 and time_sec <= 240.0 and parries >= 4:
		rank_str = "S"
		rank_title = "CYBER CHAMPION (PERFECT)"
		rank_color = Color(1.0, 0.85, 0.2, 1.0) # Gold
	elif continues <= 1 and time_sec <= 360.0:
		rank_str = "A"
		rank_title = "ACE GLADIATOR"
		rank_color = Color(0.2, 0.95, 1.0, 1.0) # Neon Cyan
	elif continues <= 2:
		rank_str = "B"
		rank_title = "VETERAN DUELIST"
		rank_color = Color(0.4, 0.9, 0.4, 1.0) # Green
	else:
		rank_str = "C"
		rank_title = "SURVIVOR PILOT"
		rank_color = Color(0.9, 0.5, 0.3, 1.0) # Orange

	return {
		"rank": rank_str,
		"title": rank_title,
		"color": rank_color,
		"score": total_score
	}

func display_run_results(stats: Dictionary) -> void:
	var char_id: StringName = stats.get("character", &"viper")
	var time_sec: float = stats.get("clear_time", 180.0)
	var continues: int = stats.get("continues", 0)
	var parries: int = stats.get("parries", 0)
	var ring_outs: int = stats.get("ring_outs", 0)

	var eval := evaluate_run(time_sec, continues, parries, ring_outs)

	# Tampilkan Rank & Title
	if rank_label:
		rank_label.text = eval["rank"]
		rank_label.add_theme_color_override("font_color", eval["color"])
	if rank_title_label:
		rank_title_label.text = eval["title"]
		rank_title_label.add_theme_color_override("font_color", eval["color"])

	# Tampilkan Statistik
	if score_label:
		score_label.text = "%d PTS" % eval["score"]
	if time_label:
		var mins := int(time_sec) / 60
		var secs := int(time_sec) % 60
		time_label.text = "%02d:%02d" % [mins, secs]
	if continues_label:
		continues_label.text = "%d" % continues
	if parries_label:
		parries_label.text = "%d" % parries
	if ringouts_label:
		ringouts_label.text = "%d" % ring_outs

	# Tampilkan Epilog Cerita
	var epilogue := DialogueDBScript.get_epilogue(char_id)
	if epilogue_headline:
		epilogue_headline.text = epilogue["headline"]
		var char_info: Dictionary = DialogueDBScript.PORTRAITS.get(char_id, {})
		if char_info.has("theme_color"):
			epilogue_headline.add_theme_color_override("font_color", char_info["theme_color"])
	if epilogue_body:
		epilogue_body.text = epilogue["body"]

	# Simpan ke RecordsManager
	RecordsManager.get_instance().record_arcade_clear(char_id, eval["rank"], time_sec)

func _on_play_again() -> void:
	MenuAudio.play_confirm_chime(self)
	MatchConfigScript.set_mode(&"arcade")
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_main_menu() -> void:
	MenuAudio.play_confirm_chime(self)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
