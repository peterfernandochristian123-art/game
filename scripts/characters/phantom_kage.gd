class_name PhantomKage
extends BaseMecha

## Petarung Mecha: Phantom-9 "Kage" (Story 13.1)
## Archetype: Stance Switcher / Stealth Ninja Mecha
## Kecepatan Jalan: 320 px/s, Dash: 780 px/s (14 frame)
## Total HP: 920 HP, Mekanik: Dual Stance (Kenjutsu Katana vs Shinobi Shuriken)

signal stance_changed(new_stance: StringName)
signal iaido_strike_executed()
signal shuriken_storm_thrown()
signal shadow_blossom_executed()

var current_stance: StringName = &"kenjutsu" # &"kenjutsu" (Melee Katana) atau &"shinobi" (Ranged Shurikens)

var _res_katana_5L = preload("res://resources/attacks/kage_slash.tres")
var _res_katana_5H = preload("res://resources/attacks/kage_cleave.tres")
var _res_shinobi_5L = preload("res://resources/attacks/kage_kunai.tres")
var _res_shinobi_5H = preload("res://resources/attacks/kage_kunai_flurry.tres")
var _res_stance_shift = preload("res://resources/attacks/kage_stance_shift.tres")
var _res_iaido_crescent = preload("res://resources/attacks/kage_iaido_strike.tres")
var _res_shuriken_storm = preload("res://resources/attacks/kage_shuriken_storm.tres")
var _res_shadow_blossom = preload("res://resources/attacks/kage_shadow_blossom.tres")

func _init() -> void:
	max_hp = CombatConstants.KAGE_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.KAGE_WALK_SPEED

func _ready() -> void:
	max_hp = CombatConstants.KAGE_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.KAGE_WALK_SPEED

	_sync_stance_moves()

	super._ready()

	# Modulasi warna visual Kage jika ada visual sprite fallback
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.95, 0.15, 0.25, 1.0) # Crimson Red

	if OS.is_debug_build():
		print("[CHARACTER][PhantomKage] Phantom-9 Kage diinisialisasi. HP: %d, Jalan: %.1f px/s, Dash: %.1f px/s. Stance Awal: %s." % [
			max_hp, walk_speed, get_dash_speed(), current_stance
		])

func get_archetype() -> StringName:
	return &"kage"

func get_dash_speed() -> float:
	return CombatConstants.KAGE_DASH_SPEED

func get_dash_duration() -> int:
	return CombatConstants.KAGE_DASH_DURATION_FRAMES

func _sync_stance_moves() -> void:
	if current_stance == &"kenjutsu":
		attack_resources[&"5L"] = _res_katana_5L
		attack_resources[&"5H"] = _res_katana_5H
		attack_resources[&"Skill2"] = _res_iaido_crescent
		attack_resources[&"IaidoCrescent"] = _res_iaido_crescent
	else:
		attack_resources[&"5L"] = _res_shinobi_5L
		attack_resources[&"5H"] = _res_shinobi_5H
		attack_resources[&"Skill2"] = _res_shuriken_storm
		attack_resources[&"ShurikenStorm"] = _res_shuriken_storm

	attack_resources[&"Skill1"] = _res_stance_shift
	attack_resources[&"StanceShift"] = _res_stance_shift
	attack_resources[&"Ultimate"] = _res_shadow_blossom
	attack_resources[&"ShadowBlossom"] = _res_shadow_blossom

func set_stance(new_stance: StringName) -> void:
	if current_stance == new_stance:
		return
	current_stance = new_stance
	_sync_stance_moves()
	stance_changed.emit(current_stance)

func execute_skill_1() -> void:
	# Skill 1: Stance Shift & Shadow Feint
	invulnerability_frames = CombatConstants.KAGE_STANCE_FEINT_FRAMES
	var atk = attack_resources.get(&"Skill1")
	if atk:
		request_attack(atk)

	# Pergantian Stance: Kenjutsu <-> Shinobi
	if current_stance == &"kenjutsu":
		set_stance(&"shinobi")
	else:
		set_stance(&"kenjutsu")

func execute_skill_2() -> void:
	var atk = attack_resources.get(&"Skill2")
	if atk:
		request_attack(atk)
		if current_stance == &"kenjutsu":
			iaido_strike_executed.emit()
		else:
			shuriken_storm_thrown.emit()

func execute_ultimate() -> void:
	var atk = attack_resources.get(&"Ultimate")
	if atk:
		invulnerability_frames = 16
		request_attack(atk)
		shadow_blossom_executed.emit()
