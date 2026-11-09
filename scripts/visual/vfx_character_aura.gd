class_name VFXCharacterAura
extends Node2D

## Efek Visual Aura Cahaya Karakter (Persistent Character Light/Glow)
## Menggambar cincin energi berdenyut, partikel motes mengorbit, dan pendaran tanah
## berwarna profil VFX karakter. Dapat mengikuti target Node2D atau dipasang statis.
## Memberikan nuansa "cahaya" pada karakter saat idle, skill, atau overclock.

@export var aura_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var secondary_color: Color = Color(0.1, 0.55, 0.85, 1.0)
@export var base_radius: float = 28.0
@export var intensity: float = 1.0 ## 0.6=idle, 1.0=active, 1.5=overclock/ult
@export var duration_seconds: float = 0.0 ## 0 = persistent until freed externally
@export var follow_target: bool = true

var _elapsed: float = 0.0
var _active: bool = false
var _target: Node2D = null
var _offset: Vector2 = Vector2(0.0, -4.0)
var _motes: Array[Dictionary] = []
var _pulse: float = 0.0
var _heat_aware: bool = false
var _profile_primary: Color = Color.TRANSPARENT
var _profile_secondary: Color = Color.TRANSPARENT
var _is_meltdown_visual: bool = false

func _ready() -> void:
	z_index = 8 # di belakang sprite karakter tapi di atas latar
	set_physics_process(true)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func setup(target: Node2D = null, pos: Vector2 = Vector2.ZERO, custom_color: Color = Color.TRANSPARENT,
		custom_secondary: Color = Color.TRANSPARENT, power: float = 1.0,
		duration: float = 0.0, offset: Vector2 = Vector2(0.0, -4.0), heat_aware: bool = false) -> void:
	_target = target
	follow_target = is_instance_valid(target)
	if follow_target:
		global_position = target.global_position + offset
	else:
		global_position = pos
	_offset = offset
	intensity = clampf(power, 0.3, 2.5)
	duration_seconds = duration
	_heat_aware = heat_aware
	_profile_primary = custom_color if custom_color != Color.TRANSPARENT else aura_color
	_profile_secondary = custom_secondary if custom_secondary != Color.TRANSPARENT else secondary_color
	if custom_color != Color.TRANSPARENT:
		aura_color = custom_color
	if custom_secondary != Color.TRANSPARENT:
		secondary_color = custom_secondary
	_is_meltdown_visual = false
	_elapsed = 0.0
	_active = true
	_spawn_motes()
	queue_redraw()

func _spawn_motes() -> void:
	_motes.clear()
	var count := int(6 + intensity * 4.0)
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		_motes.append({
			"angle": ang,
			"dist": randf_range(base_radius * 0.4, base_radius * 1.15),
			"speed": randf_range(1.2, 3.2) * (1.0 if randf() > 0.5 else -1.0),
			"size": randf_range(1.2, 2.8) * intensity,
			"phase": randf_range(0.0, TAU),
			"rise": randf_range(-8.0, 8.0),
		})

func trigger_aura(target: Node2D = null, pos: Vector2 = Vector2.ZERO,
		custom_color: Color = Color.TRANSPARENT, power: float = 1.0, duration: float = 0.0) -> void:
	setup(target, pos, custom_color, Color.TRANSPARENT, power, duration)

func set_colors(primary: Color, secondary: Color = Color.TRANSPARENT) -> void:
	aura_color = primary
	if secondary != Color.TRANSPARENT:
		secondary_color = secondary
	queue_redraw()

func set_intensity(power: float) -> void:
	intensity = clampf(power, 0.3, 2.5)
	queue_redraw()

func is_active() -> bool:
	return _active

func deactivate() -> void:
	_active = false
	queue_free()

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_pulse += delta * (3.0 + intensity * 1.5)

	if follow_target:
		if is_instance_valid(_target):
			global_position = _target.global_position + _offset
		else:
			# Target hilang: tetap hidup di posisi terakhir jika persistent, atau mati
			follow_target = false
			if duration_seconds <= 0.0:
				duration_seconds = 0.35

	if duration_seconds > 0.0 and _elapsed >= duration_seconds:
		_active = false
		queue_free()
		return

	if _heat_aware and is_instance_valid(_target):
		_update_heat_visual()

	# Update motes
	for m in _motes:
		m["angle"] += m["speed"] * delta
		m["phase"] += delta * 4.0
	queue_redraw()

func _get_target_heat_ratio() -> float:
	if not is_instance_valid(_target):
		return 0.0
	var max_h: float = 100.0
	var cur_h: float = 0.0
	var hc = _target.get("heat_component")
	if is_instance_valid(hc):
		var hv = hc.get("current_heat")
		if hv != null:
			cur_h = float(hv)
		var hmv = hc.get("max_heat")
		if hmv != null:
			max_h = maxf(1.0, float(hmv))
	else:
		var gv = _target.get("heat_gauge")
		if gv != null:
			cur_h = float(gv)
	var mg = _target.get("max_heat")
	if mg != null:
		max_h = maxf(1.0, float(mg))
	return clampf(cur_h / maxf(1.0, max_h), 0.0, 1.0)

func _is_target_overclocked() -> bool:
	if not is_instance_valid(_target):
		return false
	if _target.has_method("is_overclocked"):
		return bool(_target.is_overclocked())
	return false

func _is_target_meltdown() -> bool:
	if not is_instance_valid(_target):
		return false
	var sm = _target.get("state_machine")
	if is_instance_valid(sm) and sm.get("current_state") != null:
		var st = sm.current_state
		if st != null and st.get("name") == &"Meltdown":
			return true
	return false

func _update_heat_visual() -> void:
	var heat_r := _get_target_heat_ratio()
	var over := _is_target_overclocked()
	var melt := _is_target_meltdown()
	_is_meltdown_visual = melt

	var pcol := _profile_primary if _profile_primary != Color.TRANSPARENT else aura_color
	var scol := _profile_secondary if _profile_secondary != Color.TRANSPARENT else secondary_color
	var hot_col := Color(1.0, 0.72, 0.22, 1.0)
	var alarm_col := Color(1.0, 0.18, 0.12, 1.0)

	if melt:
		# Meltdown: redup/berkedip alarm merah
		var alarm_pulse := 0.45 + 0.55 * sin(_pulse * 2.8)
		aura_color = alarm_col.lerp(Color(0.45, 0.05, 0.05, 1.0), 0.35)
		secondary_color = Color(1.0, 0.4, 0.15, 1.0)
		intensity = 0.55 + 0.25 * alarm_pulse
	elif over:
		# Overclock: puncak cahaya, sedikit panas/putih
		aura_color = pcol.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.35).lerp(hot_col, 0.18)
		secondary_color = scol.lerp(hot_col, 0.25)
		intensity = 1.35 + 0.2 * sin(_pulse)
	else:
		# Idle -> panas: aura halus lalu makin terang
		var t := clampf((heat_r - 0.05) / 0.75, 0.0, 1.0)
		aura_color = pcol.lerp(hot_col, t * 0.45)
		secondary_color = scol.lerp(hot_col, t * 0.2)
		intensity = lerpf(0.32, 1.05, t)

func _draw() -> void:
	if not _active:
		return

	var t := _elapsed
	var fade := 1.0
	if duration_seconds > 0.0:
		var progress := clampf(_elapsed / duration_seconds, 0.0, 1.0)
		if progress < 0.15:
			fade = progress / 0.15
		elif progress > 0.7:
			fade = 1.0 - ((progress - 0.7) / 0.3)
		fade = clampf(fade, 0.0, 1.0)

	var breath := 0.5 + 0.5 * sin(_pulse)
	var r := base_radius * (0.92 + 0.12 * breath) * (0.85 + intensity * 0.15)
	var a := fade

	# 1. Pendaran lembut luar (outer soft glow bloom)
	var glow_r := r * (1.45 + 0.18 * breath)
	var glow_col := Color(aura_color.r, aura_color.g, aura_color.b, a * 0.12 * intensity)
	draw_circle(Vector2.ZERO, glow_r, glow_col)
	var glow_col2 := Color(aura_color.r, aura_color.g, aura_color.b, a * 0.07 * intensity)
	draw_circle(Vector2.ZERO, glow_r * 1.35, glow_col2)

	# 2. Cincin energi utama
	var ring_col := Color(aura_color.r, aura_color.g, aura_color.b, a * (0.35 + 0.2 * breath))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, ring_col, 2.0)
	draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 30, Color(secondary_color.r, secondary_color.g, secondary_color.b, a * 0.22), 1.2)

	# 3. Arc segmen berputar (energi aktif)
	var spin := t * (1.8 + intensity * 0.6)
	for i in range(3):
		var start_a := spin + float(i) * TAU / 3.0
		var sweep := 0.55 + 0.25 * sin(_pulse + float(i))
		var seg_col := Color(1.0, 1.0, 1.0, a * (0.25 + 0.25 * breath) * minf(1.0, intensity))
		draw_arc(Vector2.ZERO, r * 1.05, start_a, start_a + sweep, 10, seg_col, 2.5)
		draw_arc(Vector2.ZERO, r * 1.05, start_a, start_a + sweep, 10, Color(aura_color.r, aura_color.g, aura_color.b, a * 0.3), 3.5)

	# 4. Ground glow (elips di kaki)
	var ground_y := base_radius * 0.95
	var ground_w := r * 1.1
	var ground_h := r * 0.22
	var ground_col := Color(aura_color.r, aura_color.g, aura_color.b, a * 0.18 * (0.7 + 0.3 * breath))
	_draw_ellipse(Vector2(0.0, ground_y), ground_w, ground_h, ground_col)
	_draw_ellipse(Vector2(0.0, ground_y), ground_w * 0.55, ground_h * 0.55, Color(1.0, 1.0, 1.0, a * 0.1 * intensity))

	# 5. Partikel motes mengorbit (cahaya kecil)
	for m in _motes:
		var flicker := 0.5 + 0.5 * sin(m["phase"])
		var mdist: float = m["dist"] * (0.9 + 0.1 * breath)
		var mpos := Vector2(cos(m["angle"]), sin(m["angle"]) * 0.55) * mdist
		mpos.y += m["rise"] * 0.15
		var mcol := Color(aura_color.r, aura_color.g, aura_color.b, a * 0.55 * flicker)
		var mcore := Color(1.0, 1.0, 1.0, a * 0.7 * flicker)
		draw_circle(mpos, m["size"] * 1.6, Color(aura_color.r, aura_color.g, aura_color.b, a * 0.12 * flicker))
		draw_circle(mpos, m["size"], mcol)
		draw_circle(mpos, maxf(0.5, m["size"] * 0.4), mcore)

	# 6. Core shimmer halus di pusat atas
	var core_a := a * 0.1 * intensity * (0.6 + 0.4 * breath)
	draw_circle(Vector2(0.0, -2.0), r * 0.35, Color(aura_color.r, aura_color.g, aura_color.b, core_a))

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 20
	for i in range(segs):
		var ang := (TAU / float(segs)) * float(i)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, col)
