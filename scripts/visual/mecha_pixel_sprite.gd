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
var attack_frame: int = 0

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

		if sm and sm.get("current_state"):
			if sm.current_state.name == &"Attack" and sm.current_state.get("current_attack_data"):
				var atk_d = sm.current_state.current_attack_data
				var n = atk_d.get("name", "")
				if n != "":
					attack_type = StringName(str(n))
				if "current_attack_frame" in sm.current_state:
					attack_frame = sm.current_state.current_attack_frame
			elif sm.current_state.name != &"Attack":
				attack_type = &""
				attack_frame = 0

	if hit_flash_frames > 0:
		hit_flash_frames -= 1

	queue_redraw()

func _draw() -> void:
	if hit_flash_frames > 0:
		draw_rect(Rect2(-12, -19, 24, 38), Color(1.0, 1.0, 1.0, 0.85))
		return

	# 1. Layer Efek Belakang (Underlay VFX: Aura, Pijaran Lantai, Uap, Partikel, Orbit Belakang)
	_draw_vfx_underlay()

	# 2. Render Karakter Utama Sesuai Archetype
	if archetype == &"bulwark":
		_draw_bulwark_fighter()
	elif archetype == &"pulsar":
		_draw_pulsar_fighter()
	elif archetype == &"kage":
		_draw_kage_fighter()
	else:
		_draw_viper_fighter()

	# 3. Layer Efek Depan (Overlay VFX: Visor Flare, Kilau Senjata, Busur Serangan, Orbit Depan, Petir Overclock)
	_draw_vfx_overlay()

## =========================================================================
## LAYER EFEK VISUAL BELAKANG (UNDERLAY VFX)
## =========================================================================
func _draw_vfx_underlay() -> void:
	var t: float = float(anim_tick) * 0.1
	var is_moving: bool = current_state in [&"Walk", &"Dash", &"AirDash"]

	# A. Overclock / Meltdown Super Saiyan Flame Aura (Semua Karakter)
	if is_overclocked or is_meltdown:
		var flame_col := col_highlight
		flame_col.a = 0.45 if is_overclocked else 0.7
		var core_col := col_armor
		core_col.a = 0.3
		# 5 Lidah api energi dinamis yang berkobar ke atas
		for i in range(5):
			var fx: float = -14.0 + float(i) * 7.0
			var h_flame: float = 24.0 + sin(t * 8.0 + float(i) * 1.5) * 8.0
			var flame_pts := PackedVector2Array([
				Vector2(fx - 4, 18),
				Vector2(fx + 4, 18),
				Vector2(fx + sin(t * 6.0 + float(i)) * 3.0, 18 - h_flame)
			])
			draw_colored_polygon(flame_pts, core_col)
			draw_polyline(flame_pts, flame_col, 1.2)

	# B. Efek Khusus per Karakter (Underlay)
	match archetype:
		&"viper":
			# Percikan plasma cyan di sekitar kaki saat bergerak/kuda-kuda
			for i in range(3):
				var px: float = -8.0 + float(i) * 8.0 + sin(t * 5.0 + float(i)) * 3.0
				var py: float = 18.0 - abs(sin(t * 6.0 + float(i))) * 6.0
				draw_circle(Vector2(px, py), 1.5, col_armor)
			if is_moving:
				# Cincin hembusan angin dash di belakang
				draw_arc(Vector2(-10, 8), 7.0, PI * 0.6, PI * 1.4, 6, Color(col_armor.r, col_armor.g, col_armor.b, 0.45), 1.5)

		&"bulwark":
			# Semburan uap knalpot termal hidrolik dari ventilasi bahu
			var steam_phase := sin(t * 4.0)
			if steam_phase > 0.0:
				var s_alpha := steam_phase * 0.5
				draw_circle(Vector2(-8, -17 - steam_phase * 5.0), 3.0 + steam_phase * 2.0, Color(0.9, 0.9, 0.95, s_alpha))
				draw_circle(Vector2(5, -17 - steam_phase * 5.0), 3.0 + steam_phase * 2.0, Color(0.9, 0.9, 0.95, s_alpha))
			# Gelombang debu seismik di tanah saat melangkah / idle
			var shock_r := 10.0 + sin(t * 3.0) * 4.0
			draw_arc(Vector2(0, 19), shock_r, 0.0, PI, 8, Color(col_armor.r, col_armor.g, col_armor.b, 0.35), 1.5)

		&"pulsar":
			# Cincin Lotus Zen Mandala bercahaya di bawah kaki
			var lotus_rot := t * 1.5
			var r_zen := 12.0
			draw_arc(Vector2(0, 19), r_zen, 0.0, TAU, 12, Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.35), 1.2)
			for k in range(4):
				var ang := lotus_rot + float(k) * (TAU / 4.0)
				var petal_tip := Vector2(cos(ang) * (r_zen + 3.0), 19.0 + sin(ang) * 2.0)
				draw_circle(petal_tip, 1.5, col_energy)
			# Setengah belakang dari 3 Bola Foton Magatama yang mengorbit
			_draw_pulsar_orbit_beads(t, true)

		&"kage":
			# Gumpalan asap bayangan hitam keunguan (Shadow Ink Wisps)
			for i in range(3):
				var ix: float = -10.0 + float(i) * 10.0 + sin(t * 4.0 + float(i)) * 4.0
				var iy: float = 14.0 - float((anim_tick * 2 + i * 25) % 35)
				var alpha: float = clampf(1.0 - (14.0 - iy) / 35.0, 0.0, 0.55)
				draw_circle(Vector2(ix, iy), 3.0, Color(0.06, 0.04, 0.1, alpha))
			# Kelopak bunga mawar crimson melayang di belakang
			var petal_x := -12.0 + sin(t * 3.0) * 5.0
			var petal_y := 4.0 + cos(t * 2.5) * 6.0
			draw_rect(Rect2(petal_x, petal_y, 3, 2), Color(0.95, 0.15, 0.25, 0.8))

## =========================================================================
## LAYER EFEK VISUAL DEPAN (OVERLAY VFX)
## =========================================================================
func _draw_vfx_overlay() -> void:
	var t: float = float(anim_tick) * 0.1
	var is_attacking: bool = (current_state == &"Attack" or attack_type != &"")

	# A. Busur Kilatan Petir Overclock (Semua Karakter)
	if is_overclocked and (anim_tick % 4 == 0):
		var p1 := Vector2(randf_range(-8, 8), randf_range(-16, 16))
		var p2 := p1 + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		draw_line(p1, p2, Color.WHITE, 1.5)
		draw_line(p1, p2, col_highlight, 3.0)

	# B. Efek Khusus per Karakter (Overlay)
	match archetype:
		&"viper":
			# Visor Laser Streak (Kilauan garis mata tajam saat bergerak/menyerang)
			var eye_y := -13.0 + sin(anim_tick * 0.15) * 1.5
			var flare_len := 12.0 if is_attacking else 6.0
			draw_line(Vector2(0, eye_y), Vector2(flare_len, eye_y), col_armor, 2.0)
			draw_line(Vector2(2, eye_y), Vector2(flare_len - 2, eye_y), Color.WHITE, 1.2)
			# Kilau Berlian (✦ Sparkle) pada gagang bilah pedang di pinggul
			if anim_tick % 30 < 6:
				_draw_sparkle_cross(Vector2(-6, 5), 3.5, Color.WHITE, col_highlight)
			# Busur Tebasan Plasma Cyan saat menyerang
			if is_attacking:
				var arc_rad := 20.0
				draw_arc(Vector2(6, 0), arc_rad, -PI * 0.45, PI * 0.45, 10, col_armor, 2.5)
				draw_arc(Vector2(6, 0), arc_rad - 2.0, -PI * 0.35, PI * 0.35, 8, Color.WHITE, 1.5)

		&"bulwark":
			# Bara Api Magma Membara pada Tangan/Sarung Tinju
			var fist_pulse := 0.7 + 0.3 * sin(t * 8.0)
			var fist_pos := Vector2(10, 4) if is_attacking else Vector2(8, 2)
			draw_circle(fist_pos, 4.0, Color(1.0, 0.4, 0.05, 0.7 * fist_pulse))
			draw_circle(fist_pos, 2.0, Color(1.0, 0.9, 0.3, 0.9))
			# Reaktor Inti Dada Oranye berdenyut
			draw_circle(Vector2(1, -2), 2.5, Color(1.0, 0.55, 0.1, 0.8 * fist_pulse))
			# Ledakan Benturan Seismik Kinetik saat menyerang
			if is_attacking:
				draw_line(Vector2(10, 0), Vector2(24, -6), Color(1.0, 0.6, 0.1), 3.0)
				draw_line(Vector2(10, 4), Vector2(26, 4), Color(1.0, 0.9, 0.2), 3.0)
				draw_line(Vector2(10, 8), Vector2(24, 14), Color(1.0, 0.6, 0.1), 3.0)

		&"pulsar":
			# Setengah depan dari 3 Bola Foton Magatama yang mengorbit
			_draw_pulsar_orbit_beads(t, false)
			# Kilau Mata Ketiga Zen (Lens Flare Cross di dahi)
			if anim_tick % 24 < 6:
				_draw_sparkle_cross(Vector2(3, -15), 4.0, Color.WHITE, col_energy)
			# Gelombang Cincin Foton saat menyerang
			if is_attacking:
				draw_arc(Vector2(16, -2), 12.0, -PI * 0.5, PI * 0.5, 8, col_armor, 2.5)
				draw_arc(Vector2(20, -2), 16.0, -PI * 0.4, PI * 0.4, 8, col_energy, 2.0)
				draw_line(Vector2(12, -2), Vector2(26, -2), Color.WHITE, 1.8)

		&"kage":
			# Jejak Mata Iblis Merah (Crimson Eye Streak)
			var kage_eye_y := -13.0 + sin(anim_tick * 0.15) * 1.5
			draw_line(Vector2(1, kage_eye_y), Vector2(10, kage_eye_y), Color(1.0, 0.1, 0.2), 2.0)
			draw_line(Vector2(3, kage_eye_y), Vector2(8, kage_eye_y), Color.WHITE, 1.0)
			# Bayangan Hitam Mengabur di Belakang Tubuh (Shadow Silhouette)
			draw_rect(Rect2(-10, -15, 8, 28), Color(0.04, 0.02, 0.08, 0.35))
			# Busur Tebasan Sabit Merah Darah saat menyerang
			if is_attacking:
				var kage_arc_rad := 22.0
				draw_arc(Vector2(8, -2), kage_arc_rad, -PI * 0.5, PI * 0.4, 10, Color(0.95, 0.15, 0.25), 3.0)
				draw_arc(Vector2(8, -2), kage_arc_rad - 2.0, -PI * 0.4, PI * 0.3, 8, Color.WHITE, 1.5)

## Gambar 3 Bola Foton Magatama yang mengorbit tubuh Pulsar secara dinamis
func _draw_pulsar_orbit_beads(t: float, is_rear_layer: bool) -> void:
	var num_beads := 3
	var rx := 16.0
	var ry := 7.0
	var cy := -2.0
	for i in range(num_beads):
		var ang: float = t * 2.5 + float(i) * (TAU / float(num_beads))
		var sin_val := sin(ang)
		var is_rear := sin_val < 0.0
		if is_rear != is_rear_layer:
			continue
		var bx: float = cos(ang) * rx
		var by: float = cy + sin_val * ry
		var bead_radius: float = 3.0 if not is_rear else 2.2
		# Bola foton bercahaya
		draw_circle(Vector2(bx, by), bead_radius + 1.5, Color(col_armor.r, col_armor.g, col_armor.b, 0.4))
		draw_circle(Vector2(bx, by), bead_radius, col_armor)
		draw_circle(Vector2(bx, by), bead_radius * 0.5, Color.WHITE)

## Gambar efek kilau bintang salib (✦ Diamond Sparkle)
func _draw_sparkle_cross(pos: Vector2, size: float, core_c: Color, glow_c: Color) -> void:
	draw_line(pos - Vector2(size, 0), pos + Vector2(size, 0), glow_c, 2.5)
	draw_line(pos - Vector2(0, size), pos + Vector2(0, size), glow_c, 2.5)
	draw_line(pos - Vector2(size * 0.7, 0), pos + Vector2(size * 0.7, 0), core_c, 1.2)
	draw_line(pos - Vector2(0, size * 0.7), pos + Vector2(0, size * 0.7), core_c, 1.2)

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

	# 5. Lengan & Kepalan Tangan Bela Diri (Martial Guard / Distinct Techniques)
	if current_state == &"Attack":
		_draw_viper_attack_pose(bob_y)
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

	# 4. Lengan Kekar & Sarung Tinju / Distinct Brawler Techniques
	if current_state == &"Attack":
		_draw_bulwark_attack_pose(bob_y)
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

	# 4. Lengan & Tapak Bela Diri (Shaolin Photon Mastery / Distinct Techniques)
	if current_state == &"Attack":
		_draw_pulsar_attack_pose(bob_y)
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
		_draw_kage_attack_pose(bob_y, is_kenjutsu)
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

## =========================================================================
## TEKNIK-TEKNIK MENYERANG & EFEK VISUAL SKILL KARAKTER SPESIFIK
## =========================================================================

## 1. APEX-0 VIPER: BEAM RAPIER COMBAT TECHNIQUES
func _draw_viper_attack_pose(bob_y: float) -> void:
	var atk_str := String(attack_type).to_lower()

	if atk_str.contains("deflection") or atk_str.contains("matrix") or atk_str == "skill2":
		# Skill 2: Deflection Matrix - Holographic Hexagonal Shield Matrix
		_draw_fighter_arm(Vector2(-4, -6 + bob_y), Vector2(10, -8 + bob_y), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), Vector2(12, -2 + bob_y), col_skin, col_armor)
		var center_hex := Vector2(16.0, -5.0 + bob_y)
		var hex_r := 12.0
		var hex_pts := PackedVector2Array()
		for i in range(6):
			var a := deg_to_rad(60.0 * float(i) + (float(anim_tick) * 4.0))
			hex_pts.append(center_hex + Vector2(cos(a), sin(a)) * hex_r)
		var hex_closed := hex_pts.duplicate()
		hex_closed.append(hex_pts[0])
		draw_colored_polygon(hex_pts, Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.25))
		draw_polyline(hex_closed, col_highlight, 2.0)
		draw_polyline(hex_closed, Color.WHITE, 1.0)
		for p in hex_pts:
			draw_circle(p, 1.5, col_energy)

	elif atk_str.contains("blink") or atk_str == "skill1":
		# Skill 1: Blink Slash - Low Evasive Phantom Dash with Twin Trailing Rapiers
		var f_pos1 := Vector2(-16.0, 2.0 + bob_y)
		var f_pos2 := Vector2(-22.0, 6.0 + bob_y)
		_draw_fighter_arm(Vector2(-5, -4 + bob_y), f_pos1, col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -4 + bob_y), f_pos2, col_skin, col_armor)
		draw_line(f_pos1, f_pos1 + Vector2(-14, 2), col_energy, 2.5)
		draw_line(f_pos1, f_pos1 + Vector2(-12, 2), Color.WHITE, 1.2)
		draw_line(f_pos2, f_pos2 + Vector2(-16, 4), col_energy, 2.5)
		draw_line(f_pos2, f_pos2 + Vector2(-14, 4), Color.WHITE, 1.2)
		draw_line(Vector2(8, -8 + bob_y), Vector2(24, -8 + bob_y), Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.6), 1.5)
		draw_line(Vector2(10, -2 + bob_y), Vector2(28, -2 + bob_y), Color(1, 1, 1, 0.8), 1.5)

	elif atk_str.contains("zero") or atk_str.contains("protocol") or atk_str == "ultimate":
		# Ultimate: Absolute Zero Protocol - Sub-Zero Cryo Spikes & Ascension Stance
		_draw_fighter_arm(Vector2(-5, -6 + bob_y), Vector2(-7, 2 + bob_y), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), Vector2(7, 2 + bob_y), col_skin, col_armor)
		draw_colored_polygon(PackedVector2Array([Vector2(-12, 19 + bob_y), Vector2(-9, 6 + bob_y), Vector2(-6, 19 + bob_y)]), col_highlight)
		draw_colored_polygon(PackedVector2Array([Vector2(8, 19 + bob_y), Vector2(12, 4 + bob_y), Vector2(15, 19 + bob_y)]), col_energy)
		draw_colored_polygon(PackedVector2Array([Vector2(1, 19 + bob_y), Vector2(4, 9 + bob_y), Vector2(7, 19 + bob_y)]), Color.WHITE)

	elif atk_str.contains("5h") or atk_str.contains("cleave"):
		# 5H: Plasma Cleave - Overhead 180° Vertical Neon Crescent Arc
		var hand_pos := Vector2(14.0, 2.0 + bob_y)
		_draw_fighter_arm(Vector2(4, -7 + bob_y), hand_pos, col_skin, col_armor)
		draw_arc(Vector2(4, -3 + bob_y), 18.0, -PI * 0.55, PI * 0.35, 12, col_energy, 3.5)
		draw_arc(Vector2(4, -3 + bob_y), 18.0, -PI * 0.5, PI * 0.3, 10, Color.WHITE, 1.5)
		draw_circle(Vector2(18, 9 + bob_y), 2.5, col_highlight)

	elif atk_str.contains("5l2") or atk_str.contains("thrust"):
		# 5L2: Sonic Thrust - Deep Low Forward Lunge with Conical Shockwave Rings
		var lunge_x := 24.0
		_draw_fighter_arm(Vector2(4, -4 + bob_y), Vector2(lunge_x, -4 + bob_y), col_skin, col_armor)
		draw_line(Vector2(lunge_x, -4 + bob_y), Vector2(lunge_x + 22, -4 + bob_y), col_energy, 3.0)
		draw_line(Vector2(lunge_x, -4 + bob_y), Vector2(lunge_x + 20, -4 + bob_y), Color.WHITE, 1.5)
		draw_arc(Vector2(lunge_x + 10, -4 + bob_y), 6.0, -PI * 0.5, PI * 0.5, 8, col_highlight, 1.5)
		draw_arc(Vector2(lunge_x + 16, -4 + bob_y), 9.0, -PI * 0.5, PI * 0.5, 8, Color.WHITE, 1.2)

	else:
		# 5L / 5L1: Viper Jab - Rapid Precision Rapier Jab with Spark Point
		draw_circle(Vector2(-3, -2 + bob_y), 2.5, col_skin)
		var punch_x := 18.0
		_draw_fighter_arm(Vector2(4, -5 + bob_y), Vector2(punch_x, -5 + bob_y), col_skin, col_armor)
		draw_line(Vector2(punch_x, -5 + bob_y), Vector2(punch_x + 16, -5 + bob_y), col_energy, 2.5)
		draw_line(Vector2(punch_x, -5 + bob_y), Vector2(punch_x + 14, -5 + bob_y), Color.WHITE, 1.2)
		draw_circle(Vector2(punch_x + 16, -5 + bob_y), 2.0, col_highlight)

## 2. TITAN-V BULWARK: HEAVYWEIGHT BRAWLER & GRAPPLER TECHNIQUES
func _draw_bulwark_attack_pose(bob_y: float) -> void:
	var atk_str := String(attack_type).to_lower()

	if atk_str.contains("piledriver") or atk_str.contains("hydraulic") or atk_str == "skill1":
		# Skill 1: Hydraulic Piledriver - Clamping Steel Claws with High-Pressure Steam Piston
		var cakar_top := Vector2(20.0, -10.0 + bob_y)
		var cakar_bot := Vector2(20.0, 2.0 + bob_y)
		_draw_fighter_arm(Vector2(5, -7 + bob_y), cakar_top, col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(5, -3 + bob_y), cakar_bot, col_skin, col_armor, 4.5)
		draw_line(cakar_top, cakar_top + Vector2(6, 4), col_highlight, 3.0)
		draw_line(cakar_bot, cakar_bot + Vector2(6, -4), col_highlight, 3.0)
		draw_line(Vector2(2, -10 + bob_y), Vector2(-4, -14 + bob_y), Color.WHITE, 2.0)
		draw_line(Vector2(2, -1 + bob_y), Vector2(-4, 3 + bob_y), Color.WHITE, 2.0)

	elif atk_str.contains("riot") or atk_str.contains("shield") or atk_str == "skill2":
		# Skill 2: Riot Shield Deploy - Heavy Steel Blast Shield with Hazard Caution Stripes
		_draw_fighter_arm(Vector2(-4, -5 + bob_y), Vector2(8, -8 + bob_y), col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(4, -5 + bob_y), Vector2(10, 4 + bob_y), col_skin, col_armor, 4.5)
		draw_rect(Rect2(11, -18 + bob_y, 8, 36), col_chassis)
		draw_rect(Rect2(12, -17 + bob_y, 6, 34), col_armor)
		for i in range(4):
			var hy := -14.0 + float(i) * 8.0 + bob_y
			draw_line(Vector2(12, hy), Vector2(18, hy + 5), col_highlight, 1.8)
		draw_line(Vector2(15, 18 + bob_y), Vector2(15, 23 + bob_y), Color.WHITE, 2.5)

	elif atk_str.contains("orbital") or atk_str.contains("cannon") or atk_str == "ultimate":
		# Ultimate: Orbital Siege Cannon - Tripod Artillery Lock Aiming Skyward
		_draw_fighter_arm(Vector2(-5, -5 + bob_y), Vector2(0, 4 + bob_y), col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(5, -6 + bob_y), Vector2(8, -14 + bob_y), col_skin, col_armor, 4.5)
		var muzzle := Vector2(8, -26 + bob_y)
		draw_line(Vector2(6, -8 + bob_y), muzzle, col_armor, 5.0)
		draw_line(Vector2(6, -8 + bob_y), muzzle, Color.WHITE, 2.0)
		draw_arc(muzzle, 5.0, -PI, PI, 10, col_highlight, 2.0)
		draw_arc(muzzle, 8.0, -PI, PI, 10, Color(1.0, 0.85, 0.2, 0.7), 1.5)
		draw_circle(muzzle, 3.0, Color.WHITE)

	elif atk_str.contains("5h") or atk_str.contains("slam"):
		# 5H: Earthbreaker Hammer Slam - Intertwined Double Hammer Fists Crashing Down
		var slam_pos := Vector2(14.0, 10.0 + bob_y)
		_draw_fighter_arm(Vector2(-2, -8 + bob_y), slam_pos, col_skin, col_armor, 4.5)
		_draw_fighter_arm(Vector2(6, -8 + bob_y), slam_pos, col_skin, col_armor, 4.5)
		draw_circle(slam_pos, 5.5, col_armor)
		draw_circle(slam_pos, 3.0, col_highlight)
		draw_line(Vector2(slam_pos.x - 6, 19 + bob_y), Vector2(slam_pos.x + 12, 19 + bob_y), Color.WHITE, 2.0)
		draw_line(Vector2(slam_pos.x + 2, 19 + bob_y), Vector2(slam_pos.x + 8, 24 + bob_y), col_highlight, 1.5)

	else:
		# 5L: Megaton Straight Punch - Rocket Knuckle with Back Exhaust Flame
		var punch_pos := Vector2(20.0, -5 + bob_y)
		_draw_fighter_arm(Vector2(6, -6 + bob_y), punch_pos, col_skin, col_armor, 4.5)
		draw_circle(punch_pos, 4.5, col_armor)
		draw_circle(punch_pos + Vector2(2, 0), 2.5, col_highlight)
		draw_arc(punch_pos + Vector2(3, 0), 6.0, -PI * 0.5, PI * 0.5, 8, col_highlight, 1.5)
		draw_line(Vector2(-9, -6 + bob_y), Vector2(-16, -6 + bob_y), col_thruster, 3.0)
		draw_line(Vector2(-9, -6 + bob_y), Vector2(-13, -6 + bob_y), Color.WHITE, 1.5)

## 3. RAY-X PULSAR: SHAOLIN PHOTON & SPATIAL TECHNIQUES
func _draw_pulsar_attack_pose(bob_y: float) -> void:
	var atk_str := String(attack_type).to_lower()

	if atk_str.contains("railgun") or atk_str.contains("photon") or atk_str == "skill1":
		# Skill 1: Photon Railgun - Diamond Focus Prism Mudra with Guiding Laser Ray
		var prism_pos := Vector2(16.0, -4.0 + bob_y)
		_draw_fighter_arm(Vector2(-4, -5 + bob_y), prism_pos, col_skin, col_highlight, 3.5)
		_draw_fighter_arm(Vector2(4, -5 + bob_y), prism_pos, col_skin, col_highlight, 3.5)
		var prism_poly := PackedVector2Array([
			prism_pos + Vector2(0, -6),
			prism_pos + Vector2(5, 0),
			prism_pos + Vector2(0, 6),
			prism_pos + Vector2(-5, 0)
		])
		draw_colored_polygon(prism_poly, col_energy)
		draw_polyline(prism_poly, Color.WHITE, 1.5)
		draw_line(prism_pos, prism_pos + Vector2(28, 0), Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.8), 2.5)
		draw_line(prism_pos, prism_pos + Vector2(26, 0), Color.WHITE, 1.2)

	elif atk_str.contains("drone") or atk_str.contains("disrupter") or atk_str == "skill2":
		# Skill 2: Disrupter Drone - Tactical Upward Mudra with Floating Pod & Scanner Cone
		_draw_fighter_arm(Vector2(-4, -5 + bob_y), Vector2(-1, 0 + bob_y), col_skin, col_highlight)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), Vector2(10, -18 + bob_y), col_skin, col_highlight)
		var drone_pos := Vector2(14.0, -26.0 + bob_y)
		var d_poly := PackedVector2Array([
			drone_pos + Vector2(0, -5),
			drone_pos + Vector2(6, 4),
			drone_pos + Vector2(-6, 4)
		])
		draw_colored_polygon(d_poly, col_armor)
		draw_polyline(d_poly, col_highlight, 1.2)
		draw_circle(drone_pos, 2.0, col_energy)
		draw_line(drone_pos, drone_pos + Vector2(-8, 12), Color(col_energy.r, col_energy.g, col_energy.b, 0.5), 1.0)
		draw_line(drone_pos, drone_pos + Vector2(8, 12), Color(col_energy.r, col_energy.g, col_energy.b, 0.5), 1.0)

	elif atk_str.contains("supernova") or atk_str.contains("horizon") or atk_str == "ultimate":
		# Ultimate: Supernova Horizon - Levitating Cosmic Zen Meditation
		var lev_y := bob_y - 8.0
		_draw_fighter_arm(Vector2(-5, -6 + lev_y), Vector2(-10, -4 + lev_y), col_skin, col_highlight)
		_draw_fighter_arm(Vector2(4, -6 + lev_y), Vector2(10, -4 + lev_y), col_skin, col_highlight)
		for i in range(3):
			var angle := (float(anim_tick) * 0.16) + (float(i) * (TAU / 3.0))
			var orb_pos := Vector2(cos(angle) * 16.0, sin(angle) * 10.0 - 4.0 + lev_y)
			draw_circle(orb_pos, 4.0, col_energy)
			draw_circle(orb_pos, 2.0, Color.WHITE)
			draw_arc(orb_pos, 6.0, 0, TAU, 8, col_highlight, 1.0)
		draw_arc(Vector2(0, -4 + lev_y), 20.0, 0, TAU, 16, Color(1.0, 0.85, 0.2, 0.6), 1.5)

	elif atk_str.contains("5h") or atk_str.contains("lance"):
		# 5H: Plasma Lance - Flying Sweep Thrust with Energy Spiral Helices
		var lance_pos := Vector2(22.0, -5.0 + bob_y)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), lance_pos, col_skin, col_highlight)
		draw_line(Vector2(lance_pos.x - 8, -5 + bob_y), Vector2(lance_pos.x + 24, -5 + bob_y), col_energy, 3.5)
		draw_line(Vector2(lance_pos.x - 6, -5 + bob_y), Vector2(lance_pos.x + 22, -5 + bob_y), Color.WHITE, 1.5)
		draw_arc(Vector2(lance_pos.x + 6, -5 + bob_y), 5.0, -PI, PI, 8, col_highlight, 1.2)
		draw_arc(Vector2(lance_pos.x + 14, -5 + bob_y), 4.0, -PI, PI, 8, col_highlight, 1.2)

	else:
		# 5L: Twin Photon Palm - Double Shaolin Concentric Waves
		var palm_pos1 := Vector2(16.0, -8.0 + bob_y)
		var palm_pos2 := Vector2(18.0, -1.0 + bob_y)
		_draw_fighter_arm(Vector2(-3, -6 + bob_y), palm_pos1, col_skin, col_highlight)
		_draw_fighter_arm(Vector2(4, -5 + bob_y), palm_pos2, col_skin, col_highlight)
		draw_circle(palm_pos1, 3.5, Color(col_energy.r, col_energy.g, col_energy.b, 0.8))
		draw_circle(palm_pos1, 1.8, Color.WHITE)
		draw_circle(palm_pos2, 4.0, Color(col_energy.r, col_energy.g, col_energy.b, 0.8))
		draw_circle(palm_pos2, 2.0, Color.WHITE)
		draw_arc(Vector2(20, -4 + bob_y), 8.0, -PI * 0.5, PI * 0.5, 8, col_highlight, 1.5)

## 4. PHANTOM-9 KAGE: DUAL-STANCE SHADOW SHINOBI TECHNIQUES
func _draw_kage_attack_pose(bob_y: float, is_kenjutsu: bool) -> void:
	var atk_str := String(attack_type).to_lower()

	if atk_str.contains("stance") or atk_str == "skill1":
		# Skill 1: Stance Shift & Shadow Feint - Ninja Smoke Vanish Silhouette
		for i in range(5):
			var a := float(i) * (TAU / 5.0) + (float(anim_tick) * 0.1)
			var sp := Vector2(cos(a) * 12.0, sin(a) * 8.0 - 6.0 + bob_y)
			draw_circle(sp, 6.0, Color(0.1, 0.08, 0.12, 0.7))
			draw_circle(sp, 4.0, Color(col_armor.r, col_armor.g, col_armor.b, 0.4))
		draw_line(Vector2(2, -15 + bob_y), Vector2(8, -15 + bob_y), col_visor, 2.0)

	elif atk_str.contains("blossom") or atk_str == "ultimate":
		# Ultimate: Shadow Blossom - Tsukuyomi Multi-Cross Slash with Flying Petals
		_draw_fighter_arm(Vector2(-4, -6 + bob_y), Vector2(-10, -2 + bob_y), col_skin, col_armor)
		_draw_fighter_arm(Vector2(4, -6 + bob_y), Vector2(16, -6 + bob_y), col_skin, col_armor)
		draw_line(Vector2(6, -18 + bob_y), Vector2(26, 6 + bob_y), col_highlight, 3.0)
		draw_line(Vector2(6, -18 + bob_y), Vector2(26, 6 + bob_y), Color.WHITE, 1.2)
		draw_line(Vector2(6, 6 + bob_y), Vector2(26, -18 + bob_y), col_highlight, 3.0)
		draw_line(Vector2(6, 6 + bob_y), Vector2(26, -18 + bob_y), Color.WHITE, 1.2)
		draw_circle(Vector2(14, -12 + bob_y), 2.0, col_armor)
		draw_circle(Vector2(22, 2 + bob_y), 1.8, col_armor)
		draw_circle(Vector2(8, 0 + bob_y), 2.2, col_armor)

	elif is_kenjutsu:
		if atk_str.contains("iaido") or atk_str == "skill2":
			# Kenjutsu Skill 2: Iaido Crescent Strike - Extreme Low Dash Crescent Blood Wave
			var blade_start := Vector2(8, -2 + bob_y)
			var blade_tip := Vector2(26, -6 + bob_y)
			_draw_fighter_arm(Vector2(4, -5 + bob_y), blade_start, col_skin, col_armor)
			draw_line(blade_start, blade_tip, col_highlight, 3.0)
			draw_line(blade_start, blade_tip, Color.WHITE, 1.5)
			draw_arc(Vector2(16, -4 + bob_y), 16.0, -PI * 0.6, PI * 0.4, 10, col_armor, 3.0)
			draw_arc(Vector2(16, -4 + bob_y), 16.0, -PI * 0.55, PI * 0.35, 10, Color.WHITE, 1.5)
		elif atk_str.contains("5h") or atk_str.contains("cleave"):
			# Kenjutsu 5H: Katana Cleave - Two-Handed Overhead Executioner Chop
			var hilt_pos := Vector2(8, -18 + bob_y)
			var tip_pos := Vector2(18, 10 + bob_y)
			_draw_fighter_arm(Vector2(-3, -7 + bob_y), hilt_pos, col_skin, col_armor)
			_draw_fighter_arm(Vector2(4, -7 + bob_y), hilt_pos, col_skin, col_armor)
			draw_line(hilt_pos, tip_pos, col_highlight, 3.0)
			draw_line(hilt_pos, tip_pos, Color.WHITE, 1.5)
			draw_line(Vector2(10, -20 + bob_y), Vector2(20, 8 + bob_y), Color(col_highlight.r, col_highlight.g, col_highlight.b, 0.5), 2.0)
		else:
			# Kenjutsu 5L: Katana Slash - Quick-Draw Iaido Horizontal Slash
			var blade_start := Vector2(5, -6 + bob_y)
			var blade_tip := Vector2(22, -9 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), blade_start, col_skin, col_armor)
			draw_line(blade_start, blade_tip, col_highlight, 2.5)
			draw_line(blade_start, blade_tip, Color.WHITE, 1.2)
			draw_line(blade_tip, blade_tip + Vector2(6, -1), col_highlight, 1.5)

	else:
		# SHINOBI STANCE
		if atk_str.contains("shuriken") or atk_str.contains("storm") or atk_str == "skill2":
			# Shinobi Skill 2: Shuriken Storm - Spinning Razor Star Flurry
			var hand_pos := Vector2(16, -5 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), hand_pos, col_skin, col_armor)
			for i in range(3):
				var sx: float = hand_pos.x + 8.0 + float(i) * 7.0
				var sy: float = hand_pos.y + float(i % 2) * 6.0 - 3.0
				_draw_mini_shuriken(Vector2(sx, sy), (float(anim_tick) * 0.3) + float(i))
		elif atk_str.contains("5h") or atk_str.contains("flurry"):
			# Shinobi 5H: Kunai Flurry - Tri-Kunai Fan Spread
			var hand_pos := Vector2(16, -4 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), hand_pos, col_skin, col_armor)
			_draw_kunai(hand_pos + Vector2(6, -6), -0.25)
			_draw_kunai(hand_pos + Vector2(8, 0), 0.0)
			_draw_kunai(hand_pos + Vector2(6, 6), 0.25)
		else:
			# Shinobi 5L: Phantom Kunai - Sharp Wrist Throw
			var hand_pos := Vector2(16, -4 + bob_y)
			_draw_fighter_arm(Vector2(4, -6 + bob_y), hand_pos, col_skin, col_armor)
			_draw_kunai(hand_pos + Vector2(8, 0), 0.0)

func _draw_mini_shuriken(pos: Vector2, rot: float) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -4).rotated(rot),
		pos + Vector2(4, 0).rotated(rot),
		pos + Vector2(0, 4).rotated(rot),
		pos + Vector2(-4, 0).rotated(rot)
	])
	draw_colored_polygon(pts, col_armor)
	draw_polyline(pts, Color.WHITE, 1.0)
	draw_circle(pos, 1.0, Color.BLACK)

func _draw_kunai(pos: Vector2, angle: float) -> void:
	var tip := pos + Vector2(6, 0).rotated(angle)
	var base1 := pos + Vector2(-3, -2).rotated(angle)
	var base2 := pos + Vector2(-3, 2).rotated(angle)
	draw_colored_polygon(PackedVector2Array([tip, base1, base2]), col_armor)
	draw_line(pos + Vector2(-3, 0).rotated(angle), pos + Vector2(-6, 0).rotated(angle), Color.WHITE, 1.2)
