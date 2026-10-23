class_name MechaPixelSprite
extends Node2D

## Komponen Renderer Karakter Petarung Martial Arts (Fighter Visuals)
## Menggantikan siluet kotak primitif dengan anatomi petarung bela diri dinamis:
## - Proporsi tubuh petarung (kepala, rambut/bandana, torso berotot/gi, sabuk, kepalan tangan, celana & boot)
## - Animasi pose bela diri autentik (idle bounce, stepping walk, martial arts guard, snap punch, X-block, ledge struggle)
## - 3 Persona Petarung: Apex-0 Viper (Cyber-Ninja), Titan-V Bulwark (Heavy Brawler), Ray-X Pulsar (Shaolin Master)

@export var archetype: StringName = &"viper" # &"viper", &"bulwark", atau &"pulsar"

# Warna Palet Karakter & Kostum Bela Diri
var col_chassis: Color = Color(0.10, 0.13, 0.20)
var col_armor: Color = Color(0.20, 0.88, 1.00)
var col_highlight: Color = Color(0.60, 0.95, 1.00)
var col_visor: Color = Color(0.90, 1.00, 1.00)
var col_thruster: Color = Color(0.25, 0.70, 1.00)
var col_energy: Color = Color(0.30, 0.90, 1.00)

# Warna Kulit & Rambut Petarung
var col_skin: Color = Color(0.96, 0.82, 0.70)
var col_skin_shadow: Color = Color(0.80, 0.62, 0.48)
var col_hair: Color = Color(0.12, 0.14, 0.22)
var col_belt: Color = Color(0.08, 0.08, 0.10)

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
		elif "Pulsar" in parent_mecha.name or "Ray" in parent_mecha.name:
			archetype = &"pulsar"
		elif "Kage" in parent_mecha.name or "Phantom" in parent_mecha.name:
			archetype = &"kage"
		else:
			archetype = &"viper"
		
		if parent_mecha.has_signal("heat_changed"):
			if not parent_mecha.heat_changed.is_connected(_on_heat_changed):
				parent_mecha.heat_changed.connect(_on_heat_changed)

func _apply_archetype_palette() -> void:
	if archetype == &"bulwark":
		col_chassis = Color(0.14, 0.15, 0.18)
		col_armor = Color(1.00, 0.55, 0.10)
		col_highlight = Color(1.00, 0.75, 0.25)
		col_visor = Color(1.00, 0.25, 0.20)
		col_thruster = Color(1.00, 0.40, 0.05)
		col_energy = Color(1.00, 0.60, 0.15)
		col_skin = Color(0.86, 0.62, 0.44)
		col_skin_shadow = Color(0.68, 0.45, 0.30)
		col_hair = Color(0.18, 0.15, 0.14)
		col_belt = Color(0.95, 0.65, 0.10) # Golden champion belt
	elif archetype == &"pulsar":
		col_chassis = Color(0.12, 0.08, 0.20)
		col_armor = Color(0.65, 0.25, 0.95)
		col_highlight = Color(0.85, 0.50, 1.00)
		col_visor = Color(1.00, 0.90, 0.15)
		col_thruster = Color(0.80, 0.30, 1.00)
		col_energy = Color(1.00, 0.85, 0.20)
		col_skin = Color(0.92, 0.78, 0.64)
		col_skin_shadow = Color(0.76, 0.58, 0.45)
		col_hair = Color(0.08, 0.06, 0.14)
		col_belt = Color(1.00, 0.85, 0.20) # Golden sash
	elif archetype == &"kage":
		col_chassis = Color(0.08, 0.08, 0.12) # Midnight Charcoal
		col_armor = Color(0.95, 0.15, 0.25) # Crimson Red
		col_highlight = Color(1.00, 0.40, 0.45) # Neon Rose
		col_visor = Color(1.00, 0.20, 0.30) # Glowing Crimson
		col_thruster = Color(0.85, 0.10, 0.20)
		col_energy = Color(1.00, 0.20, 0.35)
		col_skin = Color(0.94, 0.88, 0.82)
		col_skin_shadow = Color(0.74, 0.65, 0.58)
		col_hair = Color(0.06, 0.06, 0.08) # Jet midnight black
		col_belt = Color(0.90, 0.12, 0.22) # Crimson flowing ninja scarf
	else:
		col_chassis = Color(0.10, 0.13, 0.20)
		col_armor = Color(0.20, 0.88, 1.00)
		col_highlight = Color(0.60, 0.95, 1.00)
		col_visor = Color(0.90, 1.00, 1.00)
		col_thruster = Color(0.25, 0.70, 1.00)
		col_energy = Color(0.30, 0.90, 1.00)
		col_skin = Color(0.96, 0.82, 0.70)
		col_skin_shadow = Color(0.80, 0.62, 0.48)
		col_hair = Color(0.10, 0.12, 0.18)
		col_belt = Color(0.08, 0.08, 0.10) # Black belt

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

	if parent_mecha and parent_mecha.get("hitstop_frames") and parent_mecha.hitstop_frames > 0:
		pass
	else:
		anim_tick = (anim_tick + 1) % 120

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
	if hit_flash_frames > 0:
		draw_rect(Rect2(-12, -19, 24, 38), Color(1.0, 1.0, 1.0, 0.85))
		return

	if archetype == &"bulwark":
		_draw_bulwark_fighter()
	elif archetype == &"pulsar":
		_draw_pulsar_fighter()
	elif archetype == &"kage":
		_draw_kage_fighter()
	else:
		_draw_viper_fighter()

	# Efek Aura Overclock (Aura api petarung)
	if is_overclocked and (anim_tick % 6 < 4):
		var aura_col = Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.35)
		draw_polyline(PackedVector2Array([
			Vector2(-12, 18), Vector2(-13, 0), Vector2(-10, -14),
			Vector2(0, -21), Vector2(10, -14), Vector2(13, 0), Vector2(12, 18)
		]), aura_col, 1.5)

## Kompatibilitas mundur dengan nama lama
func _draw_viper_mecha() -> void:
	_draw_viper_fighter()

func _draw_bulwark_mecha() -> void:
	_draw_bulwark_fighter()

## =========================================================================
## 1. APEX-0 VIPER: CYBER-NINJA MARTIAL ARTIST (Shinobi Fighter)
## =========================================================================
func _draw_viper_fighter() -> void:
	var bob_y: float = 0.0
	if current_state == &"Idle":
		# Rhythmic martial arts idle bounce (pernapasan & kesiapan)
		bob_y = sin(anim_tick * 0.15) * 1.5
	elif current_state == &"Walk":
		bob_y = abs(sin(anim_tick * 0.35)) * 1.8
	elif current_state == &"Cliffhanger":
		bob_y = 6.0

	var head_center := Vector2(0, -14.0 + bob_y)
	if current_state == &"Meltdown":
		head_center.y += 3.0

	# 1. Flowing Ninja Headband Ribbon (Berkibar dinamis di belakang kepala)
	var trail_offset = -6.0 if current_state == &"Walk" else -4.0
	var wave_1 = sin((anim_tick + 10) * 0.2) * 3.0
	var wave_2 = cos((anim_tick + 20) * 0.25) * 4.0
	var ribbon_pts = PackedVector2Array([
		Vector2(-4, head_center.y + 1),
		Vector2(trail_offset - 4, head_center.y + 3 + wave_1),
		Vector2(trail_offset - 10, head_center.y + 6 + wave_2),
		Vector2(trail_offset - 14, head_center.y + 8 + wave_1)
	])
	draw_polyline(ribbon_pts, col_armor, 2.0)
	draw_polyline(ribbon_pts, Color.WHITE, 1.0)

	# 2. Kaki Petarung (Shinobi Combat Pants & Boots)
	if current_state == &"Walk":
		var stride = sin(anim_tick * 0.35) * 5.0
		# Kaki belakang
		_draw_fighter_leg(Vector2(-5 - stride, 5 + bob_y), Vector2(-6 - stride, 19 + bob_y), col_chassis, col_armor, 4.5)
		# Kaki depan
		_draw_fighter_leg(Vector2(4 + stride, 5 + bob_y), Vector2(5 + stride, 19 + bob_y), col_chassis, col_armor, 4.5)
	elif current_state == &"Cliffhanger":
		_draw_fighter_leg(Vector2(-4, 5 + bob_y), Vector2(-4, 18 + bob_y), col_chassis, col_armor, 4.0)
		_draw_fighter_leg(Vector2(3, 5 + bob_y), Vector2(4, 19 + bob_y), col_chassis, col_armor, 4.0)
	elif current_state in [&"Jump", &"Fall"]:
		# Pose lompatan ninja: satu kaki ditekuk ke atas, satu kaki menjulur
		_draw_fighter_leg(Vector2(-5, 4 + bob_y), Vector2(-8, 14 + bob_y), col_chassis, col_armor, 4.5)
		_draw_fighter_leg(Vector2(4, 4 + bob_y), Vector2(7, 19 + bob_y), col_chassis, col_armor, 4.5)
	else:
		# Standar stance bela diri: kaki kiri sedikit ke belakang, kaki kanan di depan
		_draw_fighter_leg(Vector2(-5, 5 + bob_y), Vector2(-7, 19 + bob_y), col_chassis, col_armor, 4.5)
		_draw_fighter_leg(Vector2(4, 5 + bob_y), Vector2(6, 19 + bob_y), col_chassis, col_armor, 4.5)

	# 3. Torso & Gi Bela Diri (Martial Arts Vest / Gi)
	var chest_pts = PackedVector2Array([
		Vector2(-7, -8 + bob_y),
		Vector2(7, -8 + bob_y),
		Vector2(5, 5 + bob_y),
		Vector2(-5, 5 + bob_y)
	])
	draw_colored_polygon(chest_pts, col_chassis)
	
	# Dada dalam / Gi wrap & highlight cyan
	var inner_gi = PackedVector2Array([
		Vector2(-4, -7 + bob_y),
		Vector2(4, -7 + bob_y),
		Vector2(2, 3 + bob_y),
		Vector2(-2, 3 + bob_y)
	])
	draw_colored_polygon(inner_gi, col_armor)

	# Dada kulit berotot di sela kerah Gi
	var skin_chest = PackedVector2Array([
		Vector2(-2, -7 + bob_y),
		Vector2(2, -7 + bob_y),
		Vector2(0, -2 + bob_y)
	])
	draw_colored_polygon(skin_chest, col_skin)

	# Sabuk Bela Diri Hitam (Black Belt) & Simpul Pita
	draw_rect(Rect2(-6, 3 + bob_y, 12, 3), col_belt)
	draw_rect(Rect2(0, 5 + bob_y, 3, 5), col_belt) # Pita sabuk menjuntai

	# 4. Kepala & Wajah Ninja
	# Rambut spiky ninja
	var hair_pts = PackedVector2Array([
		Vector2(-5, head_center.y - 1),
		Vector2(-6, head_center.y - 5),
		Vector2(-2, head_center.y - 7),
		Vector2(3, head_center.y - 7),
		Vector2(6, head_center.y - 4),
		Vector2(5, head_center.y)
	])
	draw_colored_polygon(hair_pts, col_hair)

	# Wajah kulit petarung
	draw_circle(Vector2(head_center.x + 0.5, head_center.y), 4.2, col_skin)

	# Ninja Mask / Bandana bawah
	var mask_pts = PackedVector2Array([
		Vector2(-3.5, head_center.y),
		Vector2(4.0, head_center.y),
		Vector2(2.5, head_center.y + 4.5),
		Vector2(-2.5, head_center.y + 4.5)
	])
	draw_colored_polygon(mask_pts, col_chassis)

	# Headband di dahi
	draw_rect(Rect2(-4.5, head_center.y - 3, 9, 2), col_armor)
	# Mata tajam anime petarung (Cyan glow)
	if not is_meltdown:
		draw_line(Vector2(0.5, head_center.y - 1), Vector2(3.5, head_center.y - 1), col_visor, 1.2)
	else:
		draw_line(Vector2(0.5, head_center.y - 1), Vector2(3.5, head_center.y - 1), Color(0.3, 0.4, 0.5), 1.0)

	# 5. Lengan & Kepalan Tangan Bela Diri (Martial Guard / Punch)
	if current_state == &"Attack":
		# Lengan kiri menjaga dada
		draw_circle(Vector2(-3, -2 + bob_y), 2.5, col_skin)
		# Tangan kanan melancarkan pukulan kilat maju ke depan dengan Beam Rapier!
		var punch_x = 18.0
		_draw_fighter_arm(Vector2(4, -5 + bob_y), Vector2(punch_x, -5 + bob_y), col_skin, col_armor)
		# Rapier Beam Blade dari kepalan tangan
		draw_line(Vector2(punch_x, -5 + bob_y), Vector2(punch_x + 16, -5 + bob_y), col_energy, 2.5)
		draw_line(Vector2(punch_x, -5 + bob_y), Vector2(punch_x + 14, -5 + bob_y), Color.WHITE, 1.2)
	elif current_state in [&"Blockstun", &"Parry"]:
		# X-Guard: Dua lengan menyilang kuat di depan wajah
		_draw_fighter_arm(Vector2(-4, -4 + bob_y), Vector2(3, -9 + bob_y), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -4 + bob_y), Vector2(-3, -9 + bob_y), col_skin, col_armor)
	elif current_state == &"Cliffhanger":
		# Dua tangan mencengkeram bibir tebing
		_draw_fighter_arm(Vector2(-4, -4 + bob_y), Vector2(-2, -19), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -4 + bob_y), Vector2(6, -19), col_skin, col_armor)
		draw_rect(Rect2(-3, -20, 4, 3), col_skin)
		draw_rect(Rect2(5, -20, 4, 3), col_skin)
	else:
		# Stance Bela Diri Netral: Dua kepalan tangan terangkat siap tempur di dekat dada
		var f1_pos = Vector2(-4, -3 + bob_y + sin(anim_tick * 0.15) * 0.8)
		var f2_pos = Vector2(6, -5 + bob_y - cos(anim_tick * 0.15) * 0.8)
		_draw_fighter_arm(Vector2(-5, -6 + bob_y), f1_pos, col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), f2_pos, col_skin, col_armor)

## =========================================================================
## 2. TITAN-V BULWARK: HEAVYWEIGHT BRAWLER / BOXER (Grappler Fighter)
## =========================================================================
func _draw_bulwark_fighter() -> void:
	var bob_y: float = 0.0
	if current_state == &"Idle":
		bob_y = sin(anim_tick * 0.12) * 1.2
	elif current_state == &"Walk":
		bob_y = abs(sin(anim_tick * 0.28)) * 1.5
	elif current_state == &"Cliffhanger":
		bob_y = 6.0

	var head_center := Vector2(0, -14.0 + bob_y)
	if current_state == &"Meltdown":
		head_center.y += 3.0

	# 1. Kaki Berotot Kekar & Pelindung Lutut Brawler
	if current_state == &"Walk":
		var stride = sin(anim_tick * 0.28) * 4.0
		_draw_fighter_leg(Vector2(-6 - stride, 5 + bob_y), Vector2(-7 - stride, 19 + bob_y), col_chassis, col_armor, 6.0)
		_draw_fighter_leg(Vector2(5 + stride, 5 + bob_y), Vector2(6 + stride, 19 + bob_y), col_chassis, col_armor, 6.0)
	elif current_state == &"Cliffhanger":
		_draw_fighter_leg(Vector2(-5, 5 + bob_y), Vector2(-6, 18 + bob_y), col_chassis, col_armor, 5.5)
		_draw_fighter_leg(Vector2(4, 5 + bob_y), Vector2(5, 19 + bob_y), col_chassis, col_armor, 5.5)
	else:
		# Stance Brawler Kokoh & Lebar
		_draw_fighter_leg(Vector2(-6, 5 + bob_y), Vector2(-8, 19 + bob_y), col_chassis, col_armor, 6.0)
		_draw_fighter_leg(Vector2(5, 5 + bob_y), Vector2(8, 19 + bob_y), col_chassis, col_armor, 6.0)

	# 2. Torso Kekar & Dada Berotot (Heavy Muscular Build)
	var torso_pts = PackedVector2Array([
		Vector2(-9, -8 + bob_y),
		Vector2(9, -8 + bob_y),
		Vector2(7, 5 + bob_y),
		Vector2(-7, 5 + bob_y)
	])
	draw_colored_polygon(torso_pts, col_skin) # Kulit dada kekar

	# Rompi / Pelat Bahu Petarung (Open Combat Vest)
	draw_rect(Rect2(-9, -8 + bob_y, 4, 11), col_chassis)
	draw_rect(Rect2(5, -8 + bob_y, 4, 11), col_chassis)
	# Aksen garis oranye
	draw_rect(Rect2(-8, -7 + bob_y, 2, 9), col_armor)
	draw_rect(Rect2(6, -7 + bob_y, 2, 9), col_armor)

	# Sabuk Juara Berat Emas (Heavyweight Championship Belt)
	draw_rect(Rect2(-7, 3 + bob_y, 14, 4), col_belt)
	draw_circle(Vector2(0, 5 + bob_y), 3.0, Color(1.0, 0.9, 0.4)) # Plat emas bulat

	# 3. Kepala Petarung Kekar & Bandana Merah
	# Kepala & Rahang Kuat
	draw_circle(Vector2(head_center.x, head_center.y), 5.0, col_skin)
	# Rambut spiky brawler
	var hair_pts = PackedVector2Array([
		Vector2(-5, head_center.y - 2),
		Vector2(-5, head_center.y - 7),
		Vector2(-1, head_center.y - 8),
		Vector2(4, head_center.y - 7),
		Vector2(5, head_center.y - 2)
	])
	draw_colored_polygon(hair_pts, col_hair)

	# Bandana Petarung Merah
	draw_rect(Rect2(-5, head_center.y - 3, 10, 2.5), col_visor)
	# Mata galak / sensor brawler
	draw_circle(Vector2(2.0, head_center.y - 0.5), 1.2, Color.WHITE)
	draw_circle(Vector2(2.0, head_center.y - 0.5), 0.7, Color.BLACK)

	# 4. Lengan Kekar & Sarung Tinju / Knuckle Wrap
	if current_state == &"Attack":
		# Heavy Haymaker Punch meluncur dahsyat ke depan
		var punch_pos = Vector2(20.0, -5 + bob_y)
		_draw_fighter_arm(Vector2(6, -6 + bob_y), punch_pos, col_skin, col_armor, 4.5)
		draw_circle(punch_pos, 4.5, col_armor) # Sarung tinju tebal
		draw_circle(punch_pos + Vector2(2, 0), 2.5, col_highlight)
	elif current_state in [&"Blockstun", &"Parry"]:
		# Full Guard: Dua lengan kekar menutupi seluruh kepala & dada
		_draw_fighter_arm(Vector2(-5, -5 + bob_y), Vector2(0, -11 + bob_y), col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(5, -5 + bob_y), Vector2(3, -11 + bob_y), col_skin, col_armor, 4.5)
		draw_rect(Rect2(4, -13 + bob_y, 4, 16), col_highlight)
	elif current_state == &"Cliffhanger":
		_draw_fighter_arm(Vector2(-5, -5 + bob_y), Vector2(-3, -19), col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(5, -5 + bob_y), Vector2(7, -19), col_skin, col_armor, 4.5)
		draw_circle(Vector2(-3, -19), 3.5, col_armor)
		draw_circle(Vector2(7, -19), 3.5, col_armor)
	else:
		# Stance Boxer / Muay Thai: Dua sarung tinju di depan wajah
		var b_fist1 = Vector2(-5, -5 + bob_y)
		var b_fist2 = Vector2(6, -7 + bob_y)
		_draw_fighter_arm(Vector2(-7, -6 + bob_y), b_fist1, col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(6, -6 + bob_y), b_fist2, col_skin, col_armor, 4.5)
		draw_circle(b_fist1, 3.5, col_armor)
		draw_circle(b_fist2, 3.8, col_armor)

## =========================================================================
## 3. RAY-X PULSAR: SHAOLIN / TAOIST PHOTON MASTER (Wushu Monk)
## =========================================================================
func _draw_pulsar_fighter() -> void:
	var bob_y: float = sin(anim_tick * 0.18) * 1.0
	if current_state == &"Walk":
		bob_y = abs(sin(anim_tick * 0.3)) * 1.5
	elif current_state == &"Cliffhanger":
		bob_y = 6.0

	var head_center := Vector2(0, -14.0 + bob_y)

	# 1. Kaki Petarung Sutra Sutra Shaolin (Flowing Monk Pants)
	if current_state == &"Walk":
		var stride = sin(anim_tick * 0.3) * 4.5
		_draw_fighter_leg(Vector2(-5 - stride, 5 + bob_y), Vector2(-6 - stride, 19 + bob_y), col_armor, col_highlight, 4.5)
		_draw_fighter_leg(Vector2(4 + stride, 5 + bob_y), Vector2(5 + stride, 19 + bob_y), col_armor, col_highlight, 4.5)
	else:
		_draw_fighter_leg(Vector2(-4, 5 + bob_y), Vector2(-6, 19 + bob_y), col_armor, col_highlight, 4.5)
		_draw_fighter_leg(Vector2(4, 5 + bob_y), Vector2(6, 19 + bob_y), col_armor, col_highlight, 4.5)

	# 2. Jubah Sutra Bela Diri Taoist (Flowing Robe / Tunic)
	var robe_pts = PackedVector2Array([
		Vector2(-7, -8 + bob_y),
		Vector2(7, -8 + bob_y),
		Vector2(6, 6 + bob_y),
		Vector2(-6, 6 + bob_y)
	])
	draw_colored_polygon(robe_pts, col_armor)

	# Selendang Emas Melintang (Golden Shaolin Sash)
	draw_line(Vector2(-6, -7 + bob_y), Vector2(5, 5 + bob_y), col_belt, 2.5)
	draw_rect(Rect2(-5, 3 + bob_y, 10, 3), col_belt)

	# Inti Energi Foton di Dada
	draw_circle(Vector2(0, -2 + bob_y), 2.5, col_energy)
	draw_circle(Vector2(0, -2 + bob_y), 1.2, Color.WHITE)

	# 3. Kepala Pendekar & Hiasan Kening Emas
	draw_circle(head_center, 4.2, col_skin)
	# Rambut topknot pendek rapi
	draw_circle(Vector2(head_center.x, head_center.y - 4.5), 2.5, col_hair)
	# Hiasan mahkota kening emas
	draw_line(Vector2(-3.5, head_center.y - 2), Vector2(3.5, head_center.y - 2), col_belt, 1.5)
	draw_circle(Vector2(0, head_center.y - 2), 1.2, col_energy)

	# 4. Lengan & Tapak Bela Diri (Shaolin Palm Stance)
	if current_state == &"Attack":
		# Serangan Tapak Sakti / Photon Palm Strike meluncur ke depan
		var palm_pos = Vector2(17.0, -4 + bob_y)
		_draw_fighter_arm(Vector2(4, -5 + bob_y), palm_pos, col_skin, col_highlight)
		# Gelombang foton melingkar di ujung tapak
		draw_circle(palm_pos, 4.0, Color(col_energy.r, col_energy.g, col_energy.b, 0.7))
		draw_circle(palm_pos, 2.0, Color.WHITE)
	elif current_state in [&"Blockstun", &"Parry"]:
		# Lingkaran pertahanan tapak Wing Chun
		_draw_fighter_arm(Vector2(-4, -4 + bob_y), Vector2(2, -8 + bob_y), col_skin, col_highlight)
		_draw_fighter_arm(Vector2(4, -4 + bob_y), Vector2(6, -3 + bob_y), col_skin, col_highlight)
		draw_arc(Vector2(6, -5 + bob_y), 8.0, -PI*0.5, PI*0.5, 8, col_energy, 1.5)
	else:
		# Stance Tapak Anggun: Tapak depan terbuka, tapak belakang di dekat dada
		var p1_pos = Vector2(-3, -3 + bob_y)
		var p2_pos = Vector2(8, -4 + bob_y)
		_draw_fighter_arm(Vector2(-5, -6 + bob_y), p1_pos, col_skin, col_highlight)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), p2_pos, col_skin, col_highlight)
		draw_circle(p1_pos, 2.0, col_skin)
		draw_circle(p2_pos, 2.2, col_skin)

		# 3 Butir Bola Energi Foton (Orbiting Photon Prayer Orbs) melayang anggun
		for i in range(3):
			var angle = (anim_tick * 0.08) + (i * (TAU / 3.0))
			var orb_pos = Vector2(cos(angle) * 11.0, sin(angle) * 7.0 - 4.0 + bob_y)
			draw_circle(orb_pos, 2.0, col_energy)
			draw_circle(orb_pos, 1.0, Color.WHITE)

## =========================================================================
## 4. PHANTOM-9 KAGE: SHADOW NINJA STANCE SWITCHER (Kenjutsu & Shinobi)
## =========================================================================
func _draw_kage_fighter() -> void:
	var bob_y: float = 0.0
	if current_state == &"Idle":
		bob_y = sin(anim_tick * 0.16) * 1.5
	elif current_state == &"Walk":
		bob_y = abs(sin(anim_tick * 0.36)) * 1.8
	elif current_state == &"Cliffhanger":
		bob_y = 6.0

	var head_center := Vector2(0, -14.0 + bob_y)
	if current_state == &"Meltdown":
		head_center.y += 3.0

	# 1. Flowing Crimson Ninja Scarf (Berkibar di leher ninja)
	var trail_offset = -6.0 if current_state == &"Walk" else -4.0
	var wave_1 = sin((anim_tick + 12) * 0.22) * 3.5
	var wave_2 = cos((anim_tick + 24) * 0.28) * 4.5
	var scarf_pts = PackedVector2Array([
		Vector2(-3, head_center.y + 3),
		Vector2(trail_offset - 4, head_center.y + 5 + wave_1),
		Vector2(trail_offset - 11, head_center.y + 7 + wave_2),
		Vector2(trail_offset - 16, head_center.y + 9 + wave_1)
	])
	draw_polyline(scarf_pts, col_belt, 2.5)
	draw_polyline(scarf_pts, col_highlight, 1.0)

	# 2. Celana Shinobi Gelap & Crimson Shin Guards
	if current_state == &"Walk":
		var stride = sin(anim_tick * 0.36) * 5.0
		_draw_fighter_leg(Vector2(-5 - stride, 5 + bob_y), Vector2(-6 - stride, 19 + bob_y), col_chassis, col_armor, 4.5)
		_draw_fighter_leg(Vector2(4 + stride, 5 + bob_y), Vector2(5 + stride, 19 + bob_y), col_chassis, col_armor, 4.5)
	else:
		_draw_fighter_leg(Vector2(-5, 5 + bob_y), Vector2(-7, 19 + bob_y), col_chassis, col_armor, 4.5)
		_draw_fighter_leg(Vector2(4, 5 + bob_y), Vector2(6, 19 + bob_y), col_chassis, col_armor, 4.5)

	# 3. Torso Ninja Berotot & Armor Mesh Hitam-Merah
	var chest_pts = PackedVector2Array([
		Vector2(-7, -8 + bob_y),
		Vector2(7, -8 + bob_y),
		Vector2(5, 5 + bob_y),
		Vector2(-5, 5 + bob_y)
	])
	draw_colored_polygon(chest_pts, col_chassis)

	var inner_armor = PackedVector2Array([
		Vector2(-4, -7 + bob_y),
		Vector2(4, -7 + bob_y),
		Vector2(2, 3 + bob_y),
		Vector2(-2, 3 + bob_y)
	])
	draw_colored_polygon(inner_armor, col_armor)
	draw_rect(Rect2(-6, 3 + bob_y, 12, 3), Color(0.12, 0.12, 0.16)) # Belt

	# 4. Kepala, Cowl Ninja & Glowing Crimson Mask
	draw_circle(head_center, 4.2, col_hair)
	# Glowing Crimson Visor / Eye Slits
	draw_line(Vector2(0, head_center.y - 1), Vector2(4, head_center.y - 1), col_visor, 1.5)
	draw_circle(Vector2(3, head_center.y - 1), 1.0, Color.WHITE)

	# 5. Katana (Kenjutsu) vs Shuriken (Shinobi)
	var is_kenjutsu: bool = true
	if parent_mecha and parent_mecha.get("current_stance"):
		is_kenjutsu = (parent_mecha.current_stance == &"kenjutsu")

	if current_state == &"Attack":
		if is_kenjutsu:
			# Slash Katana terhunus tajam
			var blade_start = Vector2(5, -6 + bob_y)
			var blade_tip = Vector2(22, -9 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), blade_start, col_skin, col_armor)
			draw_line(blade_start, blade_tip, col_highlight, 2.5)
			draw_line(blade_start, blade_tip, Color.WHITE, 1.2)
		else:
			# Lemparan Shuriken Bayangan
			var hand_pos = Vector2(16, -4 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), hand_pos, col_skin, col_armor)
			draw_circle(hand_pos, 3.5, col_energy)
			draw_circle(hand_pos, 1.5, Color.WHITE)
	else:
		# Pose tangan sigap bela diri ninja
		_draw_fighter_arm(Vector2(-5, -6 + bob_y), Vector2(-2, -3 + bob_y), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), Vector2(7, -4 + bob_y), col_skin, col_armor)
		if is_kenjutsu:
			# Katana terselip di punggung
			draw_line(Vector2(-6, 4 + bob_y), Vector2(8, -16 + bob_y), col_highlight, 2.0)
		else:
			# Shuriken siap di tangan depan
			draw_rect(Rect2(6, -6 + bob_y, 3, 3), col_energy)

## =========================================================================
## HELPER DRAWING FUNCTIONS (Smooth Anatomical Limbs)
## =========================================================================
func _draw_fighter_leg(hip: Vector2, foot: Vector2, pants_col: Color, boots_col: Color, width: float = 5.0) -> void:
	var mid = hip.lerp(foot, 0.5)
	# Paha & Celana bela diri
	draw_line(hip, mid, pants_col, width)
	# Betis & Boot bela diri
	draw_line(mid, foot, boots_col, width - 0.5)
	# Sepatu bela diri / telapak kaki
	draw_line(foot + Vector2(-1, 0), foot + Vector2(3, 0), Color(0.1, 0.1, 0.1), width - 1.0)

func _draw_fighter_arm(shoulder: Vector2, hand: Vector2, skin_c: Color, wrap_c: Color, thickness: float = 3.5) -> void:
	var elbow = shoulder.lerp(hand, 0.5)
	# Lengan atas
	draw_line(shoulder, elbow, skin_c, thickness)
	# Lengan bawah dengan balutan perban / wraps
	draw_line(elbow, hand, wrap_c, thickness)
	# Kepalan / Tapak tangan
	draw_circle(hand, thickness * 0.6, skin_c)
