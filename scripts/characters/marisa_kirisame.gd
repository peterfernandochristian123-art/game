class_name MarisaKirisame
extends BaseMecha

## Petarung Roster: Marisa Kirisame
## Class: Wizard
## Kecepatan Jalan: 330 px/s, Dash: 780 px/s
## Total HP: 900 (High Range / Star Magic Cannon)

func _init() -> void:
	max_hp = 900
	current_hp = max_hp
	walk_speed = 330.0

func _ready() -> void:
	max_hp = 900
	current_hp = max_hp
	walk_speed = 330.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/pulsar_pulse.tres"),
		&"5L1": preload("res://resources/attacks/pulsar_pulse.tres"),
		&"5L2": preload("res://resources/attacks/pulsar_lance.tres"),
		&"5H": preload("res://resources/attacks/pulsar_lance.tres"),
		&"Skill1": preload("res://resources/attacks/pulsar_disrupter_drone.tres"),
		&"LeylineDash": preload("res://resources/attacks/pulsar_disrupter_drone.tres"),
		&"Skill2": preload("res://resources/attacks/pulsar_photon_railgun.tres"),
		&"StarlightTyphoon": preload("res://resources/attacks/pulsar_photon_railgun.tres"),
		&"Ultimate": preload("res://resources/attacks/pulsar_supernova.tres"),
		&"FinalMasterSpark": preload("res://resources/attacks/pulsar_supernova.tres")
	}

	super._ready()

func get_dash_speed() -> float:
	return 780.0

func get_dash_duration() -> int:
	return 13

func execute_skill_1() -> void:
	# Skill 1: Witch Leyline Dash (Broom Flight Rush)
	velocity.x = 850.0 * float(facing_direction)
	request_attack_by_name(&"LeylineDash")

func execute_skill_2() -> void:
	# Skill 2: Starlight Typhoon (Linear Photon Star Blast)
	request_attack_by_name(&"StarlightTyphoon")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"StarlightTyphoon", global_position, facing_direction)

func execute_ultimate() -> void:
	# Ultimate: Final Master Spark (Giant Screen-Filling Laser)
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	request_attack_by_name(&"FinalMasterSpark")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"FinalMasterSpark", global_position, facing_direction)

func get_archetype() -> StringName:
	return &"marisa"
