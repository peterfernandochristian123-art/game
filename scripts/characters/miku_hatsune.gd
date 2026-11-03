class_name MikuHatsune
extends BaseMecha

## Petarung Roster: Miku Hatsune
## Class: Vocaloid / Idol
## Kecepatan Jalan: 350 px/s, Dash: 820 px/s
## Total HP: 880 (High-Speed Striker / Rhythm Duelist)

var rhythm_overdrive_frames: int = 0
var frequency_barrier_frames: int = 0

func _init() -> void:
	max_hp = 880
	current_hp = max_hp
	walk_speed = 350.0

func _ready() -> void:
	max_hp = 880
	current_hp = max_hp
	walk_speed = 350.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/viper_jab.tres"),
		&"5L1": preload("res://resources/attacks/viper_jab.tres"),
		&"5L2": preload("res://resources/attacks/viper_thrust.tres"),
		&"5H": preload("res://resources/attacks/viper_cleave.tres"),
		&"Skill1": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"RhythmDash": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"Skill2": preload("res://resources/attacks/viper_deflection_matrix.tres"),
		&"FrequencyBarrier": preload("res://resources/attacks/viper_deflection_matrix.tres"),
		&"Ultimate": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"WorldIsMine": preload("res://resources/attacks/viper_blink_slash.tres")
	}

	vfx_profile = preload("res://resources/vfx_profiles/miku.tres")

	super._ready()

	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.0, 0.9, 0.95, 1.0)

func get_dash_speed() -> float:
	if is_overdrive_active():
		return 820.0 * 1.25
	return 820.0

func get_dash_duration() -> int:
	return 12

func is_overdrive_active() -> bool:
	return rhythm_overdrive_frames > 0

func add_heat(amount: float) -> void:
	if is_overdrive_active():
		if heat_component:
			heat_component.current_heat = 0.0
		heat_gauge = 0.0
		return
	super.add_heat(amount)

func execute_skill_1() -> void:
	# Skill 1: Rhythm Dash (Sonic Twintail Slice)
	var teleport_distance: float = 380.0 * float(facing_direction)
	global_position.x += teleport_distance
	request_attack_by_name(&"RhythmDash")

func execute_skill_2() -> void:
	# Skill 2: Frequency Barrier (Holographic Sound Wall)
	frequency_barrier_frames = 30
	request_attack_by_name(&"FrequencyBarrier")

func execute_ultimate() -> void:
	# Ultimate: World is Mine Protocol
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	rhythm_overdrive_frames = 480 # 8 Detik
	if heat_component:
		heat_component.current_heat = 0.0
	heat_gauge = 0.0
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"WorldIsMine", global_position, facing_direction)

func _physics_process(delta: float) -> void:
	if rhythm_overdrive_frames > 0:
		rhythm_overdrive_frames -= 1
		can_air_dash = true
		if heat_component:
			heat_component.current_heat = 0.0
		heat_gauge = 0.0

	if frequency_barrier_frames > 0:
		frequency_barrier_frames -= 1

	super._physics_process(delta)

func get_archetype() -> StringName:
	return &"miku"
