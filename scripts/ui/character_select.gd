class_name CharacterSelect
extends Control

## Character Select Screen & Roster Selector (Story 11.1)
## Antarmuka pemilihan mecha arcade 32-bit retro cyberpunk
## Mendukung rotasi 3 petarung (Viper, Bulwark, Pulsar), inspeksi statistik,
## live pixel sprite preview, konfirmasi duel, dan transisi mulus ke arena.

const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const VfxProfileScript = preload("res://resources/vfx_profile.gd")
const VFXAuraBurstScript = preload("res://scripts/visual/vfx_aura_burst.gd")
const VFXShockwaveScript = preload("res://scripts/visual/vfx_shockwave.gd")
const VFXCharacterAuraScript = preload("res://scripts/visual/vfx_character_aura.gd")
const VFXLightningArcScript = preload("res://scripts/visual/vfx_lightning.gd")
const VFXSupernovaScript = preload("res://scripts/visual/vfx_supernova.gd")
const VFXCinematicSlashScript = preload("res://scripts/visual/vfx_cinematic_slash.gd")
const VFXCryoFreezeScript = preload("res://scripts/visual/vfx_cryo_freeze.gd")
const VFXOrbitalBeamScript = preload("res://scripts/visual/vfx_orbital_beam.gd")
const VFXSeismicImpactScript = preload("res://scripts/visual/vfx_seismic_impact.gd")
const STAGE_SELECT_SCENE := "res://scenes/menus/stage_select.tscn"

signal p1_selection_changed(index: int, char_id: StringName)
signal p2_selection_changed(index: int, char_id: StringName)
signal selection_confirmed(p1_char_id: StringName, p2_char_id: StringName)
signal cancelled()

var p1_index: int = 0
var p2_index: int = 1
var p1_locked: bool = false
var p2_locked: bool = false
var is_transitioning: bool = false

@onready var title_label: Label = $TopBar/TitleLabel
@onready var mode_label: Label = $TopBar/ModeLabel
@onready var stage_label: Label = $TopBar/StageLabel

# Roster Cards Container
@onready var cards_container: GridContainer = $RosterArea/CardsContainer

const ROSTER_GRID_COLUMNS: int = 7

# Preview & Details Area
@onready var p1_preview_mount: Control = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/SpriteMount
@onready var p1_name_label: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/NameLabel
@onready var p1_archetype_label: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/ArchetypeLabel
@onready var p1_ready_badge: Label = $DetailsArea/P1Panel/Margin/VBox/HBoxTop/InfoVBox/ReadyBadge
@onready var p1_stats_label: Label = $DetailsArea/P1Panel/Margin/VBox/StatsLabel
@onready var p1_moves_label: Label = $DetailsArea/P1Panel/Margin/VBox/MovesLabel

@onready var p2_preview_mount: Control = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/SpriteMount
@onready var p2_name_label: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/NameLabel
@onready var p2_archetype_label: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/ArchetypeLabel
@onready var p2_ready_badge: Label = $DetailsArea/P2Panel/Margin/VBox/HBoxTop/InfoVBox/ReadyBadge
@onready var p2_stats_label: Label = $DetailsArea/P2Panel/Margin/VBox/StatsLabel
@onready var p2_moves_label: Label = $DetailsArea/P2Panel/Margin/VBox/MovesLabel

@onready var prompt_label: Label = $BottomBar/PromptLabel
@onready var fade_rect: ColorRect = $FadeOverlay

var _p1_sprite: Node2D = null
var _p2_sprite: Node2D = null
var _card_nodes: Array[PanelContainer] = []
var _scroll_tween: Tween = null
var _vfx_preview_root: Node2D = null
var _p1_showcase_aura: Node2D = null
var _p2_showcase_aura: Node2D = null

const PROFILE_PATHS := {
	&"viper": "res://resources/vfx_profiles/viper.tres",
	&"bulwark": "res://resources/vfx_profiles/bulwark.tres",
	&"pulsar": "res://resources/vfx_profiles/pulsar.tres",
	&"kage": "res://resources/vfx_profiles/kage.tres",
	&"trigger": "res://resources/vfx_profiles/trigger.tres",
	&"death_kam": "res://resources/vfx_profiles/death_kam.tres",
	&"unit_zero": "res://resources/vfx_profiles/unit_zero.tres",
	&"miku": "res://resources/vfx_profiles/miku.tres",
	&"reimu": "res://resources/vfx_profiles/reimu.tres",
	&"marisa": "res://resources/vfx_profiles/marisa.tres",
	&"remilia": "res://resources/vfx_profiles/remilia.tres",
	&"sasuke": "res://resources/vfx_profiles/sasuke.tres",
	&"yorha_2b": "res://resources/vfx_profiles/yorha_2b.tres",
	&"2b": "res://resources/vfx_profiles/yorha_2b.tres",
}

const COUNTERPLAY_TIPS := {
	&"miku": "Jaga jarak mid; anti-air vs note dive, hukumi recovery Sonic Pulse.",
	&"reimu": "Tekan setelah ofuda/teleport; hindari sudut Fantasy Seal.",
	&"marisa": "Sidestep/jump read Hakkero beam; tutup jarak di celah charge.",
	&"remilia": "Jaga spacing anti-dash claw; blokir lalu punish chain Gungnir.",
	&"sasuke": "Sabar lawan teleport; block Chidori, serang saat stance/whiff.",
	&"yorha_2b": "Jangan diam di zoning pod; dekati saat celah Blade Cyclone.",
	&"2b": "Jangan diam di zoning pod; dekati saat celah Blade Cyclone.",
	&"death_kam": "Jaga jarak dari chain pull; bait Rage, punish di recovery.",
	&"viper": "Hormati Blink/cryofreeze; anti-armor setup, punish whiff dash.",
	&"bulwark": "Hindari grab/piledriver; serang dari jarak, bait Riot Shield.",
	&"pulsar": "Jangan lurus lawan railgun; tutup jarak dan pressure drone setup.",
	&"kage": "Baca stance/teleport; tahan block mixup, punish rekanya.",
	&"trigger": "Waspadai parry/ricochet; variasikan timing serangan.",
	&"unit_zero": "Main sabar, punish celah besar; kelola space vs super armor/beam.",
}

func _ready() -> void:
	_setup_audio()
	_setup_vfx_preview_root()
	if title_label:
		title_label.text = "PROJECT RETRO ZERO - 2D FIGHTING GAME"
	if mode_label:
		mode_label.text = "CHARACTER SELECT  >>>  CHOOSE YOUR FIGHTER"
	_build_roster_cards()
	_update_p1_display()
	_update_p2_display()
	_update_stage_ui()
	if MatchConfigScript.game_mode == &"arcade" and mode_label:
		mode_label.text = "MODE: ARCADE GAUNTLET (4-STAGE)"
	call_deferred("_scroll_to_index", p1_index, false)
	_update_prompt()
	_fade_in()

func _setup_vfx_preview_root() -> void:
	if is_instance_valid(_vfx_preview_root):
		return
	_vfx_preview_root = Node2D.new()
	_vfx_preview_root.name = "VFXPreviewRoot"
	_vfx_preview_root.z_index = 20
	add_child(_vfx_preview_root)

func _setup_audio() -> void:
	if AudioManagerScript.instance != null:
		AudioManagerScript.instance.play_bgm(&"title")

func _format_stat_bar(stat_name: String, val: int, max_val: int = 10) -> String:
	var filled := clampi(val, 0, max_val)
	var bar := ""
	for k in range(filled):
		bar += "■"
	for k in range(max_val - filled):
		bar += "░"
	return "%-3s  [%s]" % [stat_name, bar]

func _build_roster_cards() -> void:
	_card_nodes.clear()
	for child in cards_container.get_children():
		child.queue_free()

	var total := FighterFactoryScript.get_roster_count()
	var cols := ROSTER_GRID_COLUMNS
	if cards_container:
		cards_container.columns = cols

	for i in range(total):
		var char_data = FighterFactoryScript.get_character_at(i)
		var card := PanelContainer.new()
		# Ukuran kompak agar 7 kolom x 2 baris muat rapi di 640px.
		card.custom_minimum_size = Vector2(82, 64)
		card.name = "Card_" + String(char_data["id"])
		card.mouse_filter = Control.MOUSE_FILTER_STOP

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 1)

		# Mini Portrait Preview Mount
		var port_mount := Control.new()
		port_mount.custom_minimum_size = Vector2(28, 26)
		port_mount.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var mini_spr := MechaPixelSpriteScript.new()
		mini_spr.archetype = char_data["id"]
		mini_spr.set_palette_index(0)
		mini_spr.position = Vector2(14, 20)
		mini_spr.scale = Vector2(0.9, 0.9)
		port_mount.add_child(mini_spr)
		vbox.add_child(port_mount)

		var lbl_name := Label.new()
		lbl_name.name = "LabelName"
		lbl_name.text = char_data["name"]
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_name.add_theme_color_override("font_color", char_data["theme_color"])
		lbl_name.add_theme_font_size_override("font_size", 8)
		lbl_name.clip_text = true
		lbl_name.custom_minimum_size.x = 78

		var lbl_arch := Label.new()
		lbl_arch.name = "LabelArch"
		lbl_arch.text = char_data["archetype"]
		lbl_arch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_arch.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90, 0.75))
		lbl_arch.add_theme_font_size_override("font_size", 6)
		lbl_arch.clip_text = true
		lbl_arch.custom_minimum_size.x = 78

		vbox.add_child(lbl_name)
		vbox.add_child(lbl_arch)
		card.add_child(vbox)

		# Click selection
		var card_idx = i
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if not p1_locked:
					p1_index = card_idx
					MenuAudio.play_nav_beep(self)
					_update_p1_display()
					_scroll_to_index(p1_index, true)
		)

		cards_container.add_child(card)
		_card_nodes.append(card)

	_highlight_cards()

func _highlight_cards() -> void:
	for i in range(_card_nodes.size()):
		var card = _card_nodes[i]
		var is_p1 := (i == p1_index)
		var is_p2 := (i == p2_index and MatchConfigScript.game_mode == &"local_2p")

		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(4)
		# Border/content margin KONSTAN agar ukuran kartu tidak berubah saat seleksi
		# (mencegah HBox/roster "ikut tergeser" karena reflow layout).
		sb.set_border_width_all(2)
		sb.set_content_margin_all(4)
		sb.bg_color = Color(0.06, 0.07, 0.11, 0.92)

		if is_p1 and is_p2:
			sb.border_color = Color(1.0, 0.88, 0.25, 1.0)
			card.modulate = Color(1.3, 1.3, 1.1, 1.0)
		elif is_p1:
			sb.border_color = Color(0.0, 0.95, 1.0, 1.0)
			card.modulate = Color(1.2, 1.25, 1.3, 1.0)
		elif is_p2:
			sb.border_color = Color(1.0, 0.25, 0.35, 1.0)
			card.modulate = Color(1.3, 1.15, 1.15, 1.0)
		else:
			sb.border_color = Color(0.22, 0.25, 0.35, 0.35)
			card.modulate = Color(0.7, 0.72, 0.8, 0.75)

		card.add_theme_stylebox_override("panel", sb)

func _update_p1_display() -> void:
	var char_data = FighterFactoryScript.get_character_at(p1_index)
	var pal_name = MatchConfigScript.PALETTE_NAMES[MatchConfigScript.p1_palette]
	p1_name_label.text = "%s  [C: %s]" % [char_data["name"], pal_name]
	p1_name_label.add_theme_color_override("font_color", char_data["theme_color"])
	p1_archetype_label.text = "%s  |  \"%s\"" % [char_data["archetype"], char_data.get("quote", "Let's fight!")]
	
	p1_stats_label.text = "STATS\n%s    %s\n%s    %s" % [
		_format_stat_bar("HP", char_data.get("hp_bar", 5)),
		_format_stat_bar("DEF", char_data.get("def_bar", 5)),
		_format_stat_bar("SPD", char_data.get("spd_bar", 5)),
		_format_stat_bar("RNG", char_data.get("rng_bar", 5))
	]
	var counter = _get_counterplay_tip(char_data["id"])
	var moves: Array = char_data.get("signature_moves", [])
	p1_moves_label.text = "TIP: %s\nMOVES:\n- %s" % [counter, "\n- ".join(moves)] if moves.size() > 0 else "TIP: %s" % counter

	if p1_ready_badge:
		p1_ready_badge.visible = p1_locked
		p1_ready_badge.text = "[ READY ]" if p1_locked else ""

	# Live Pixel Sprite Preview (idle/pose showcase)
	if is_instance_valid(_p1_sprite):
		_p1_sprite.queue_free()
	var spr := MechaPixelSpriteScript.new()
	spr.name = "P1Sprite"
	spr.archetype = char_data["id"]
	spr.set_palette_index(MatchConfigScript.p1_palette)
	spr.position = Vector2(40, 50)
	spr.scale = Vector2(2.8, 2.8)
	if spr.has_method("set_current_state"):
		spr.set_current_state(&"Idle")
	p1_preview_mount.add_child(spr)
	_p1_sprite = spr
	_play_showcase_preview(1, char_data["id"], spr)

	_highlight_cards()
	_update_prompt()
	p1_selection_changed.emit(p1_index, char_data["id"])

func _update_p2_display() -> void:
	if MatchConfigScript.game_mode == &"arcade":
		p2_name_label.text = "ARCADE RIVALS & BOSS"
		p2_name_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.35, 1.0))
		p2_archetype_label.text = "4-Stage Gauntlet | Zero Circuit"
		p2_stats_label.text = "HP   [■■■■■■■■□□]    DEF  [■■■■■■■□□□]\nSPD  [■■■■■■■■□□]    RNG  [■■■■■■■□□□]"
		p2_moves_label.text = "INFO: Hadapi rival bertahap, simpan resource untuk Boss.\nStage 1-3: Rivals | Stage 4: Boss Unit-0"
		if p2_ready_badge:
			p2_ready_badge.visible = true
			p2_ready_badge.text = "[ READY ]"
		_update_prompt()
		return

	var char_data = FighterFactoryScript.get_character_at(p2_index)
	var pal_name = MatchConfigScript.PALETTE_NAMES[MatchConfigScript.p2_palette]
	p2_name_label.text = "%s  [V: %s]" % [char_data["name"], pal_name]
	p2_name_label.add_theme_color_override("font_color", char_data["theme_color"])
	p2_archetype_label.text = "%s  |  \"%s\"" % [char_data["archetype"], char_data.get("quote", "This is a divine will.")]
	
	p2_stats_label.text = "STATS\n%s    %s\n%s    %s" % [
		_format_stat_bar("HP", char_data.get("hp_bar", 5)),
		_format_stat_bar("DEF", char_data.get("def_bar", 5)),
		_format_stat_bar("SPD", char_data.get("spd_bar", 5)),
		_format_stat_bar("RNG", char_data.get("rng_bar", 5))
	]
	var counter = _get_counterplay_tip(char_data["id"])
	var moves: Array = char_data.get("signature_moves", [])
	p2_moves_label.text = "TIP: %s\nMOVES:\n- %s" % [counter, "\n- ".join(moves)] if moves.size() > 0 else "TIP: %s" % counter

	if p2_ready_badge:
		p2_ready_badge.visible = p2_locked
		p2_ready_badge.text = "[ READY ]" if p2_locked else ""

	if is_instance_valid(_p2_sprite):
		_p2_sprite.queue_free()
	var spr := MechaPixelSpriteScript.new()
	spr.name = "P2Sprite"
	spr.archetype = char_data["id"]
	spr.set_palette_index(MatchConfigScript.p2_palette)
	spr.position = Vector2(40, 50)
	spr.scale = Vector2(-2.8, 2.8) # Hadap kiri
	if spr.has_method("set_current_state"):
		spr.set_current_state(&"Idle")
	p2_preview_mount.add_child(spr)
	_p2_sprite = spr
	_play_showcase_preview(2, char_data["id"], spr)

	_highlight_cards()
	_update_prompt()
	p2_selection_changed.emit(p2_index, char_data["id"])

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	# P1 Navigasi: grid 2 baris (A/D/←/→ kiri-kanan, W/S/↑/↓ atas-bawah)
	if not p1_locked:
		var cols := _get_grid_columns()
		if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
			_change_p1_index(-1)
		elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
			_change_p1_index(1)
		elif event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
			_change_p1_index(-cols)
		elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
			_change_p1_index(cols)

	# P2 Navigasi (Untuk mode Local 2P / AI pick): J / L atau Up/Down
	if not p2_locked and MatchConfigScript.game_mode == &"local_2p":
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_J or event.keycode == KEY_LEFT:
				_change_p2_index(-1)
			elif event.keycode == KEY_L or event.keycode == KEY_RIGHT:
				_change_p2_index(1)

	# Ganti Palette P1: C
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		MatchConfigScript.cycle_p1_palette()
		MenuAudio.play_nav_beep(self)
		_update_p1_display()

	# Ganti Palette P2: V
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		MatchConfigScript.cycle_p2_palette()
		MenuAudio.play_nav_beep(self)
		_update_p2_display()

	# Buka Menu Map Selector (12 Maps): M
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_open_stage_selector()

	# Ganti Arena / Map: Tab / T
	if event is InputEventKey and event.pressed and (event.keycode == KEY_TAB or event.keycode == KEY_T):
		toggle_stage()

	# Konfirmasi: Space / Enter
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_confirm_selection()

	# Batal / Kembali: Esc
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_cancel_or_return()

func _open_stage_selector() -> void:
	is_transitioning = true
	MenuAudio.play_confirm_chime(self)
	_fade_out_and_execute(func():
		get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
	)

func toggle_stage() -> void:
	MatchConfigScript.cycle_next_arena()
	MenuAudio.play_nav_beep(self)
	_update_stage_ui()

func _update_stage_ui() -> void:
	if not stage_label:
		return
	if not stage_label.gui_input.is_connected(_on_stage_label_input):
		stage_label.mouse_filter = Control.MOUSE_FILTER_STOP
		stage_label.gui_input.connect(_on_stage_label_input)

	if MatchConfigScript.selected_arena == &"stage":
		var cur_id = MatchConfigScript.selected_stage
		var stage_data = StageManager.get_stage(cur_id)
		var s_idx = StageManager.index_of(cur_id) + 1
		stage_label.text = "[M / CLICK] MAP: %s (%d/12 - %s) | [TAB] NEXT" % [
			stage_data.get("name", "STAGE"),
			s_idx,
			stage_data.get("tag", "MAP")
		]
		stage_label.modulate = stage_data.get("accent", Color(0.2, 0.95, 1.0))
	else:
		match MatchConfigScript.selected_arena:
			&"reactor":
				stage_label.text = "[TAB] ARENA: UNDERGROUND REACTOR | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(1.0, 0.45, 0.1, 1.0)
			&"orbital":
				stage_label.text = "[TAB] ARENA: ORBITAL SPACE STATION | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(0.3, 0.9, 1.0, 1.0)
			&"highway":
				stage_label.text = "[TAB] ARENA: CYBER HIGHWAY | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(1.0, 0.2, 0.6, 1.0)
			_:
				stage_label.text = "[TAB] ARENA: ZERO-G SKYSCRAPER | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(0.2, 0.9, 1.0, 1.0)
	_update_prompt()

func _update_prompt() -> void:
	if not prompt_label or is_transitioning:
		return
	var mode_txt: String = String(MatchConfigScript.game_mode).to_upper()
	var controls: String = "←→/A D: Pilih  |  Enter/Space: Konfirmasi  |  C/V: Palette  |  M/Tab: Stage/Map  |  Esc: Kembali"
	if MatchConfigScript.game_mode == &"local_2p":
		controls = "P1: ←→ Pilih, Enter OK, C Palette  |  P2: A/D Pilih, Spasi OK, V Palette  |  M/Tab: Stage  |  Esc: Kembali"
	prompt_label.text = "MODE: %s\n%s" % [mode_txt, controls]
	prompt_label.modulate = Color(0.85, 0.95, 1.0, 0.95)
				stage_label.text = "[TAB] ARENA: NEO-SHIBUYA HIGHWAY | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(1.0, 0.25, 0.65, 1.0)
			_:
				stage_label.text = "[TAB] ARENA: ZERO-G SKYSCRAPER | [M] BROWSE 12 MAPS"
				stage_label.modulate = Color(0.2, 0.9, 1.0, 1.0)

func _on_stage_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_stage_selector()

func _get_grid_columns() -> int:
	if cards_container and cards_container.columns > 0:
		return cards_container.columns
	return ROSTER_GRID_COLUMNS

func _change_p1_index(delta: int) -> void:
	var total = FighterFactoryScript.get_roster_count()
	if total <= 0:
		return
	p1_index = posmod(p1_index + delta, total)
	MenuAudio.play_nav_beep(self)
	_update_p1_display()
	_scroll_to_index(p1_index, true)

func _change_p2_index(delta: int) -> void:
	var total = FighterFactoryScript.get_roster_count()
	if total <= 0:
		return
	p2_index = posmod(p2_index + delta, total)
	MenuAudio.play_nav_beep(self)
	_update_p2_display()
	if MatchConfigScript.game_mode == &"local_2p":
		_scroll_to_index(p2_index, true)

func _confirm_selection() -> void:
	if not p1_locked:
		p1_locked = true
		MenuAudio.play_confirm_chime(self)
		_update_p1_display()
		if MatchConfigScript.game_mode == &"versus_ai" or MatchConfigScript.game_mode == &"arcade":
			p2_locked = true
			_update_p2_display()

	if MatchConfigScript.game_mode == &"local_2p" and not p2_locked:
		p2_locked = true
		MenuAudio.play_confirm_chime(self)
		_update_p2_display()

	if p1_locked and p2_locked:
		_launch_match()

func _cancel_or_return() -> void:
	if p1_locked or p2_locked:
		p1_locked = false
		p2_locked = false
		MenuAudio.play_nav_beep(self)
		_update_p1_display()
		_update_p2_display()
	else:
		cancelled.emit()
		_fade_out_and_execute(func():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)

func _launch_match() -> void:
	is_transitioning = true
	var p1_id = FighterFactoryScript.get_character_at(p1_index)["id"]
	var p2_id = FighterFactoryScript.get_character_at(p2_index)["id"]
	MatchConfigScript.set_p1(p1_id)
	MatchConfigScript.set_p2(p2_id)
	selection_confirmed.emit(p1_id, p2_id)

	prompt_label.text = "LAUNCHING ARCADE..." if MatchConfigScript.game_mode == &"arcade" else "LAUNCHING ARENA..."
	prompt_label.modulate = Color(0.2, 0.95, 1.0, 1.0)

	_fade_out_and_execute(func():
		var target_scene = MatchConfigScript.get_target_scene()
		if MatchConfigScript.game_mode != &"arcade":
			target_scene = STAGE_SELECT_SCENE
		get_tree().change_scene_to_file(target_scene)
	)

func _fade_in() -> void:
	if not fade_rect:
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.3)
	tw.tween_callback(func(): fade_rect.visible = false)

func _get_counterplay_tip(char_id: StringName) -> String:
	if COUNTERPLAY_TIPS.has(char_id):
		return COUNTERPLAY_TIPS[char_id]
	return "Amati pola serangan, kelola jarak, dan punish recovery."

func _load_profile_for_char(char_id: StringName) -> VfxProfile:
	var path: String = PROFILE_PATHS.get(char_id, "")
	if path != "" and ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is VfxProfile:
			return res
	return VfxProfileScript.create_generic()

func _preview_world_pos(sprite: Node2D) -> Vector2:
	if not is_instance_valid(sprite):
		return Vector2.ZERO
	var mount = sprite.get_parent()
	if mount is Control:
		return mount.get_global_rect().get_center() + Vector2(0, 6)
	return sprite.global_position

func _play_showcase_preview(player_idx: int, char_id: StringName, sprite: Node2D) -> void:
	if not is_instance_valid(_vfx_preview_root) or not is_instance_valid(sprite):
		return
	var profile := _load_profile_for_char(char_id)
	var pos := _preview_world_pos(sprite)
	# Pose singkat: kedipan state agar terasa "showcase" (idle tetap berjalan)
	if sprite.has_method("set_current_state"):
		sprite.set_current_state(&"Walk")
		var t := create_tween()
		t.tween_interval(0.18)
		t.tween_callback(func():
			if is_instance_valid(sprite) and sprite.has_method("set_current_state"):
				sprite.set_current_state(&"Idle")
		)

	# Bersihkan aura showcase sisi ini, lalu pasang aura idle+glow
	var aura_ref: Node2D = _p1_showcase_aura if player_idx == 1 else _p2_showcase_aura
	if is_instance_valid(aura_ref):
		aura_ref.queue_free()
	var aura = VFXCharacterAuraScript.new()
	_vfx_preview_root.add_child(aura)
	aura.setup(null, pos, profile.primary_color, profile.secondary_color, 0.65, 1.35, Vector2.ZERO, false)
	if player_idx == 1:
		_p1_showcase_aura = aura
	else:
		_p2_showcase_aura = aura

	# Signature VFX singkat sesuai profil
	var burst = VFXAuraBurstScript.new()
	_vfx_preview_root.add_child(burst)
	burst.trigger_burst(pos, profile.primary_color, 42.0, 0.28, 1.0, profile.flash_color)
	var sw = VFXShockwaveScript.new()
	_vfx_preview_root.add_child(sw)
	sw.trigger_shockwave(pos, 34.0, profile.primary_color, 0.22, 2.0)
	_spawn_signature_preview(profile, pos, player_idx)

func _spawn_signature_preview(profile: VfxProfile, pos: Vector2, player_idx: int) -> void:
	var facing := 1 if player_idx == 1 else -1
	var c := profile.primary_color
	var s := profile.spark_color
	match profile.signature_effect:
		&"cryo_matrix":
			var fx = VFXCryoFreezeScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_freeze(pos, 22.0, c)
		&"seismic_forge":
			var fx = VFXSeismicImpactScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_impact(pos + Vector2(0, 8), facing, c, 40.0)
		&"photon_horizon", &"master_spark", &"pod_042":
			var fx = VFXOrbitalBeamScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_beam(pos + Vector2(-facing * 30, -10), Vector2(facing, 0), 80.0, 12.0, c, 0.28)
		&"shadow_stance", &"ofuda_seal":
			var fx = VFXCinematicSlashScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_cinematic_slash(pos, 1, c, 0.24, 70.0)
		&"gunslinger", &"reaper_chain", &"chidori":
			var fx = VFXLightningArcScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_arc(pos, pos + Vector2(facing * 55, -10), s, 0.2, 2)
		&"overload", &"rhythm_pulse", &"gungnir":
			var fx = VFXSupernovaScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_supernova(pos, 38.0, c, 0.3)
		_:
			var fx = VFXLightningArcScript.new(); _vfx_preview_root.add_child(fx); fx.trigger_arc(pos, pos + Vector2(facing * 45, -8), c, 0.18, 1)

func _scroll_to_index(idx: int, animate: bool = true) -> void:
	# Grid 2 baris dirancang muat di area; hindari menggeser container yang memakai anchors.
	if not cards_container or idx < 0 or idx >= _card_nodes.size():
		return
	var card: PanelContainer = _card_nodes[idx]
	if card.size.x <= 0.0 or cards_container.size.x <= 0.0:
		call_deferred("_scroll_to_index", idx, animate)
		return
	if cards_container.layout_mode != 0:
		# Layout berbasis anchors: biarkan Container/Grid yang mengatur posisi (tanpa pergeseran manual).
		return
	var area_w: float = cards_container.get_parent().size.x
	if area_w <= 0.0:
		area_w = 640.0
	var card_center: float = card.position.x + card.size.x * 0.5
	var target_x: float = (area_w * 0.5) - card_center
	var content_w: float = cards_container.get_combined_minimum_size().x
	if content_w <= 0.0:
		content_w = cards_container.size.x
	var min_x: float = minf(0.0, area_w - content_w)
	var max_x: float = 0.0
	target_x = clampf(target_x, min_x, max_x)
	if min_x >= -0.5 and max_x <= 0.5:
		return
	if is_instance_valid(_scroll_tween):
		_scroll_tween.kill()
	if animate:
		_scroll_tween = create_tween()
		_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_scroll_tween.tween_property(cards_container, "position:x", target_x, 0.16)
	else:
		cards_container.position.x = target_x

func _fade_out_and_execute(callable: Callable) -> void:
	if not fade_rect:
		callable.call()
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tw.tween_callback(callable)
