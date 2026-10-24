class_name VFXDramaticFinish
extends CanvasLayer

## Efek Sinematik Slow-Mo Dramatic Finish & K.O. Retro Arcade
## Menampilkan letterbox bar sinematik, kilatan flash layar penuh,
## bintang impak raksasa, dan banner tipografi "K.O.!" bergetar bertenaga.

var winner_player_id: int = 1
var finish_reason: StringName = &"ko"
var duration: float = 1.35
var _elapsed: float = 0.0
var _active: bool = false
var _shake_offset: Vector2 = Vector2.ZERO

var _bar_top: ColorRect = null
var _bar_bottom: ColorRect = null
var _flash_rect: ColorRect = null
var _center_control: Control = null
var _ko_label: Label = null
var _subtitle_label: Label = null

func _ready() -> void:
	layer = 120
	_build_ui()
	_start_finish_sequence()

func setup_finish(winner_id: int, reason: StringName = &"ko") -> void:
	winner_player_id = winner_id
	finish_reason = reason

func _build_ui() -> void:
	# Flash Screen Overlay
	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashOverlay"
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1.0, 0.95, 0.8, 0.9)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	# Letterbox Bar Atas
	_bar_top = ColorRect.new()
	_bar_top.name = "LetterboxTop"
	_bar_top.color = Color(0.04, 0.05, 0.08, 1.0)
	_bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_top.custom_minimum_size = Vector2(0, 0)
	_bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_top)

	# Letterbox Bar Bawah
	_bar_bottom = ColorRect.new()
	_bar_bottom.name = "LetterboxBottom"
	_bar_bottom.color = Color(0.04, 0.05, 0.08, 1.0)
	_bar_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_bottom.custom_minimum_size = Vector2(0, 0)
	_bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_bottom)

	# Container Tengah
	_center_control = Control.new()
	_center_control.name = "CenterDisplay"
	_center_control.set_anchors_preset(Control.PRESET_CENTER)
	_center_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center_control)

	# Label K.O. Utama
	_ko_label = Label.new()
	_ko_label.name = "KOLabel"
	_ko_label.text = "K. O. !" if finish_reason != &"double_ko" else "DOUBLE K.O.!"
	_ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ko_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ko_label.add_theme_font_size_override("font_size", 48)
	_ko_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	_ko_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.1, 0.1, 0.9))
	_ko_label.add_theme_constant_override("shadow_offset_x", 4)
	_ko_label.add_theme_constant_override("shadow_offset_y", 4)
	_ko_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05, 1.0))
	_ko_label.add_theme_constant_override("outline_size", 8)
	_ko_label.position = Vector2(-150, -40)
	_ko_label.size = Vector2(300, 60)
	_ko_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_control.add_child(_ko_label)

	# Label Subtitle
	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	var win_text := "PLAYER %d VICTORIOUS" % winner_player_id if winner_player_id > 0 else "DRAW MATCH"
	_subtitle_label.text = "— %s // CRITICAL ROUND SECURED —" % win_text
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0, 0.95))
	_subtitle_label.position = Vector2(-200, 24)
	_subtitle_label.size = Vector2(400, 24)
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_control.add_child(_subtitle_label)

func _start_finish_sequence() -> void:
	_active = true
	_elapsed = 0.0

	# 1. Animasi Flash Fade-Out
	var tw_flash := create_tween()
	tw_flash.tween_property(_flash_rect, "color:a", 0.0, 0.35)

	# 2. Letterbox Bars slide in
	var tw_bars := create_tween()
	tw_bars.set_parallel(true)
	tw_bars.tween_property(_bar_top, "size:y", 32.0, 0.25)
	tw_bars.tween_property(_bar_bottom, "size:y", 32.0, 0.25)
	tw_bars.tween_property(_bar_bottom, "position:y", 360.0 - 32.0, 0.25)

	# 3. K.O. Pop-in scale bounce
	_center_control.scale = Vector2(2.5, 2.5)
	var tw_scale := create_tween()
	tw_scale.tween_property(_center_control, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	# Getaran mikro pada teks K.O.
	if _elapsed < 0.6:
		var shake := (0.6 - _elapsed) * 8.0
		_ko_label.position = Vector2(-150 + randf_range(-shake, shake), -40 + randf_range(-shake, shake))

	if _elapsed >= duration:
		_active = false
		queue_free()
