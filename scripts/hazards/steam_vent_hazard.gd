class_name SteamVentHazard
extends Area2D

## Geothermal Steam Vent Hazard (Story 12.1)
## Ventilasi uap geotermal panggung Underground Reactor.
## Beroperasi dengan siklus otomatis: Dormant -> Warning (3s) -> Eruption (1.5s)
## Memberikan +20% Heat dan 15 chip damage pada mecha yang melintas saat erupsi aktif.

signal warning_started()
signal eruption_started()
signal eruption_ended()
signal fighter_scorched(fighter: Node2D)

enum VentState {
	DORMANT,
	WARNING,
	ERUPTION
}

@export var dormant_duration: float = 6.0
@export var warning_duration: float = 3.0
@export var eruption_duration: float = 1.5

@export var damage_amount: int = 15
@export var heat_penalty: float = 20.0

var current_state: VentState = VentState.DORMANT
var state_timer: float = 0.0

var warning_indicator: ColorRect = null
var vent_particles: CPUParticles2D = null
var scorched_fighters: Array[Node2D] = []

func _ready() -> void:
	_setup_collision()
	_setup_visuals()
	_setup_particles()
	
	body_entered.connect(_on_body_entered)
	state_timer = dormant_duration

func _setup_collision() -> void:
	# Layer 1 (World) / Hazard monitor Area2D
	collision_layer = 0
	collision_mask = 1 # Mecha CharacterBody2D ada di Layer 1
	monitoring = true

func _setup_visuals() -> void:
	# Warning Indicator Beacon (Lampu bahaya)
	if not has_node("WarningBeacon"):
		warning_indicator = ColorRect.new()
		warning_indicator.name = "WarningBeacon"
		warning_indicator.custom_minimum_size = Vector2(32, 6)
		warning_indicator.position = Vector2(-16, -3)
		warning_indicator.color = Color(0.2, 0.2, 0.2, 1.0) # Mati saat dormant
		add_child(warning_indicator)
	else:
		warning_indicator = get_node("WarningBeacon") as ColorRect

func _setup_particles() -> void:
	if not has_node("SteamJet"):
		vent_particles = CPUParticles2D.new()
		vent_particles.name = "SteamJet"
		vent_particles.emitting = false
		vent_particles.amount = 36
		vent_particles.lifetime = 0.6
		vent_particles.direction = Vector2(0, -1)
		vent_particles.spread = 15.0
		vent_particles.gravity = Vector2(0, -250)
		vent_particles.initial_velocity_min = 180.0
		vent_particles.initial_velocity_max = 260.0
		vent_particles.scale_amount_min = 3.0
		vent_particles.scale_amount_max = 7.0
		vent_particles.color = Color(1.0, 0.5, 0.1, 0.85) # Uap panas membara oranye-kuning
		add_child(vent_particles)
	else:
		vent_particles = get_node("SteamJet") as CPUParticles2D

func _physics_process(delta: float) -> void:
	state_timer -= delta
	
	if current_state == VentState.WARNING:
		_process_warning_flash(delta)
	
	if state_timer <= 0.0:
		_advance_state()

func _process_warning_flash(_delta: float) -> void:
	if warning_indicator:
		# Berkedip cepat (frekuensi 6 Hz) warna Amber / Oranye-Merah
		var flash = int(Time.get_ticks_msec() / 150) % 2 == 0
		warning_indicator.color = Color(1.0, 0.25, 0.0, 1.0) if flash else Color(0.3, 0.1, 0.0, 1.0)

func _advance_state() -> void:
	match current_state:
		VentState.DORMANT:
			current_state = VentState.WARNING
			state_timer = warning_duration
			scorched_fighters.clear()
			warning_started.emit()
		VentState.WARNING:
			current_state = VentState.ERUPTION
			state_timer = eruption_duration
			if vent_particles:
				vent_particles.emitting = true
			if warning_indicator:
				warning_indicator.color = Color(1.0, 0.1, 0.0, 1.0)
			eruption_started.emit()
			_check_overlapping_bodies()
		VentState.ERUPTION:
			current_state = VentState.DORMANT
			state_timer = dormant_duration
			if vent_particles:
				vent_particles.emitting = false
			if warning_indicator:
				warning_indicator.color = Color(0.2, 0.2, 0.2, 1.0)
			scorched_fighters.clear()
			eruption_ended.emit()

func _check_overlapping_bodies() -> void:
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b is CharacterBody2D:
			_scorch_fighter(b)

func _on_body_entered(body: Node2D) -> void:
	if current_state == VentState.ERUPTION and body is CharacterBody2D:
		_scorch_fighter(body)

func _scorch_fighter(fighter: Node2D) -> void:
	if fighter in scorched_fighters:
		return
	scorched_fighters.append(fighter)
	
	# Tambahkan panas mecha via heat_component
	if "heat_component" in fighter and fighter.heat_component:
		fighter.heat_component.add_heat(heat_penalty)
	
	# Berikan chip damage
	if fighter.has_method("set_hp"):
		var cur = fighter.get("current_hp")
		if cur != null:
			fighter.set_hp(cur - damage_amount)
	
	# Visual hit flash
	if fighter.has_method("trigger_hit_flash"):
		fighter.trigger_hit_flash(6)
	
	fighter_scorched.emit(fighter)
	if OS.is_debug_build():
		print("[HAZARD][STEAM_VENT] Mecha %s tersengat semburan uap geotermal! (+%.1f%% Heat, -%d HP)" % [
			fighter.name, heat_penalty, damage_amount
		])
