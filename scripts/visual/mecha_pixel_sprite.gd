class_name MechaPixelSprite
extends Node2D

## Komponen Renderer Pixel Art Mecha 32-Bit & Animasi Pose (Story 7.1)
## Menggantikan ColorRect statis dengan siluet mecha bervolume, visor bercahaya,
## thruster jet dinamis, dan respons visual terhadap status StateMachine.

@export var archetype: StringName = &"viper" # &"viper" atau &"bulwark"

# Warna Palet 32-Bit Neo-Retro
var col_chassis: Color = Color(0.10, 0.13, 0.20)
var col_armor: Color = Color(0.20, 0.88, 1.00)
var col_highlight: Color = Color(0.60, 0.95, 1.00)
var col_visor: Color = Color(0.90, 1.00, 1.00)
var col_thruster: Color = Color(0.25, 0.70, 1.00)
var col_energy: Color = Color(0.30, 0.90, 1.00)

# State & Animasi
var current_state: StringName = &"Idle"
var anim_tick: int = 0
var hit_flash_frames: int = 0
var is_overclocked: bool = false
var is_meltdown: bool = false
var weapon_extended: bool = false
var attack_type: StringName = &""

var parent_mecha: CharacterBody2D = null

func _ready() -> void:
	_detect_parent_mecha()
	_apply_archetype_palette()
	set_physics_process(true)

func _detect_parent_mecha() -> void:
	var p = get_parent()
	while p:
		if p is CharacterBody2D and p.has_method("take_hit"):
			parent_mecha = p as CharacterBody2D
			break
		p = p.get_parent()

	if parent_mecha:
		if parent_mecha.has_method("get_archetype"):
			archetype = parent_mecha.get_archetype()
		elif "Bulwark" in parent_mecha.name or "Titan" in parent_mecha.name:
			archetype = &"bulwark"
		else:
			archetype = &"viper"
		
		# Sambungkan listener perubahan heat
		if parent_mecha.has_signal("heat_changed"):
			if not parent_mecha.heat_changed.is_connected(_on_heat_changed):
				parent_mecha.heat_changed.connect(_on_heat_changed)

func _apply_archetype_palette() -> void:
	if archetype == &"bulwark":
		col_chassis = Color(0.14, 0.15, 0.18)
		col_armor = Color(1.00, 0.55, 0.10)
		col_highlight = Color(1.00, 0.75, 0.25)
		col_visor = Color(1.00, 0.25, 0.20) # Sensor mata merah ruby
		col_thruster = Color(1.00, 0.40, 0.05)
		col_energy = Color(1.00, 0.60, 0.15)
	else:
		col_chassis = Color(0.10, 0.13, 0.20)
		col_armor = Color(0.20, 0.88, 1.00)
		col_highlight = Color(0.60, 0.95, 1.00)
		col_visor = Color(0.90, 1.00, 1.00) # Visor slit cyan
		col_thruster = Color(0.25, 0.70, 1.00)
		col_energy = Color(0.30, 0.90, 1.00)

func _on_heat_changed(current: float, _max_val: float) -> void:
	is_overclocked = (current >= 80.0 and current < 100.0)
	is_meltdown = (current >= 100.0)

func trigger_hit_flash(frames: int = 4) -> void:
	hit_flash_frames = frames
	queue_redraw()

func set_current_state(state_name: StringName) -> void:
	current_state = state_name
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not parent_mecha:
		_detect_parent_mecha()

	# Jika mecha dalam status hitstop, bekukan kemajuan animasi
	if parent_mecha and parent_mecha.get("hitstop_frames") and parent_mecha.hitstop_frames > 0:
		pass
	else:
		anim_tick = (anim_tick + 1) % 120

	# Sinkronisasi status mecha
	if parent_mecha:
		var sm = parent_mecha.get_node_or_null("StateMachine")
		if sm and sm.get("current_state"):
			var st_name: StringName = StringName(sm.current_state.name)
			if st_name != current_state:
				current_state = st_name

		if parent_mecha.has_method("is_overclocked"):
			is_overclocked = parent_mecha.is_overclocked()

	if hit_flash_frames > 0:
		hit_flash_frames -= 1

	queue_redraw()

func _draw() -> void:
	# Efek Hit Flash (Putih / Merah menyala)
	if hit_flash_frames > 0:
		draw_rect(Rect2(-12, -19, 24, 38), Color(1.0, 1.0, 1.0, 0.85))
		return

	if archetype == &"bulwark":
		_draw_bulwark_mecha()
	else:
		_draw_viper_mecha()

	# Efek Aura Overclock (Glow neon tipis di sekeliling bodi)
	if is_overclocked and (anim_tick % 6 < 3):
		draw_rect(Rect2(-13, -20, 26, 40), Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.3), false, 1.0)

## =========================================================================
## RENDERER 32-BIT: APEX-0 VIPER (Aerodynamic High-Speed Rushdown Mecha)
## =========================================================================
func _draw_viper_mecha() -> void:
	var bob_y: float = 0.0
	if current_state == &"Idle":
		bob_y = 1.0 if (anim_tick % 30 < 15) else 0.0
	elif current_state == &"Walk":
		bob_y = 1.5 if (anim_tick % 16 < 8) else -0.5
	elif current_state == &"Cliffhanger":
		# Pose menggantung: seluruh bodi turun 6px, satu tangan terangkat ke atas
		bob_y = 6.0

	# 1. Jet Thruster Flames (Belakang / Bawah saat Dash, Jump, Fall)
	if current_state in [&"Dash", &"AirDash"]:
		var flame_w = 7.0 + (anim_tick % 3)
		draw_rect(Rect2(-12 - flame_w, -6 + bob_y, flame_w, 4), col_thruster)
		draw_rect(Rect2(-12 - (flame_w * 0.6), -5 + bob_y, flame_w * 0.6, 2), Color.WHITE)
	elif current_state in [&"Jump", &"Fall"]:
		var flame_h = 6.0 + (anim_tick % 4)
		draw_rect(Rect2(-7, 19 + bob_y, 4, flame_h), col_thruster)
		draw_rect(Rect2(3, 19 + bob_y, 4, flame_h), col_thruster)

	# 2. Main Chassis & Pelvis (Ramping, sudut miring)
	draw_rect(Rect2(-9, -10 + bob_y, 18, 16), col_chassis)
	draw_rect(Rect2(-7, -8 + bob_y, 14, 12), col_armor)

	# Reactor Core di tengah dada (berdenyut saat Overclock)
	var core_color = Color(1.0, 0.3, 0.2) if is_overclocked else col_energy
	draw_rect(Rect2(-3, -4 + bob_y, 6, 6), core_color)
	draw_rect(Rect2(-1, -2 + bob_y, 2, 2), Color.WHITE)

	# 3. Kaki Cybernetic (Left & Right legs)
	if current_state == &"Walk":
		var stride = 3.0 if (anim_tick % 16 < 8) else -3.0
		# Kaki kiri
		draw_rect(Rect2(-8 + stride, 6 + bob_y, 5, 13), col_chassis)
		draw_rect(Rect2(-7 + stride, 8 + bob_y, 3, 10), col_armor)
		# Kaki kanan
		draw_rect(Rect2(3 - stride, 6 + bob_y, 5, 13), col_chassis)
		draw_rect(Rect2(4 - stride, 8 + bob_y, 3, 10), col_armor)
	elif current_state == &"Cliffhanger":
		# Kaki menjuntai lurus ke bawah
		draw_rect(Rect2(-7, 6 + bob_y, 5, 14), col_chassis)
		draw_rect(Rect2(2, 6 + bob_y, 5, 14), col_chassis)
	else:
		# Standar kaki
		draw_rect(Rect2(-8, 6 + bob_y, 5, 13), col_chassis)
		draw_rect(Rect2(-7, 8 + bob_y, 3, 10), col_armor)
		draw_rect(Rect2(3, 6 + bob_y, 5, 13), col_chassis)
		draw_rect(Rect2(4, 8 + bob_y, 3, 10), col_armor)

	# 4. Kepala & Visor Aerodinamis (Y: -18 s/d -10)
	var head_y = -18.0 + bob_y
	if current_state == &"Meltdown":
		head_y += 3.0 # Kepala tertunduk saat shutdown
	draw_rect(Rect2(-6, head_y, 12, 8), col_chassis)
	draw_rect(Rect2(-5, head_y + 1, 10, 6), col_armor)
	# Visor horizontal slit tajam
	if not is_meltdown:
		draw_rect(Rect2(-4, head_y + 3, 9, 2), col_visor)
		draw_rect(Rect2(-1, head_y + 3, 3, 2), Color.WHITE)
	else:
		# Visor mati/redup
		draw_rect(Rect2(-4, head_y + 3, 9, 2), Color(0.2, 0.3, 0.4))

	# 5. Lengan & Senjata Rapier Beam (Right Arm)
	if current_state == &"Attack":
		# Lengan terentang ke depan dengan Rapier Beam
		draw_rect(Rect2(6, -6 + bob_y, 8, 4), col_chassis)
		draw_rect(Rect2(14, -7 + bob_y, 14, 3), col_energy) # Rapier beam blade
		draw_rect(Rect2(14, -6 + bob_y, 12, 1), Color.WHITE)
	elif current_state == &"Cliffhanger":
		# Tangan kanan meraih bibir tebing di atas platform (Y = -19)
		draw_rect(Rect2(5, -19, 4, 15), col_armor)
		draw_rect(Rect2(3, -20, 6, 3), col_highlight) # Cengkeraman jari mecha
	elif current_state == &"Blockstun" or current_state == &"Parry":
		# Postur guard menyilang di depan dada
		draw_rect(Rect2(2, -8 + bob_y, 6, 10), col_armor)
		draw_rect(Rect2(6, -10 + bob_y, 3, 14), col_highlight)
	else:
		# Lengan santai di samping
		draw_rect(Rect2(-11, -7 + bob_y, 3, 10), col_chassis)
		draw_rect(Rect2(8, -7 + bob_y, 3, 10), col_chassis)
		draw_rect(Rect2(8, -5 + bob_y, 3, 8), col_armor)

## =========================================================================
## RENDERER 32-BIT: TITAN-V BULWARK (Heavy Industrial Armored Grappler)
## =========================================================================
func _draw_bulwark_mecha() -> void:
	var bob_y: float = 0.0
	if current_state == &"Idle":
		bob_y = 1.0 if (anim_tick % 40 < 20) else 0.0
	elif current_state == &"Walk":
		bob_y = 1.0 if (anim_tick % 24 < 12) else -1.0
	elif current_state == &"Cliffhanger":
		bob_y = 6.0

	# 1. Pendorong Heavy Thruster (Bawah saat Jump/Fall, Belakang saat Dash)
	if current_state in [&"Dash", &"AirDash"]:
		var flame_w = 6.0 + (anim_tick % 3)
		draw_rect(Rect2(-14 - flame_w, -4 + bob_y, flame_w, 6), col_thruster)
		draw_rect(Rect2(-14 - (flame_w * 0.5), -3 + bob_y, flame_w * 0.5, 4), Color(1.0, 0.9, 0.3))
	elif current_state in [&"Jump", &"Fall"]:
		var flame_h = 5.0 + (anim_tick % 3)
		draw_rect(Rect2(-9, 19 + bob_y, 6, flame_h), col_thruster)
		draw_rect(Rect2(3, 19 + bob_y, 6, flame_h), col_thruster)

	# 2. Heavy Chassis & Pelat Baja Dada (Bahu lebar, kokoh)
	draw_rect(Rect2(-11, -11 + bob_y, 22, 18), col_chassis)
	draw_rect(Rect2(-9, -9 + bob_y, 18, 14), col_armor)

	# Hazard stripes / pelat penguat industrial
	draw_rect(Rect2(-7, -7 + bob_y, 14, 3), col_highlight)
	draw_rect(Rect2(-7, -2 + bob_y, 14, 4), Color(0.18, 0.20, 0.24)) # Grille vent

	# 3. Kaki Baja Piston Berat (Lebar 6px tiap kaki)
	if current_state == &"Walk":
		var stride = 2.5 if (anim_tick % 24 < 12) else -2.5
		# Kaki kiri
		draw_rect(Rect2(-10 + stride, 7 + bob_y, 7, 12), col_chassis)
		draw_rect(Rect2(-9 + stride, 8 + bob_y, 5, 10), col_armor)
		# Kaki kanan
		draw_rect(Rect2(3 - stride, 7 + bob_y, 7, 12), col_chassis)
		draw_rect(Rect2(4 - stride, 8 + bob_y, 5, 10), col_armor)
	elif current_state == &"Cliffhanger":
		draw_rect(Rect2(-9, 7 + bob_y, 7, 13), col_chassis)
		draw_rect(Rect2(2, 7 + bob_y, 7, 13), col_chassis)
	else:
		draw_rect(Rect2(-10, 7 + bob_y, 7, 12), col_chassis)
		draw_rect(Rect2(-9, 8 + bob_y, 5, 10), col_armor)
		draw_rect(Rect2(3, 7 + bob_y, 7, 12), col_chassis)
		draw_rect(Rect2(4, 8 + bob_y, 5, 10), col_armor)

	# 4. Helm Baja Berat & Sensor Optik (Y: -18 s/d -11)
	var head_y = -18.0 + bob_y
	if current_state == &"Meltdown":
		head_y += 3.0
	draw_rect(Rect2(-7, head_y, 14, 7), col_chassis)
	draw_rect(Rect2(-6, head_y + 1, 12, 5), col_armor)
	# Dual optic red sensor
	if not is_meltdown:
		draw_rect(Rect2(-4, head_y + 2, 3, 2), col_visor)
		draw_rect(Rect2(1, head_y + 2, 3, 2), col_visor)
	else:
		draw_rect(Rect2(-4, head_y + 2, 3, 2), Color(0.3, 0.1, 0.1))
		draw_rect(Rect2(1, head_y + 2, 3, 2), Color(0.3, 0.1, 0.1))

	# 5. Shoulder Guards & Piston Arm / Riot Shield
	# Massive Shoulder Guards
	draw_rect(Rect2(-13, -12 + bob_y, 4, 7), col_highlight)
	draw_rect(Rect2(9, -12 + bob_y, 4, 7), col_highlight)

	if current_state == &"Attack":
		# Hydraulic punch extension ke depan
		draw_rect(Rect2(8, -6 + bob_y, 12, 7), col_chassis)
		draw_rect(Rect2(18, -8 + bob_y, 8, 10), col_armor) # Heavy knuckle fist
		draw_rect(Rect2(12, -4 + bob_y, 6, 3), col_highlight) # Piston cylinder
	elif current_state == &"Cliffhanger":
		# Tangan cengkeram tebing kokoh
		draw_rect(Rect2(6, -19, 6, 15), col_armor)
		draw_rect(Rect2(4, -20, 8, 4), col_highlight)
	elif current_state == &"Blockstun" or current_state == &"Parry":
		# Riot Shield Deploy menutupi bagian depan
		draw_rect(Rect2(4, -14 + bob_y, 6, 26), col_highlight)
		draw_rect(Rect2(6, -12 + bob_y, 3, 22), col_armor)
	else:
		# Lengan hydraulic bertumpu di samping
		draw_rect(Rect2(-12, -5 + bob_y, 3, 10), col_chassis)
		draw_rect(Rect2(9, -5 + bob_y, 4, 11), col_chassis)
		draw_rect(Rect2(9, -3 + bob_y, 3, 8), col_armor)
