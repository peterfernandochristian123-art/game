class_name RayPulsar
extends BaseMecha

## Petarung Mecha: Ray-X "Pulsar" (Story 10.1)
## Archetype: Long-Range Zoner / Spatial Trap Disrupter
## Kecepatan Jalan: 300 px/s, Dash: 720 px/s (14 frame)
## Total HP: 950 HP, Spesialisasi Balistik Laser Foton & Drone Penutup Area

signal photon_railgun_fired(origin: Vector2, direction: int)
signal drone_deployed(position: Vector2)
signal supernova_executed()

var drone_frames_left: int = 0
var drone_position: Vector2 = Vector2.ZERO

func _init() -> void:
	max_hp = CombatConstants.PULSAR_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.PULSAR_WALK_SPEED

func _ready() -> void:
	max_hp = CombatConstants.PULSAR_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.PULSAR_WALK_SPEED

	attack_resources = {
		&"5L": preload("res://resources/attacks/pulsar_pulse.tres"),
		&"5H": preload("res://resources/attacks/pulsar_lance.tres"),
		&"Skill1": preload("res://resources/attacks/pulsar_photon_railgun.tres"),
		&"PhotonRailgun": preload("res://resources/attacks/pulsar_photon_railgun.tres"),
		&"Skill2": preload("res://resources/attacks/pulsar_disrupter_drone.tres"),
		&"DisrupterDrone": preload("res://resources/attacks/pulsar_disrupter_drone.tres"),
		&"Ultimate": preload("res://resources/attacks/pulsar_supernova.tres"),
		&"SupernovaHorizon": preload("res://resources/attacks/pulsar_supernova.tres")
	}

	super._ready()

	# Warna visual khas Pulsar: Neon Violet / Deep Purple
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.65, 0.25, 0.95, 1.0)

	if OS.is_debug_build():
		print("[CHARACTER][RayPulsar] Ray-X Pulsar diinisialisasi. HP: %d, Jalan: %.1f px/s, Dash: %.1f px/s." % [
			max_hp, walk_speed, get_dash_speed()
		])

func get_archetype() -> StringName:
	return &"pulsar"

func get_dash_speed() -> float:
	return CombatConstants.PULSAR_DASH_SPEED

func get_dash_duration() -> int:
	return CombatConstants.PULSAR_DASH_DURATION_FRAMES

func execute_skill_1() -> void:
	var atk = attack_resources.get(&"Skill1")
	if atk:
		request_attack(atk)
		photon_railgun_fired.emit(global_position, facing_direction)

func execute_skill_2() -> void:
	var atk = attack_resources.get(&"Skill2")
	if atk:
		request_attack(atk)
		deploy_disrupter_drone()

func execute_ultimate() -> void:
	var atk = attack_resources.get(&"Ultimate")
	if atk:
		# Supernova Horizon memberikan invulnerability frame pada fase startup
		invulnerability_frames = 18
		request_attack(atk)
		supernova_executed.emit()

func deploy_disrupter_drone() -> void:
	drone_frames_left = CombatConstants.PULSAR_DRONE_DURATION_FRAMES
	drone_position = global_position + Vector2(facing_direction * 120.0, -40.0)
	drone_deployed.emit(drone_position)

func is_drone_active() -> bool:
	return drone_frames_left > 0

func _physics_process(delta: float) -> void:
	if drone_frames_left > 0:
		drone_frames_left -= 1

	super._physics_process(delta)
