class_name StageFloorVisual
extends Node2D

## Visualisasi Lantai Utama Arena Sesuai Tema Map
## Ditambahkan sebagai anak dari Platform utama ($Y=300$) untuk memberikan
## detail lantai, marka, garis batas tepi, dan aksen khas 12 stage tanpa mengganggu collision.

@export var stage_id: StringName = &"sakura_temple"
@export var floor_width: float = 1280.0
@export var floor_height: float = 24.0

var _anim_time: float = 0.0

func _init(p_stage_id: StringName = &"sakura_temple", p_width: float = 1280.0, p_height: float = 24.0) -> void:
	stage_id = p_stage_id
	floor_width = p_width
	floor_height = p_height

func _process(delta: float) -> void:
	_anim_time += delta
	if stage_id in [&"neon_city", &"space_station", &"hell_gate"]:
		queue_redraw()

func _draw() -> void:
	var hw: float = floor_width * 0.5
	var hh: float = floor_height * 0.5
	var rect := Rect2(-hw, -hh, floor_width, floor_height)

	match stage_id:
		&"sakura_temple":
			# Lantai batu candi hitam dengan lis kayu merah dan batas emas
			draw_rect(rect, Color(0.14, 0.15, 0.18, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 3), Color(0.72, 0.2, 0.22))
			draw_rect(Rect2(-hw, -hh + 3, floor_width, 1), Color(0.95, 0.82, 0.35))
			# Pembatas pilar ujung kiri & kanan
			draw_rect(Rect2(-hw, -hh, 20, floor_height), Color(0.85, 0.25, 0.25))
			draw_rect(Rect2(hw - 20, -hh, 20, floor_height), Color(0.85, 0.25, 0.25))
			# Sambungan balok tatami/batu tiap 160 px
			for x in range(int(-hw + 160), int(hw), 160):
				draw_line(Vector2(x, -hh), Vector2(x, hh), Color(0.25, 0.27, 0.32), 1.5)

		&"neon_city":
			# Aspal cyberpunk basah berkilau neon
			var pulse := 0.75 + 0.25 * sin(_anim_time * 6.0)
			draw_rect(rect, Color(0.08, 0.09, 0.14, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.0, 0.9, 1.0, 0.9 * pulse))
			# Garis marka tengah neon cyan & ungu
			draw_rect(Rect2(-hw, -hh + 4, floor_width, 1), Color(0.8, 0.1, 0.9, 0.6))
			# Curb neon kiri & kanan
			draw_rect(Rect2(-hw, -hh, 24, floor_height), Color(0.0, 0.95, 1.0, 0.9))
			draw_rect(Rect2(hw - 24, -hh, 24, floor_height), Color(1.0, 0.15, 0.75, 0.9))

		&"ruin_factory":
			# Plat baja industri berkarat dengan pola marka hazard kuning-hitam
			draw_rect(rect, Color(0.18, 0.16, 0.15, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.35, 0.32, 0.28))
			# Garis batas marka bahaya di ujung kiri dan kanan
			var hw_zone := 80.0
			for x in range(int(-hw), int(-hw + hw_zone), 12):
				draw_rect(Rect2(x, -hh, 6, floor_height), Color(0.95, 0.75, 0.1))
			for x in range(int(hw - hw_zone), int(hw), 12):
				draw_rect(Rect2(x, -hh, 6, floor_height), Color(0.95, 0.75, 0.1))

		&"forest_shrine":
			# Bebatuan candi hutan berlumut hijau
			draw_rect(rect, Color(0.18, 0.22, 0.18, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.35, 0.68, 0.3))
			# Undakan batu batas kuil di tepi
			draw_rect(Rect2(-hw, -hh, 22, floor_height), Color(0.28, 0.38, 0.25))
			draw_rect(Rect2(hw - 22, -hh, 22, floor_height), Color(0.28, 0.38, 0.25))

		&"rooftop":
			# Beton atap gedung helipad dengan strip kuning senja
			draw_rect(rect, Color(0.16, 0.18, 0.22, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.4, 0.45, 0.52))
			draw_rect(Rect2(-hw, -hh + 2, floor_width, 2), Color(0.95, 0.6, 0.15, 0.7))
			# Garis pembatas helipad kiri dan kanan
			draw_rect(Rect2(-hw, -hh, 18, floor_height), Color(0.95, 0.6, 0.15))
			draw_rect(Rect2(hw - 18, -hh, 18, floor_height), Color(0.95, 0.6, 0.15))

		&"snow_field":
			# Lapisan es permafrost biru dengan selimut salju putih
			draw_rect(rect, Color(0.32, 0.55, 0.75, 0.92))
			draw_rect(Rect2(-hw, -hh, floor_width, 4), Color(0.95, 0.98, 1.0))
			draw_rect(Rect2(-hw, -hh + 4, floor_width, 2), Color(0.65, 0.85, 1.0, 0.7))
			# Gundukan salju tebal di ujung
			draw_rect(Rect2(-hw, -hh - 2, 28, floor_height + 2), Color(0.9, 0.95, 1.0))
			draw_rect(Rect2(hw - 28, -hh - 2, 28, floor_height + 2), Color(0.9, 0.95, 1.0))

		&"canyon":
			# Bebatuan pasir merah ngarai gurun
			draw_rect(rect, Color(0.48, 0.25, 0.16, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 3), Color(0.78, 0.45, 0.28))
			draw_rect(Rect2(-hw, -hh, 24, floor_height), Color(0.6, 0.3, 0.18))
			draw_rect(Rect2(hw - 24, -hh, 24, floor_height), Color(0.6, 0.3, 0.18))

		&"moon_castle":
			# Marmer hitam istana malam dengan lis perak berkilau
			draw_rect(rect, Color(0.1, 0.12, 0.2, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.65, 0.78, 1.0))
			draw_rect(Rect2(-hw, -hh, 20, floor_height), Color(0.2, 0.26, 0.42))
			draw_rect(Rect2(hw - 20, -hh, 20, floor_height), Color(0.2, 0.26, 0.42))

		&"ancient_ruins":
			# Balok batu reruntuhan kuno dengan ukiran rune hijau lumut
			draw_rect(rect, Color(0.22, 0.26, 0.24, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.35, 0.75, 0.55, 0.8))
			draw_rect(Rect2(-hw, -hh, 24, floor_height), Color(0.3, 0.38, 0.32))
			draw_rect(Rect2(hw - 24, -hh, 24, floor_height), Color(0.3, 0.38, 0.32))

		&"space_station":
			# Dek stasiun antariksa titanium dengan jalur sirkuit biru
			var pulse_space := 0.8 + 0.2 * sin(_anim_time * 5.0)
			draw_rect(rect, Color(0.1, 0.14, 0.2, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.0, 0.8, 1.0, pulse_space))
			draw_rect(Rect2(-hw, -hh, 26, floor_height), Color(0.18, 0.28, 0.42))
			draw_rect(Rect2(hw - 26, -hh, 26, floor_height), Color(0.18, 0.28, 0.42))

		&"traditional_town":
			# Paving batu jalanan perkampungan dengan trim balok kayu cokelat
			draw_rect(rect, Color(0.25, 0.22, 0.2, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 3), Color(0.62, 0.38, 0.22))
			draw_rect(Rect2(-hw, -hh, 20, floor_height), Color(0.48, 0.28, 0.15))
			draw_rect(Rect2(hw - 20, -hh, 20, floor_height), Color(0.48, 0.28, 0.15))

		&"hell_gate":
			# Kerak batu obsidian hitam pekat dengan lelehan lahar pijar
			var lava_glow := 0.7 + 0.3 * sin(_anim_time * 7.0)
			draw_rect(rect, Color(0.1, 0.06, 0.08, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 3), Color(1.0, 0.32, 0.05, lava_glow))
			draw_rect(Rect2(-hw, -hh, 24, floor_height), Color(0.7, 0.18, 0.08))
			draw_rect(Rect2(hw - 24, -hh, 24, floor_height), Color(0.7, 0.18, 0.08))

		_:
			draw_rect(rect, Color(0.16, 0.2, 0.26, 0.95))
			draw_rect(Rect2(-hw, -hh, floor_width, 2), Color(0.4, 0.5, 0.6))
