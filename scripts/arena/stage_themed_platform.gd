class_name StageThemedPlatform
extends StaticBody2D

## Platform Melayang Bertingkat (Elevated Themed Battle Platform)
## Memiliki CollisionShape2D dengan one_way_collision = true agar petarung dapat melompat dari bawah
## dan bertarung di atas platform, dengan visual dan dekorasi khas sesuai tema masing-masing dari 12 map.

@export var platform_size: Vector2 = Vector2(170.0, 14.0)
@export var stage_id: StringName = &"sakura_temple"
@export var is_left_side: bool = true

var collision_shape: CollisionShape2D
var _anim_time: float = 0.0

func _init(p_stage_id: StringName = &"sakura_temple", p_size: Vector2 = Vector2(170.0, 14.0), p_is_left: bool = true) -> void:
	stage_id = p_stage_id
	platform_size = p_size
	is_left_side = p_is_left

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	z_index = -5 # Berada di depan background, di belakang petarung/efek

	# Setup Collision Shape
	collision_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = platform_size
	collision_shape.shape = rect
	collision_shape.one_way_collision = true
	collision_shape.one_way_collision_margin = 6.0
	add_child(collision_shape)

func _process(delta: float) -> void:
	_anim_time += delta
	# Re-draw animasi halus untuk stage yang memiliki lampu/energi berdenyut
	if stage_id in [&"neon_city", &"space_station", &"hell_gate", &"rooftop"]:
		queue_redraw()

func _draw() -> void:
	var w: float = platform_size.x
	var h: float = platform_size.y
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var top_left := Vector2(-hw, -hh)
	var rect := Rect2(top_left, platform_size)

	match stage_id:
		&"sakura_temple":
			_draw_sakura_temple(rect, hw, hh)
		&"neon_city":
			_draw_neon_city(rect, hw, hh)
		&"ruin_factory":
			_draw_ruin_factory(rect, hw, hh)
		&"forest_shrine":
			_draw_forest_shrine(rect, hw, hh)
		&"rooftop":
			_draw_rooftop(rect, hw, hh)
		&"snow_field":
			_draw_snow_field(rect, hw, hh)
		&"canyon":
			_draw_canyon(rect, hw, hh)
		&"moon_castle":
			_draw_moon_castle(rect, hw, hh)
		&"ancient_ruins":
			_draw_ancient_ruins(rect, hw, hh)
		&"space_station":
			_draw_space_station(rect, hw, hh)
		&"traditional_town":
			_draw_traditional_town(rect, hw, hh)
		&"hell_gate":
			_draw_hell_gate(rect, hw, hh)
		_:
			_draw_default(rect, hw, hh)

# ------------------------------------------------------------- 1. SAKURA TEMPLE
func _draw_sakura_temple(r: Rect2, hw: float, hh: float) -> void:
	# Balok kayu merah kuil lacquer dengan ornamen ujung emas
	draw_rect(r, Color(0.68, 0.16, 0.18))
	draw_rect(Rect2(-hw, -hh, r.size.x, 3), Color(0.85, 0.28, 0.28)) # Highlight atas
	draw_rect(Rect2(-hw, hh - 3, r.size.x, 3), Color(0.38, 0.08, 0.1)) # Bayangan bawah
	# Ujung ornamen emas (Kuil Brass Caps)
	draw_rect(Rect2(-hw, -hh - 1, 12, r.size.y + 2), Color(0.95, 0.8, 0.25))
	draw_rect(Rect2(hw - 12, -hh - 1, 12, r.size.y + 2), Color(0.95, 0.8, 0.25))
	draw_rect(Rect2(-hw + 2, -hh, 8, r.size.y), Color(1.0, 0.92, 0.5))
	draw_rect(Rect2(hw - 10, -hh, 8, r.size.y), Color(1.0, 0.92, 0.5))
	# Tali shimenawa putih & tassel
	for x in [-hw * 0.5, 0.0, hw * 0.5]:
		draw_rect(Rect2(x - 3, hh, 6, 8), Color(0.95, 0.95, 0.95))
		draw_rect(Rect2(x - 1, hh + 8, 2, 4), Color(0.8, 0.2, 0.25))

# ------------------------------------------------------------- 2. NEON CITY
func _draw_neon_city(r: Rect2, hw: float, hh: float) -> void:
	var pulse := 0.75 + 0.25 * sin(_anim_time * 6.0)
	var glow_cyan := Color(0.0, 0.95, 1.0, 0.9 * pulse)
	var glow_pink := Color(1.0, 0.15, 0.65, 0.9)
	# Platform hardlight semi-transparan
	draw_rect(r, Color(0.05, 0.15, 0.25, 0.75))
	# Border neon menyala
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), glow_cyan)
	draw_rect(Rect2(-hw, hh - 2, r.size.x, 2), glow_pink)
	# Grid garis laser vertikal
	var steps := 8
	var step_w := r.size.x / float(steps)
	for i in range(steps + 1):
		var x := -hw + i * step_w
		draw_line(Vector2(x, -hh), Vector2(x, hh), Color(0.0, 0.8, 1.0, 0.35), 1.0)
	# Lampu aksen sudut neon
	draw_circle(Vector2(-hw + 4, 0), 3.0, glow_cyan)
	draw_circle(Vector2(hw - 4, 0), 3.0, glow_pink)

# ------------------------------------------------------------- 3. RUIN FACTORY
func _draw_ruin_factory(r: Rect2, hw: float, hh: float) -> void:
	# Balok girder baja berkarat
	draw_rect(r, Color(0.24, 0.22, 0.2))
	# Garis marka hazard kuning-hitam
	var stripe_w := 10.0
	var count := int(r.size.x / stripe_w)
	for i in range(count):
		if i % 2 == 0:
			draw_rect(Rect2(-hw + i * stripe_w, -hh, stripe_w, 3), Color(0.95, 0.75, 0.1))
	# Baut-baut baja industri
	for bx in [-hw + 8, -hw * 0.4, 0.0, hw * 0.4, hw - 8]:
		draw_circle(Vector2(bx, 1), 2.0, Color(0.55, 0.52, 0.48))
	# Rantai besi penggantung di kiri & kanan
	draw_line(Vector2(-hw + 14, -hh), Vector2(-hw + 14, -hh - 16), Color(0.4, 0.38, 0.35), 2.5)
	draw_line(Vector2(hw - 14, -hh), Vector2(hw - 14, -hh - 16), Color(0.4, 0.38, 0.35), 2.5)

# ------------------------------------------------------------- 4. FOREST SHRINE
func _draw_forest_shrine(r: Rect2, hw: float, hh: float) -> void:
	# Batang kayu keramat tua
	draw_rect(r, Color(0.32, 0.24, 0.18))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.46, 0.36, 0.26))
	# Lapisan lumut hijau alami di atas permukaan
	var moss_green := Color(0.35, 0.72, 0.28, 0.85)
	draw_rect(Rect2(-hw + 10, -hh - 1, 40, 3), moss_green)
	draw_rect(Rect2(-hw * 0.1, -hh - 1, 35, 3), moss_green)
	draw_rect(Rect2(hw - 45, -hh - 1, 35, 3), moss_green)
	# Sulur daun menjuntai ke bawah
	draw_circle(Vector2(-hw + 30, hh + 3), 3.0, Color(0.25, 0.58, 0.22))
	draw_circle(Vector2(hw - 30, hh + 4), 3.5, Color(0.25, 0.58, 0.22))

# ------------------------------------------------------------- 5. ROOFTOP
func _draw_rooftop(r: Rect2, hw: float, hh: float) -> void:
	# Plat lantai beton ventilasi atap gedung
	draw_rect(r, Color(0.25, 0.27, 0.32))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.5, 0.54, 0.6))
	draw_rect(Rect2(-hw, hh - 3, r.size.x, 3), Color(0.14, 0.16, 0.2))
	# Grating kisi-kisi AC / ventilasi
	for gx in range(int(-hw + 20), int(hw - 20), 12):
		draw_line(Vector2(gx, -hh + 3), Vector2(gx, hh - 3), Color(0.18, 0.2, 0.24), 2.0)
	# Lampu peringatan oranye atap gedung (kedip pelan)
	var blink := 0.6 + 0.4 * sin(_anim_time * 4.0)
	draw_circle(Vector2(-hw + 8, -hh - 4), 3.0, Color(1.0, 0.5, 0.1, blink))
	draw_circle(Vector2(hw - 8, -hh - 4), 3.0, Color(1.0, 0.5, 0.1, blink))

# ------------------------------------------------------------- 6. SNOW FIELD
func _draw_snow_field(r: Rect2, hw: float, hh: float) -> void:
	# Balok es glasier beku biru kristal
	draw_rect(r, Color(0.42, 0.68, 0.88, 0.85))
	draw_rect(Rect2(-hw, -hh + 2, r.size.x, 4), Color(0.7, 0.88, 1.0, 0.75))
	# Lapisan salju putih tebal di atas
	draw_rect(Rect2(-hw, -hh - 2, r.size.x, 4), Color(0.96, 0.98, 1.0))
	# Icicles (tetesan es runcing) di bawah platform
	for ix in [-hw + 20, -hw + 45, -10.0, 25.0, hw - 35]:
		var pts := PackedVector2Array([
			Vector2(ix - 3, hh),
			Vector2(ix + 3, hh),
			Vector2(ix, hh + 7 + int(abs(ix)) % 4)
		])
		draw_colored_polygon(pts, Color(0.75, 0.92, 1.0, 0.9))

# ------------------------------------------------------------- 7. CANYON
func _draw_canyon(r: Rect2, hw: float, hh: float) -> void:
	# Bebatuan tebing batu pasir merah bata gurun
	draw_rect(r, Color(0.72, 0.38, 0.24))
	draw_rect(Rect2(-hw, -hh, r.size.x, 3), Color(0.88, 0.52, 0.32)) # Sinar matahari atas
	draw_rect(Rect2(-hw, hh - 4, r.size.x, 4), Color(0.42, 0.2, 0.12)) # Bayangan tebing
	# Retakan geologis gurun horizontal
	draw_line(Vector2(-hw + 15, 0), Vector2(-hw * 0.2, 0), Color(0.45, 0.22, 0.14), 1.5)
	draw_line(Vector2(10, 1), Vector2(hw - 20, 1), Color(0.45, 0.22, 0.14), 1.5)

# ------------------------------------------------------------- 8. MOON CASTLE
func _draw_moon_castle(r: Rect2, hw: float, hh: float) -> void:
	# Balkon marmer batu kastil malam gotik
	draw_rect(r, Color(0.16, 0.18, 0.28))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.7, 0.8, 1.0, 0.9)) # Lis perak bulan
	draw_rect(Rect2(-hw, hh - 3, r.size.x, 3), Color(0.08, 0.1, 0.18))
	# Ornamen rune bulan biru berkilau
	var rune_blue := Color(0.4, 0.65, 1.0, 0.8)
	for rx in [-hw * 0.6, 0.0, hw * 0.6]:
		draw_arc(Vector2(rx, 0), 4.0, 0.0, TAU, 8, rune_blue, 1.5)
	# Penopang batu kastil di bawah
	draw_rect(Rect2(-hw + 10, hh, 10, 8), Color(0.12, 0.14, 0.22))
	draw_rect(Rect2(hw - 20, hh, 10, 8), Color(0.12, 0.14, 0.22))

# ------------------------------------------------------------- 9. ANCIENT RUINS
func _draw_ancient_ruins(r: Rect2, hw: float, hh: float) -> void:
	# Balok pilar marmer reruntuhan kuno
	draw_rect(r, Color(0.45, 0.5, 0.46))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.7, 0.76, 0.7))
	# Ukiran rune kuno mistis hijau toska
	draw_line(Vector2(-hw + 20, 0), Vector2(-hw + 60, 0), Color(0.2, 0.85, 0.6, 0.7), 1.5)
	draw_line(Vector2(hw - 60, 0), Vector2(hw - 20, 0), Color(0.2, 0.85, 0.6, 0.7), 1.5)
	# Sulur tanaman merambat kuno
	draw_circle(Vector2(-hw + 40, hh + 2), 2.5, Color(0.25, 0.6, 0.3))
	draw_circle(Vector2(hw - 35, hh + 3), 3.0, Color(0.25, 0.6, 0.3))

# ------------------------------------------------------------- 10. SPACE STATION
func _draw_space_station(r: Rect2, hw: float, hh: float) -> void:
	var pulse := 0.8 + 0.2 * sin(_anim_time * 8.0)
	var thruster_glow := Color(0.1, 0.85, 1.0, 0.95 * pulse)
	# Rangka titanium stasiun antariksa
	draw_rect(r, Color(0.14, 0.18, 0.24))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.3, 0.9, 1.0))
	draw_rect(Rect2(-hw + 10, 0, r.size.x - 20, 2), Color(0.2, 0.5, 0.8, 0.5))
	# Thruster anti-gravitasi di bagian bawah kiri & kanan
	for tx in [-hw + 25, hw - 25]:
		draw_rect(Rect2(tx - 12, hh, 24, 4), Color(0.25, 0.3, 0.4))
		draw_rect(Rect2(tx - 8, hh + 4, 16, 4), thruster_glow)

# ------------------------------------------------------------- 11. TRADITIONAL TOWN
func _draw_traditional_town(r: Rect2, hw: float, hh: float) -> void:
	# Papan kayu jembatan desa tradisional Jepang
	draw_rect(r, Color(0.52, 0.3, 0.16))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.72, 0.45, 0.24)) # Kayu hangat atas
	draw_rect(Rect2(-hw, hh - 3, r.size.x, 3), Color(0.28, 0.14, 0.08))
	# Balok penyangga kayu
	for bx in [-hw + 16, hw - 26]:
		draw_rect(Rect2(bx, hh, 10, 6), Color(0.35, 0.18, 0.1))
	# Lentera kertas merah kecil tergantung di ujung platform
	var lamp_x := -hw + 12 if is_left_side else hw - 12
	draw_circle(Vector2(lamp_x, hh + 6), 4.0, Color(0.9, 0.2, 0.18))
	draw_circle(Vector2(lamp_x, hh + 6), 2.0, Color(1.0, 0.85, 0.3))

# ------------------------------------------------------------- 12. HELL GATE
func _draw_hell_gate(r: Rect2, hw: float, hh: float) -> void:
	var heat := 0.7 + 0.3 * sin(_anim_time * 7.0)
	var lava_color := Color(1.0, 0.32, 0.08, heat)
	# Batu basal hitam vulkanik bergerigi
	draw_rect(r, Color(0.12, 0.08, 0.1))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.3, 0.15, 0.14))
	# Retakan lava membara di tengah platform
	draw_line(Vector2(-hw + 20, 0), Vector2(-15, 1), lava_color, 2.0)
	draw_line(Vector2(5, 1), Vector2(hw - 25, 0), lava_color, 2.0)
	# Tetesan lava pijar di bawah platform
	draw_circle(Vector2(-hw * 0.3, hh + 3), 2.5, lava_color)
	draw_circle(Vector2(hw * 0.3, hh + 2), 2.0, lava_color)

# ------------------------------------------------------------- DEFAULT
func _draw_default(r: Rect2, hw: float, hh: float) -> void:
	draw_rect(r, Color(0.2, 0.24, 0.3))
	draw_rect(Rect2(-hw, -hh, r.size.x, 2), Color(0.4, 0.5, 0.6))
