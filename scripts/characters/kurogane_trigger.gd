class_name KuroganeTrigger
extends BaseMecha

## Petarung Mecha: Kurogane "Trigger"
## Archetype: Cyber-Gunslinger / Dual Energy Revolver Acrobat
## Kecepatan Jalan: 340 px/s, Dash: 820 px/s (12 frame)
## Total HP: 940 HP, Spesialisasi Ricochet Shots, Evasive Rolling, & Bullet Hell

signal ricochet_shot_fired(origin: Vector2, direction: int)
signal gunslinger_roll_started(direction: int)
signal bullet_hell_executed()

func _init() -> void:
	max_hp = 940
	current_hp = max_hp
	walk_speed = 340.0

func _ready() -> void:
	max_hp = 940
	current_hp = max_hp
	walk_speed = 340.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/trigger_shot.tres"),
		&"5H": preload("res://resources/attacks/trigger_magnum.tres"),
		&"Skill1": preload("res://resources/attacks/trigger_ricochet.tres"),
		&"RicochetShot": preload("res://resources/attacks/trigger_ricochet.tres"),
		&"Skill2": preload("res://resources/attacks/trigger_roll.tres"),
		&"GunslingerRoll": preload("res://resources/attacks/trigger_roll.tres"),
		&"Ultimate": preload("res://resources/attacks/trigger_bullet_hell.tres"),
		&"BulletHellZero": preload("res://resources/attacks/trigger_bullet_hell.tres")
	}

	super._ready()

	# Warna visual khas Trigger: Amber Gold / Molten Orange
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.95, 0.65, 0.15, 1.0)

	if OS.is_debug_build():
		print("[CHARACTER][KuroganeTrigger] Kurogane Trigger diinisialisasi. HP: %d, Jalan: %.1f px/s, Dash: %.1f px/s." % [
			max_hp, walk_speed, get_dash_speed()
		])

func get_archetype() -> StringName:
	return &"trigger"

func get_dash_speed() -> float:
	return 820.0

func get_dash_duration() -> int:
	return 12

func execute_skill_1() -> void:
	var atk = attack_resources.get(&"Skill1")
	if atk:
		request_attack(atk)
	ricochet_shot_fired.emit(global_position + Vector2(facing_direction * 40.0, -25.0), facing_direction)

func execute_skill_2() -> void:
	invulnerability_frames = 14
	velocity.x = float(facing_direction) * 650.0
	var atk = attack_resources.get(&"Skill2")
	if atk:
		request_attack(atk)
	gunslinger_roll_started.emit(facing_direction)

func execute_ultimate() -> void:
	invulnerability_frames = 20
	var atk = attack_resources.get(&"Ultimate")
	if atk:
		request_attack(atk)
	bullet_hell_executed.emit()
