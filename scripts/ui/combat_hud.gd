class_name CombatHUD
extends Control

## Pengendali HUD Pertarungan Retro 32-Bit (Story 5.3 & Skill Command Dock Update)
## Menampilkan HP Bar simetris real-time, Heat Gauge dinamis (Nominal/Overclock/Meltdown),
## Ultimate Meter, Round Countdown Timer 90s, Indikator Ronde Menang,
## serta Dock Perintah Skill interaktif dengan petunjuk tombol [U, I, O, J, K, L, X] real-time.

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

# Skill & Command Keybind Dock Nodes
var skill_dock: PanelContainer = null
var skill1_card: Control = null
var skill1_badge: Label = null
var skill1_name_label: Label = null
var skill2_card: Control = null
var skill2_badge: Label = null
var skill2_name_label: Label = null
var ultimate_badge: Label = null
var ultimate_name_label: Label = null
var ultimate_card: Control = null
var current_p1_ult_name: String = "ABSOLUTE ZERO"
var _hud_time: float = 0.0

var p1_fighter: Node2D = null
var p2_fighter: Node2D = null
var match_manager: Node = null
var is_sudden_death: bool = false

func _ready() -> void:
	update_round_wins(0, 0)
	update_timer(90.0)
	_setup_skill_command_dock()
	if is_instance_valid(EventBus) and EventBus.has_signal("skill_cast"):
		EventBus.skill_cast.connect(_on_hud_skill_cast)

func _process(delta: float) -> void:
	_hud_time += delta
	# Pulsing glow animation untuk Ultimate Card saat 100% siap
	if ultimate_card and p1_ultimate_bar and p1_ultimate_bar.value >= p1_ultimate_bar.max_value:
		var pulse: float = 0.85 + 0.35 * sin(_hud_time * 6.0)
		ultimate_card.modulate = Color(1.0 + pulse * 0.3, 1.0 + pulse * 0.3, 0.9 + pulse * 0.1, 1.0)

func _on_hud_skill_cast(caster: Node2D, skill_name: StringName, _pos: Vector2, _facing: int) -> void:
	if caster != p1_fighter and (not is_instance_valid(p1_fighter) or caster.name != p1_fighter.name):
		return
	var s_name := String(skill_name).to_lower()
	if s_name.contains("blink") or s_name.contains("piledriver") or s_name.contains("railgun") or s_name.contains("stance") or s_name.contains("shockwave") or s_name == "skill1":
		_flash_card(skill1_card)
	elif s_name.contains("deflection") or s_name.contains("shield") or s_name.contains("drone") or s_name.contains("iaido") or s_name.contains("shuriken") or s_name.contains("cataclysm") or s_name == "skill2":
		_flash_card(skill2_card)
	elif s_name.contains("ultimate") or s_name.contains("protocol") or s_name.contains("cannon") or s_name.contains("supernova") or s_name.contains("blossom") or s_name.contains("overload"):
		_flash_card(ultimate_card)

func _flash_card(card: Control) -> void:
	if not card:
		return
	var tween := create_tween()
	card.modulate = Color(1.8, 1.8, 1.8, 1.0)
	tween.tween_property(card, "modulate", Color.WHITE, 0.35)


func _setup_skill_command_dock() -> void:
	if skill_dock != null:
		return

	skill_dock = PanelContainer.new()
	skill_dock.name = "SkillCommandDock"
	skill_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_dock.layout_mode = 1
	skill_dock.anchors_preset = Control.PRESET_BOTTOM_WIDE
	skill_dock.anchor_left = 0.5
	skill_dock.anchor_right = 0.5
	skill_dock.anchor_top = 1.0
	skill_dock.anchor_bottom = 1.0
	skill_dock.offset_left = -312.0
	skill_dock.offset_right = 312.0
	skill_dock.offset_top = -32.0
	skill_dock.offset_bottom = -4.0
	skill_dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	skill_dock.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.9)
	style.border_color = Color(0.2, 0.7, 0.95, 0.6)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	skill_dock.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	skill_dock.add_child(hbox)

	# 1. Skill 1 Card [U]
	var s1_box := _create_skill_card("[ U ]", "SKILL 1", "BLINK SLASH", Color(0.2, 0.95, 1.0))
	skill1_card = s1_box
	skill1_badge = s1_box.get_node("HBox/Badge") as Label
	skill1_name_label = s1_box.get_node("HBox/VBox/NameLabel") as Label
	hbox.add_child(s1_box)

	# 2. Skill 2 Card [I]
	var s2_box := _create_skill_card("[ I ]", "SKILL 2", "DEFLECTION MATRIX", Color(0.2, 0.95, 1.0))
	skill2_card = s2_box
	skill2_badge = s2_box.get_node("HBox/Badge") as Label
	skill2_name_label = s2_box.get_node("HBox/VBox/NameLabel") as Label
	hbox.add_child(s2_box)

	# 3. Ultimate Card [O]
	ultimate_card = _create_skill_card("[ O ]", "ULTIMATE", "ABSOLUTE ZERO (0%)", Color(1.0, 0.85, 0.2))
	ultimate_badge = ultimate_card.get_node("HBox/Badge") as Label
	ultimate_name_label = ultimate_card.get_node("HBox/VBox/NameLabel") as Label
	hbox.add_child(ultimate_card)

	# Separator
	var sep := VSeparator.new()
	sep.modulate = Color(0.3, 0.5, 0.7, 0.6)
	hbox.add_child(sep)

	# 4. Combat Keys Reference
	var keys_box := HBoxContainer.new()
	keys_box.alignment = BoxContainer.ALIGNMENT_CENTER
	keys_box.add_theme_constant_override("separation", 6)

	var combat_hints := [
		{"key": "[J/Z]", "act": "LIGHT"},
		{"key": "[K/C]", "act": "HEAVY"},
		{"key": "[L]", "act": "PARRY"},
		{"key": "[X/Shift]", "act": "DASH"},
		{"key": "[Space]", "act": "JUMP"},
		{"key": "[H]", "act": "HINT"}
	]

	for h in combat_hints:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		var k_lbl := Label.new()
		k_lbl.text = h["key"]
		k_lbl.add_theme_font_size_override("font_size", 7)
		k_lbl.modulate = Color(1.0, 0.9, 0.35)
		item.add_child(k_lbl)

		var a_lbl := Label.new()
		a_lbl.text = h["act"]
		a_lbl.add_theme_font_size_override("font_size", 7)
		a_lbl.modulate = Color(0.75, 0.85, 0.95)
		item.add_child(a_lbl)
		keys_box.add_child(item)

	hbox.add_child(keys_box)

	add_child(skill_dock)

func _create_skill_card(key_text: String, slot_text: String, move_text: String, theme_col: Color) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(108, 24)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.1, 0.16, 0.8)
	card_style.border_color = theme_col * Color(1, 1, 1, 0.6)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 3
	card_style.corner_radius_top_right = 3
	card_style.corner_radius_bottom_left = 3
	card_style.corner_radius_bottom_right = 3
	card_style.content_margin_left = 4.0
	card_style.content_margin_right = 4.0
	card_style.content_margin_top = 1.0
	card_style.content_margin_bottom = 1.0
	card.add_theme_stylebox_override("panel", card_style)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	card.add_child(hbox)

	var badge := Label.new()
	badge.name = "Badge"
	badge.text = key_text
	badge.add_theme_font_size_override("font_size", 8)
	badge.modulate = Color(1.0, 0.9, 0.3)
	hbox.add_child(badge)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -2)
	hbox.add_child(vbox)

	var slot_lbl := Label.new()
	slot_lbl.name = "SlotLabel"
	slot_lbl.text = slot_text
	slot_lbl.add_theme_font_size_override("font_size", 6)
	slot_lbl.modulate = Color(0.65, 0.75, 0.85)
	vbox.add_child(slot_lbl)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = move_text
	name_lbl.add_theme_font_size_override("font_size", 7)
	name_lbl.modulate = theme_col
	vbox.add_child(name_lbl)

	return card

func set_p1_skills(s1_name: String, s2_name: String, ult_name: String, col: Color = Color.CYAN) -> void:
	current_p1_ult_name = ult_name
	if skill1_name_label:
		skill1_name_label.text = s1_name
		skill1_name_label.modulate = col
	if skill2_name_label:
		skill2_name_label.text = s2_name
		skill2_name_label.modulate = col
	if ultimate_name_label:
		ultimate_name_label.text = "%s (0%%)" % ult_name
		ultimate_name_label.modulate = col

func _detect_and_bind_p1_skills(fighter: Node2D) -> void:
	if not is_instance_valid(fighter):
		return

	var f_name := fighter.name.to_lower()
	var arch: String = ""
	if fighter.has_method("get_archetype"):
		arch = String(fighter.get_archetype()).to_lower()
	elif "archetype" in fighter:
		arch = String(fighter.get("archetype")).to_lower()

	if arch.contains("viper") or f_name.contains("viper"):
		set_p1_skills("BLINK SLASH", "DEFLECTION MATRIX", "ABSOLUTE ZERO", Color(0.2, 0.95, 1.0))
	elif arch.contains("bulwark") or f_name.contains("bulwark") or arch.contains("titan") or f_name.contains("titan"):
		set_p1_skills("HYDRAULIC PILEDRIVER", "RIOT SHIELD", "ORBITAL SIEGE CANNON", Color(1.0, 0.55, 0.15))
	elif arch.contains("pulsar") or f_name.contains("pulsar"):
		set_p1_skills("PHOTON RAILGUN", "DISRUPTER DRONE", "SUPERNOVA HORIZON", Color(0.75, 0.25, 1.0))
	elif arch.contains("kage") or f_name.contains("kage"):
		set_p1_skills("STANCE SHIFT", "IAIDO CRESCENT", "SHADOW BLOSSOM", Color(1.0, 0.15, 0.25))
		if fighter.has_signal("stance_changed") and not fighter.stance_changed.is_connected(_on_kage_stance_changed):
			fighter.stance_changed.connect(_on_kage_stance_changed)
	elif f_name.contains("boss") or f_name.contains("unit_zero"):
		set_p1_skills("SHADOW SHOCKWAVE", "CATACLYSM SLASH", "ZERO OVERLOAD", Color(1.1, 0.1, 0.3))
	else:
		set_p1_skills("SPECIAL SKILL 1", "SPECIAL SKILL 2", "OVERCLOCK PROTOCOL", Color(0.2, 0.95, 1.0))

func _on_kage_stance_changed(new_stance: StringName) -> void:
	if skill2_name_label:
		if String(new_stance) == "shinobi":
			skill2_name_label.text = "SHURIKEN STORM"
		else:
			skill2_name_label.text = "IAIDO CRESCENT"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_H:
			if skill_dock:
				skill_dock.visible = !skill_dock.visible

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

		_detect_and_bind_p1_skills(p1_fighter)

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

	# Update dock ultimate card
	if ultimate_name_label:
		if is_max:
			ultimate_name_label.text = "★ READY ★ " + current_p1_ult_name
			ultimate_name_label.modulate = COLOR_ULTIMATE_MAX
			if ultimate_badge:
				ultimate_badge.text = "[ O ] READY!"
				ultimate_badge.modulate = COLOR_ULTIMATE_MAX
			if ultimate_card:
				ultimate_card.modulate = Color(1.2, 1.2, 1.0, 1.0)
		else:
			ultimate_name_label.text = "%s (%d%%)" % [current_p1_ult_name, int(current)]
			ultimate_name_label.modulate = Color(1.0, 0.85, 0.2)
			if ultimate_badge:
				ultimate_badge.text = "[ O ]"
				ultimate_badge.modulate = Color(1.0, 0.9, 0.3)
			if ultimate_card:
				ultimate_card.modulate = Color(1.0, 1.0, 1.0, 1.0)

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
