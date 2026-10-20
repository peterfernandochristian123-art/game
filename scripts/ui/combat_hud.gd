class_name CombatHUD
extends Control

## Pengendali HUD Pertarungan Retro 32-Bit (Story 5.3)
## Menampilkan HP Bar simetris real-time, Heat Gauge dinamis (Nominal/Overclock/Meltdown),
## Ultimate Meter, Round Countdown Timer 90s, dan Indikator Ronde Menang

const COLOR_HP_HEALTHY := Color(0.2, 0.95, 0.4, 1.0) # Hijau neon
const COLOR_HP_WARN := Color(1.0, 0.85, 0.2, 1.0)    # Kuning
const COLOR_HP_CRITICAL := Color(1.0, 0.25, 0.25, 1.0) # Merah

const COLOR_HEAT_NOMINAL := Color(0.15, 0.85, 0.95, 1.0) # Cyan
const COLOR_HEAT_OVERCLOCK := Color(1.0, 0.2, 0.1, 1.0)  # Merah Menyala
const COLOR_HEAT_MELTDOWN := Color(0.65, 0.25, 0.85, 0.7) # Ungu Pudar

const COLOR_ULTIMATE_CHARGING := Color(1.0, 0.75, 0.15, 1.0) # Gold Amber
const COLOR_ULTIMATE_MAX := Color(0.3, 1.0, 0.9, 1.0)       # Cyan Flash

# P1 UI Nodes
@onready var p1_name_label: Label = $TopBar/P1Panel/NameLabel
@onready var p1_hp_bar: ProgressBar = $TopBar/P1Panel/HPBar
@onready var p1_hp_text: Label = $TopBar/P1Panel/HPBar/HPText
@onready var p1_heat_bar: ProgressBar = $TopBar/P1Panel/HeatBar
@onready var p1_heat_text: Label = $TopBar/P1Panel/HeatBar/HeatText
@onready var p1_ultimate_bar: ProgressBar = $TopBar/P1Panel/UltimateBar
@onready var p1_ultimate_text: Label = $TopBar/P1Panel/UltimateBar/UltimateText
@onready var p1_win1: ColorRect = $TopBar/CenterPanel/P1Wins/Win1
@onready var p1_win2: ColorRect = $TopBar/CenterPanel/P1Wins/Win2

# P2 UI Nodes
@onready var p2_name_label: Label = $TopBar/P2Panel/NameLabel
@onready var p2_hp_bar: ProgressBar = $TopBar/P2Panel/HPBar
@onready var p2_hp_text: Label = $TopBar/P2Panel/HPBar/HPText
@onready var p2_heat_bar: ProgressBar = $TopBar/P2Panel/HeatBar
@onready var p2_heat_text: Label = $TopBar/P2Panel/HeatBar/HeatText
@onready var p2_ultimate_bar: ProgressBar = $TopBar/P2Panel/UltimateBar
@onready var p2_ultimate_text: Label = $TopBar/P2Panel/UltimateBar/UltimateText
@onready var p2_win1: ColorRect = $TopBar/CenterPanel/P2Wins/Win1
@onready var p2_win2: ColorRect = $TopBar/CenterPanel/P2Wins/Win2

# Center Panel Nodes
@onready var timer_label: Label = $TopBar/CenterPanel/TimerLabel
@onready var round_label: Label = $TopBar/CenterPanel/RoundLabel

var p1_fighter: Node2D = null
var p2_fighter: Node2D = null
var match_manager: Node = null
var is_sudden_death: bool = false

func _ready() -> void:
	update_round_wins(0, 0)
	update_timer(90.0)

func bind_fighters(p1: Node2D, p2: Node2D, mm: Node = null) -> void:
	p1_fighter = p1
	p2_fighter = p2
	match_manager = mm

	if p1_fighter:
		if p1_fighter.has_signal("hp_changed"):
			p1_fighter.hp_changed.connect(update_p1_hp)
		if p1_fighter.has_signal("heat_changed"):
			p1_fighter.heat_changed.connect(update_p1_heat)
		if p1_fighter.has_signal("ultimate_changed"):
			p1_fighter.ultimate_changed.connect(update_p1_ultimate)

		# Initial values
		var max_h: int = p1_fighter.get("max_hp") if "max_hp" in p1_fighter else 1000
		var cur_h: int = p1_fighter.get("current_hp") if "current_hp" in p1_fighter else max_h
		update_p1_hp(cur_h, max_h)

		var cur_heat: float = p1_fighter.get("heat_gauge") if "heat_gauge" in p1_fighter else 0.0
		update_p1_heat(cur_heat, 100.0)

		var cur_ult: float = p1_fighter.get("current_ultimate") if "current_ultimate" in p1_fighter else 0.0
		update_p1_ultimate(cur_ult, 100.0)

		if p1_name_label:
			p1_name_label.text = "P1 // " + p1_fighter.name.to_upper()

	if p2_fighter:
		if p2_fighter.has_signal("hp_changed"):
			p2_fighter.hp_changed.connect(update_p2_hp)
		if p2_fighter.has_signal("heat_changed"):
			p2_fighter.heat_changed.connect(update_p2_heat)
		if p2_fighter.has_signal("ultimate_changed"):
			p2_fighter.ultimate_changed.connect(update_p2_ultimate)

		# Initial values
		var max_h: int = p2_fighter.get("max_hp") if "max_hp" in p2_fighter else 1000
		var cur_h: int = p2_fighter.get("current_hp") if "current_hp" in p2_fighter else max_h
		update_p2_hp(cur_h, max_h)

		var cur_heat: float = p2_fighter.get("heat_gauge") if "heat_gauge" in p2_fighter else 0.0
		update_p2_heat(cur_heat, 100.0)

		var cur_ult: float = p2_fighter.get("current_ultimate") if "current_ultimate" in p2_fighter else 0.0
		update_p2_ultimate(cur_ult, 100.0)

		if p2_name_label:
			p2_name_label.text = "P2 // " + p2_fighter.name.to_upper()

	if match_manager:
		if match_manager.has_signal("timer_updated"):
			match_manager.timer_updated.connect(update_timer)
		if match_manager.has_signal("round_started"):
			match_manager.round_started.connect(func(r_num):
				if round_label:
					round_label.text = "ROUND %d" % r_num
			)
		if match_manager.has_signal("round_ended"):
			match_manager.round_ended.connect(func(_w_id, _reason):
				var p1_w: int = match_manager.get("p1_wins") if "p1_wins" in match_manager else 0
				var p2_w: int = match_manager.get("p2_wins") if "p2_wins" in match_manager else 0
				update_round_wins(p1_w, p2_w)
			)
		if match_manager.has_signal("sudden_death_started"):
			match_manager.sudden_death_started.connect(set_sudden_death_mode)

func update_p1_hp(current: int, max_val: int) -> void:
	if not p1_hp_bar:
		return
	p1_hp_bar.max_value = max_val
	p1_hp_bar.value = current
	if p1_hp_text:
		p1_hp_text.text = "%d / %d" % [current, max_val]

	var ratio: float = float(current) / float(max(1, max_val))
	if ratio > 0.5:
		p1_hp_bar.modulate = COLOR_HP_HEALTHY
	elif ratio > 0.2:
		p1_hp_bar.modulate = COLOR_HP_WARN
	else:
		p1_hp_bar.modulate = COLOR_HP_CRITICAL

func update_p2_hp(current: int, max_val: int) -> void:
	if not p2_hp_bar:
		return
	p2_hp_bar.max_value = max_val
	p2_hp_bar.value = current
	if p2_hp_text:
		p2_hp_text.text = "%d / %d" % [current, max_val]

	var ratio: float = float(current) / float(max(1, max_val))
	if ratio > 0.5:
		p2_hp_bar.modulate = COLOR_HP_HEALTHY
	elif ratio > 0.2:
		p2_hp_bar.modulate = COLOR_HP_WARN
	else:
		p2_hp_bar.modulate = COLOR_HP_CRITICAL

func update_p1_heat(current: float, max_val: float = 100.0) -> void:
	if not p1_heat_bar:
		return
	p1_heat_bar.max_value = max_val
	p1_heat_bar.value = current

	var heat_color := _get_heat_zone_color(current)
	p1_heat_bar.modulate = heat_color

	if p1_heat_text:
		var status_tag: String = _get_heat_status_tag(current)
		p1_heat_text.text = "HEAT: %.1f%% %s" % [current, status_tag]

func update_p2_heat(current: float, max_val: float = 100.0) -> void:
	if not p2_heat_bar:
		return
	p2_heat_bar.max_value = max_val
	p2_heat_bar.value = current

	var heat_color := _get_heat_zone_color(current)
	p2_heat_bar.modulate = heat_color

	if p2_heat_text:
		var status_tag: String = _get_heat_status_tag(current)
		p2_heat_text.text = "HEAT: %.1f%% %s" % [current, status_tag]

func _get_heat_zone_color(heat: float) -> Color:
	if heat >= 100.0:
		return COLOR_HEAT_MELTDOWN
	elif heat >= 80.0:
		return COLOR_HEAT_OVERCLOCK
	else:
		return COLOR_HEAT_NOMINAL

func _get_heat_status_tag(heat: float) -> String:
	if heat >= 100.0:
		return "[MELTDOWN]"
	elif heat >= 80.0:
		return "[OVERCLOCK]"
	else:
		return ""

func update_p1_ultimate(current: float, max_val: float = 100.0) -> void:
	if not p1_ultimate_bar:
		return
	p1_ultimate_bar.max_value = max_val
	p1_ultimate_bar.value = current
	var is_max: bool = current >= max_val
	p1_ultimate_bar.modulate = COLOR_ULTIMATE_MAX if is_max else COLOR_ULTIMATE_CHARGING

	if p1_ultimate_text:
		p1_ultimate_text.text = "PROTOCOL READY (100%)" if is_max else "ULTIMATE: %d%%" % int(current)

func update_p2_ultimate(current: float, max_val: float = 100.0) -> void:
	if not p2_ultimate_bar:
		return
	p2_ultimate_bar.max_value = max_val
	p2_ultimate_bar.value = current
	var is_max: bool = current >= max_val
	p2_ultimate_bar.modulate = COLOR_ULTIMATE_MAX if is_max else COLOR_ULTIMATE_CHARGING

	if p2_ultimate_text:
		p2_ultimate_text.text = "PROTOCOL READY (100%)" if is_max else "ULTIMATE: %d%%" % int(current)

func update_timer(seconds_left: float) -> void:
	if not timer_label:
		return
	var secs: int = int(ceil(maxf(0.0, seconds_left)))
	timer_label.text = "%02d" % secs

	if secs <= 15:
		timer_label.modulate = Color(1.0, 0.2, 0.2, 1.0) # Merah berkedip saat kritis
	else:
		timer_label.modulate = Color(0.95, 0.98, 1.0, 1.0)

func update_round_wins(p1_wins: int, p2_wins: int) -> void:
	var color_won := Color(1.0, 0.85, 0.2, 1.0)
	var color_empty := Color(0.2, 0.25, 0.35, 0.5)

	if p1_win1:
		p1_win1.color = color_won if p1_wins >= 1 else color_empty
	if p1_win2:
		p1_win2.color = color_won if p1_wins >= 2 else color_empty

	if p2_win1:
		p2_win1.color = color_won if p2_wins >= 1 else color_empty
	if p2_win2:
		p2_win2.color = color_won if p2_wins >= 2 else color_empty

func set_sudden_death_mode() -> void:
	is_sudden_death = true
	if round_label:
		round_label.text = "SUDDEN DEATH"
		round_label.modulate = Color(1.0, 0.2, 0.1, 1.0)
