class_name BossUnitZero
extends BaseMecha

## Final Boss Mecha: Unit-0 "Shadow Core" (Story 15.3)
## Archetype: Unbound Overclock Proto-Core / Final Boss
## Karakteristik: HP 1500, Kecepatan Jalan 340 px/s, Dash 880 px/s,
## Permanent Overclock Zone (90% Heat) dengan 1-Hit Super Armor pada startup dan +20% Damage Buff.

var _glow_phase: float = 0.0

func _init() -> void:
	max_hp = 1500
	current_hp = 1500
	walk_speed = 340.0
	passive_damage_reduction = 0.10 # 10% Boss Armor

func _ready() -> void:
	max_hp = 1500
	current_hp = 1500
	walk_speed = 340.0
	passive_damage_reduction = 0.10

	attack_resources = {
		&"5L": preload("res://resources/attacks/viper_cleave.tres"),
		&"5H": preload("res://resources/attacks/kage_cleave.tres"),
		&"Skill1": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"BlinkSlash": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"Skill2": preload("res://resources/attacks/kage_shuriken_storm.tres"),
		&"ShurikenStorm": preload("res://resources/attacks/kage_shuriken_storm.tres"),
		&"Ultimate": preload("res://resources/attacks/kage_shadow_blossom.tres"),
		&"ShadowBlossom": preload("res://resources/attacks/kage_shadow_blossom.tres")
	}

	super._ready()

	# Lock heat to 90% (Overclock Zone tanpa meltdown)
	heat_gauge = 90.0
	if heat_component:
		heat_component.current_heat = 90.0
		heat_component._is_overclocked = true

	# Visualisasi Boss: Chassis Hitam / Crimson Aura
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(1.2, 0.1, 0.25, 1.0) # Intense Crimson Glitch

	if OS.is_debug_build():
		print("[BOSS][UnitZero] Unit-0 Shadow Core aktif! HP: %d, Armor: %.0f%%, Heat: %.1f%%." % [
			max_hp, passive_damage_reduction * 100.0, heat_gauge
		])

func _physics_process(delta: float) -> void:
	# Pastikan suhu selalu terkunci pada 90.0% (Overclock aktif permanen)
	heat_gauge = 90.0
	if heat_component:
		heat_component.current_heat = 90.0

	super._physics_process(delta)

	# Efek visual pulsing aura crimson / purple
	_glow_phase += delta * 6.0
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			var pulse: float = 0.9 + 0.3 * sin(_glow_phase)
			spr.modulate = Color(1.2 * pulse, 0.1 * pulse, 0.35 * pulse, 1.0)

func get_archetype() -> StringName:
	return &"unit_zero"

func get_dash_speed() -> float:
	return 880.0

func get_dash_duration() -> int:
	return 12

func execute_skill_1() -> void:
	request_attack_by_name(&"Skill1")

func execute_skill_2() -> void:
	request_attack_by_name(&"Skill2")

func execute_ultimate() -> void:
	request_attack_by_name(&"Ultimate")
