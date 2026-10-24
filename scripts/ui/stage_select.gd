class_name StageSelect
extends Control

## Menu Stage Select (12 map). UI dibangun lewat kode agar mudah diubah/ditambah.
## Input: mouse / sentuh (klik kartu, tombol FIGHT/BACK), keyboard (panah/WASD, Enter/Space, Esc), gamepad (ui_*).
## FIGHT -> MatchConfig.set_stage(id) -> scene mode aktif (versus_ai / local_2p / training).
## BACK  -> character_select.tscn.

signal stage_changed(stage_id: StringName)
signal fight_requested(stage_id: StringName)
signal back_requested()
signal scene_change_requested(path: String)

const CHARACTER_SELECT_SCENE := "res://scenes/character_select.tscn"
const CARD_SIZE := Vector2(140.0, 78.0)
const COLOR_BG := Color(0.03, 0.035, 0.07, 1.0)
const COLOR_CARD := Color(0.07, 0.08, 0.14, 1.0)
const COLOR_DIM_BORDER := Color(0.22, 0.26, 0.4, 1.0)
const COLOR_CYAN := Color(0.2, 0.95, 1.0, 1.0)

## false = hanya emit sinyal, tidak pindah scene (dipakai tes otomatis)
var change_scene_enabled: bool = true
var selected_index: int = 0
var columns: int = 4
var is_transitioning: bool = false

var cards: Array[Panel] = []
var card_styles: Array[StyleBoxFlat] = []
var _card_tweens: Dictionary = {}
var _hover_index: int = -1
var _pulse_t: float = 0.0

var preview_rect: TextureRect
var preview_next: TextureRect
var grid: GridContainer
var name_label: Label
var tag_label: Label
var counter_label: Label
var fight_button: Button
var back_button: Button
var fade_rect: ColorRect
var _last_click_index: int = -1
var _last_click_msec: int = 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var start_idx := StageManager.index_of(MatchConfig.selected_stage)
	selected_index = maxi(start_idx, 0)
	_build_ui()
	get_viewport().size_changed.connect(_update_columns)
	_update_columns()
	_refresh_selection(false)
	_fade_in()

# ---------------------------------------------------------------- UI build

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BaseBackground"
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	preview_rect = _make_preview("PreviewBack")
	preview_next = _make_preview("PreviewFront")
	preview_next.modulate.a = 0.0

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.02, 0.02, 0.05, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 6)
	root_box.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root_box)

	# Header
	var header := HBoxContainer.new()
	root_box.add_child(header)
	var title := Label.new()
	title.name = "Title"
	title.text = "SELECT STAGE"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.6))
	title.add_theme_constant_override("outline_size", 4)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	counter_label = Label.new()
	counter_label.name = "Counter"
	counter_label.add_theme_font_size_override("font_size", 10)
	counter_label.add_theme_color_override("font_color", COLOR_CYAN)
	header.add_child(counter_label)

	# Grid
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root_box.add_child(center)
	grid = GridContainer.new()
	grid.name = "StageGrid"
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	center.add_child(grid)
	var stages := StageManager.get_stages()
	for i in range(stages.size()):
		_create_card(i, stages[i])

	# Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	root_box.add_child(footer)
	back_button = _make_button("BackButton", "BACK", Color(0.55, 0.6, 0.8))
	back_button.pressed.connect(_on_back_pressed)
	footer.add_child(back_button)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	footer.add_child(info)
	name_label = Label.new()
	name_label.name = "StageName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 4)
	info.add_child(name_label)
	tag_label = Label.new()
	tag_label.name = "StageTag"
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.add_theme_font_size_override("font_size", 9)
	tag_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	info.add_child(tag_label)

	fight_button = _make_button("FightButton", "FIGHT!", Color(1.0, 0.45, 0.25))
	fight_button.pressed.connect(_on_fight_pressed)
	footer.add_child(fight_button)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "ARROWS / WASD / TAP: Select    ENTER / SPACE: Fight    ESC: Back"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.8, 0.9))
	root_box.add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

func _make_preview(node_name: String) -> TextureRect:
	var r := TextureRect.new()
	r.name = node_name
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _make_button(node_name: String, text_value: String, accent: Color) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text_value
	b.custom_minimum_size = Vector2(110.0, 34.0)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	var states := {"normal": 0.0, "hover": 0.25, "pressed": -0.2}
	for key in states.keys():
		var sb := StyleBoxFlat.new()
		var base := accent.darkened(0.55)
		sb.bg_color = base.lightened(states[key]) if states[key] >= 0.0 else base.darkened(-states[key])
		sb.border_color = accent
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.35 if key == "hover" else 0.0)
		sb.shadow_size = 6
		b.add_theme_stylebox_override(key, sb)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	return b

func _create_card(index: int, info: Dictionary) -> void:
	var card := Panel.new()
	card.name = "Card_%s" % String(info["id"])
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD
	sb.border_color = COLOR_DIM_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.0)
	sb.shadow_size = 0
	card.add_theme_stylebox_override("panel", sb)

	var thumb := TextureRect.new()
	thumb.name = "Thumb"
	thumb.texture = StageManager.get_thumbnail_texture(info["id"])
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.offset_left = 3
	thumb.offset_top = 3
	thumb.offset_right = -3
	thumb.offset_bottom = -3
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(thumb)

	var strip := ColorRect.new()
	strip.name = "Strip"
	strip.color = Color(0, 0, 0, 0.68)
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_left = 3
	strip.offset_right = -3
	strip.offset_top = -17
	strip.offset_bottom = -3
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)

	var label := Label.new()
	label.name = "NameLabel"
	label.text = "%d. %s" % [index + 1, info["name"]]
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(label)

	card.gui_input.connect(_on_card_gui_input.bind(index))
	card.mouse_entered.connect(_on_card_hover.bind(index, true))
	card.mouse_exited.connect(_on_card_hover.bind(index, false))
	card.resized.connect(func(): card.pivot_offset = card.size * 0.5)
	grid.add_child(card)
	cards.append(card)
	card_styles.append(sb)

# ---------------------------------------------------------------- Layout

func _update_columns() -> void:
	if grid == null:
		return
	var w := get_viewport_rect().size.x
	var new_cols := 4
	if w < 560.0:
		new_cols = 3
	if w < 400.0:
		new_cols = 2
	columns = new_cols
	grid.columns = columns
	var avail := maxf(w - 40.0, 200.0)
	var cw := clampf((avail - float(columns - 1) * 8.0) / float(columns), 90.0, 200.0)
	var ch := cw * (CARD_SIZE.y / CARD_SIZE.x)
	for c in cards:
		c.custom_minimum_size = Vector2(cw, ch)

# ---------------------------------------------------------------- Selection

func get_selected_stage_id() -> StringName:
	return StageManager.get_stages()[selected_index]["id"]

func select_index(index: int, play_sound: bool = true) -> void:
	var count := StageManager.get_count()
	if count == 0:
		return
	index = ((index % count) + count) % count
	if index == selected_index:
		return
	selected_index = index
	if play_sound:
		MenuAudio.play_nav_beep(self)
	_refresh_selection(true)
	stage_changed.emit(get_selected_stage_id())

func move_selection(dx: int, dy: int) -> void:
	var count := StageManager.get_count()
	var row := selected_index / columns
	var col := selected_index % columns
	var rows := int(ceil(float(count) / float(columns)))
	if dx != 0:
		var new_col := (col + dx + columns) % columns
		var target := row * columns + new_col
		if target >= count:
			target = row * columns if dx > 0 else count - 1
		select_index(target)
	elif dy != 0:
		var new_row := (row + dy + rows) % rows
		var target2 := new_row * columns + col
		if target2 >= count:
			target2 = count - 1
		select_index(target2)

func _refresh_selection(animate: bool) -> void:
	var info := StageManager.get_stages()[selected_index]
	var accent: Color = info["accent"]
	for i in range(cards.size()):
		var is_sel := i == selected_index
		var sb := card_styles[i]
		sb.border_color = accent if is_sel else COLOR_DIM_BORDER
		sb.set_border_width_all(3 if is_sel else 2)
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.7) if is_sel else Color(0, 0, 0, 0)
		sb.shadow_size = 8 if is_sel else 0
		cards[i].z_index = 2 if is_sel else 0
		cards[i].modulate = Color(1, 1, 1, 1) if is_sel else Color(0.78, 0.78, 0.85, 1)
		_tween_card_scale(i)
	name_label.text = String(info["name"])
	name_label.add_theme_color_override("font_color", accent.lightened(0.35))
	tag_label.text = "// %s" % String(info["tag"])
	counter_label.text = "STAGE %02d / %02d" % [selected_index + 1, StageManager.get_count()]
	_set_preview(StageManager.get_background_texture(info["id"]), animate)

func _set_preview(tex: Texture2D, animate: bool) -> void:
	if not animate:
		preview_rect.texture = tex
		preview_next.modulate.a = 0.0
		return
	preview_next.texture = tex
	preview_next.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(preview_next, "modulate:a", 1.0, 0.22)
	tw.tween_callback(func():
		preview_rect.texture = tex
		preview_next.modulate.a = 0.0
	)

func _tween_card_scale(i: int) -> void:
	var target := 1.0
	if i == selected_index:
		target = 1.07
	elif i == _hover_index:
		target = 1.03
	if _card_tweens.has(i) and _card_tweens[i]:
		_card_tweens[i].kill()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cards[i], "scale", Vector2(target, target), 0.14)
	_card_tweens[i] = tw

func _process(delta: float) -> void:
	_pulse_t += delta
	if selected_index >= 0 and selected_index < card_styles.size():
		var accent: Color = StageManager.get_stages()[selected_index]["accent"]
		var a := 0.45 + 0.35 * (0.5 + 0.5 * sin(_pulse_t * 5.0))
		card_styles[selected_index].shadow_color = Color(accent.r, accent.g, accent.b, a)

# ---------------------------------------------------------------- Input

func _on_card_hover(index: int, entered: bool) -> void:
	if entered:
		_hover_index = index
	elif _hover_index == index:
		_hover_index = -1
	_tween_card_scale(index)

func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if is_transitioning:
		return
	var is_press := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = true
	elif event is InputEventScreenTouch and event.pressed:
		is_press = true
	if not is_press:
		return
	var now := Time.get_ticks_msec()
	var is_double := index == _last_click_index and now - _last_click_msec < 450
	_last_click_index = index
	_last_click_msec = now
	if index == selected_index:
		if is_double:
			_on_fight_pressed()
	else:
		select_index(index)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				move_selection(-1, 0)
			KEY_RIGHT, KEY_D:
				move_selection(1, 0)
			KEY_UP, KEY_W:
				move_selection(0, -1)
			KEY_DOWN, KEY_S:
				move_selection(0, 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_fight_pressed()
			KEY_ESCAPE, KEY_BACKSPACE:
				_on_back_pressed()
			_:
				return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		move_selection(-1, 0)
	elif event.is_action_pressed("ui_right"):
		move_selection(1, 0)
	elif event.is_action_pressed("ui_up"):
		move_selection(0, -1)
	elif event.is_action_pressed("ui_down"):
		move_selection(0, 1)
	elif event.is_action_pressed("ui_accept"):
		_on_fight_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ---------------------------------------------------------------- Actions

func _on_fight_pressed() -> void:
	if is_transitioning:
		return
	var id := get_selected_stage_id()
	if not MatchConfig.set_stage(id):
		return
	is_transitioning = true
	MenuAudio.play_confirm_chime(self)
	fight_requested.emit(id)
	if MatchConfig.game_mode == &"stage_select":
		MatchConfig.set_mode(&"versus_ai")
	_go_to(MatchConfig.get_target_scene())

func _on_back_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	MenuAudio.play_cancel_buzz(self)
	back_requested.emit()
	if MatchConfig.game_mode == &"stage_select":
		_go_to("res://scenes/main_menu.tscn")
	else:
		_go_to(CHARACTER_SELECT_SCENE)

func _go_to(path: String) -> void:
	scene_change_requested.emit(path)
	if not change_scene_enabled:
		return
	_fade_out_and_execute(func():
		if is_inside_tree():
			get_tree().change_scene_to_file(path)
	)

func _fade_in() -> void:
	if fade_rect == null:
		return
	fade_rect.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.3)

func _fade_out_and_execute(callable: Callable) -> void:
	if fade_rect == null:
		callable.call()
		return
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.25)
	tw.tween_callback(callable)
