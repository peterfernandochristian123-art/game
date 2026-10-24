class_name VFXShowcase
extends Node2D

## Interactive Skill Visual Effects Showcase Lab
## Memungkinkan peninjauan langsung setiap efek visual skill dari seluruh mecha roster

const VFXManagerScript = preload("res://scripts/visual/vfx_manager.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")

var vfx_manager: VFXManager = null
var caster_dummy: Node2D = null
var target_dummy: Node2D = null
var info_label: Label = null
var time_scale_btn: Button = null

var current_time_scale: float = 1.0

const SKILLS: Array[Dictionary] = [
	# Apex-0 Viper
	{"key": KEY_1, "name": "Blink Slash", "mecha": "Apex-0 Viper", "skill": &"BlinkSlash", "color": Color(0.2, 0.95, 1.0), "desc": "Teleportasi berkecepatan tinggi & ledakan kristal es heksagonal."},
	{"key": KEY_2, "name": "Deflection Matrix", "mecha": "Apex-0 Viper", "skill": &"DeflectionMatrix", "color": Color(0.2, 0.95, 1.0), "desc": "Perisai energi heksagonal berdenyut dengan bracket sudut defleksi."},
	{"key": KEY_3, "name": "Absolute Zero", "mecha": "Apex-0 Viper", "skill": &"AbsoluteZeroProtocol", "color": Color(0.3, 0.98, 1.0), "desc": "Nova kriogenik radius 130px membekukan mecha core ke 0% Heat."},

	# Titan-V Bulwark
	{"key": KEY_4, "name": "Hydraulic Piledriver", "mecha": "Titan-V Bulwark", "skill": &"HydraulicPiledriver", "color": Color(1.0, 0.55, 0.15), "desc": "Hantaman seismik lantai, retakan tanah bercahaya & puing bebatuan."},
	{"key": KEY_5, "name": "Riot Shield", "mecha": "Titan-V Bulwark", "skill": &"RiotShield", "color": Color(1.0, 0.65, 0.2), "desc": "Perisai baja berat heksagonal amber pelindung Full Super Armor."},
	{"key": KEY_6, "name": "Orbital Siege Cannon", "mecha": "Titan-V Bulwark", "skill": &"OrbitalSiegeCannon", "color": Color(1.0, 0.6, 0.15), "desc": "Meriam partikel orbital vertikal dari langit dengan cincin resonansi."},

	# Ray-X Pulsar
	{"key": KEY_7, "name": "Photon Railgun", "mecha": "Ray-X Pulsar", "skill": &"PhotonRailgun", "color": Color(0.75, 0.25, 1.0), "desc": "Laser foton horizontal menembus ruang dengan cincin riak cahaya."},
	{"key": KEY_8, "name": "Disrupter Drone", "mecha": "Ray-X Pulsar", "skill": &"DisrupterDrone", "color": Color(0.7, 0.3, 1.0), "desc": "Unit drone foton melayang dengan gyro rings berputar & pulsa radar."},
	{"key": KEY_9, "name": "Supernova Horizon", "mecha": "Ray-X Pulsar", "skill": &"SupernovaHorizon", "color": Color(0.8, 0.25, 1.0), "desc": "Ledakan 360 derajat korona surya ungu-magenta & suar radiasi kosmik."},

	# Phantom-9 Kage
	{"key": KEY_Q, "name": "Stance Shift & Feint", "mecha": "Phantom-9 Kage", "skill": &"StanceShift", "color": Color(0.95, 0.15, 0.25), "desc": "Kepulan ledakan asap ninja crimson-hitam & siluet ilusi bayangan."},
	{"key": KEY_W, "name": "Iaido Crescent", "mecha": "Phantom-9 Kage", "skill": &"IaidoCrescent", "color": Color(1.0, 0.15, 0.25), "desc": "Tebasan sabit diagonal berkecepatan tinggi dengan garis kecepatan manga."},
	{"key": KEY_E, "name": "Shuriken Storm", "mecha": "Phantom-9 Kage", "skill": &"ShurikenStorm", "color": Color(1.0, 0.2, 0.3), "desc": "3 shuriken foton 4-point berkipas berputar cepat dengan jejak neon."},
	{"key": KEY_R, "name": "Shadow Blossom", "mecha": "Phantom-9 Kage", "skill": &"ShadowBlossom", "color": Color(1.0, 0.1, 0.25), "desc": "Rangkaian 5 sayatan pedang bersilangan layar penuh bercahaya crimson tajam."},

	# Final Boss Unit-0
	{"key": KEY_T, "name": "Cataclysm Slash", "mecha": "Boss Unit-0", "skill": &"CataclysmSlash", "color": Color(1.2, 0.1, 0.3), "desc": "Tebasan sayatan kehampaan merah darah terkorupsi partikel glitch."},
	{"key": KEY_Y, "name": "Zero Overload", "mecha": "Boss Unit-0", "skill": &"ZeroOverload", "color": Color(1.1, 0.1, 0.3), "desc": "Ledakan kehampaan proto-core Overclock 220px dengan distorsi merah pekat."}
]

func _ready() -> void:
	_setup_background()
	_setup_dummies()
	_setup_vfx_manager()
	_setup_ui()

func _setup_background() -> void:
	# Background kanvas gelap retro grid
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 1.0)
	bg.size = Vector2(1280, 720)
	bg.z_index = -100
	add_child(bg)

	# Lantai panggung
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.12, 0.15, 0.22, 1.0)
	floor_rect.position = Vector2(0, 520)
	floor_rect.size = Vector2(1280, 200)
	floor_rect.z_index = -90
	add_child(floor_rect)

	# Garis pembatas lantai neon
	var floor_line := ColorRect.new()
	floor_line.color = Color(0.2, 0.8, 1.0, 0.8)
	floor_line.position = Vector2(0, 518)
	floor_line.size = Vector2(1280, 2)
	floor_line.z_index = -85
	add_child(floor_line)

func _setup_dummies() -> void:
	# Caster Dummy (Mecha Biru/Kiri)
	caster_dummy = Node2D.new()
	caster_dummy.name = "P1_Viper"
	caster_dummy.position = Vector2(540, 480)
	add_child(caster_dummy)

	var spr1 = MechaPixelSpriteScript.new()
	spr1.modulate = Color(0.3, 0.9, 1.0)
	caster_dummy.add_child(spr1)

	# Target Dummy (Mecha Oranye/Kanan)
	target_dummy = Node2D.new()
	target_dummy.name = "P2_Titan"
	target_dummy.position = Vector2(740, 480)
	add_child(target_dummy)

	var spr2 = MechaPixelSpriteScript.new()
	spr2.modulate = Color(1.0, 0.5, 0.2)
	target_dummy.add_child(spr2)

func _setup_vfx_manager() -> void:
	vfx_manager = VFXManagerScript.new()
	vfx_manager.name = "VFXManager"
	add_child(vfx_manager)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# Header Title
	var title := Label.new()
	title.text = "⚡ FIGHTING TO ZERO - MECHA SKILL VFX SHOWCASE LAB ⚡"
	title.position = Vector2(20, 15)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.2, 0.95, 1.0)
	canvas.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Klik tombol di bawah atau tekan tombol keyboard [1-9, Q, W, E, R, T, Y] untuk memicu efek!"
	subtitle.position = Vector2(20, 42)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.7, 0.8, 0.9)
	canvas.add_child(subtitle)

	# Info Description Box
	info_label = Label.new()
	info_label.text = "Pilih salah satu skill untuk melihat animasi efek visual 32-bit dan penjelasannya."
	info_label.position = Vector2(20, 68)
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.modulate = Color(1.0, 0.9, 0.3)
	canvas.add_child(info_label)

	# Tombol Slow Motion
	time_scale_btn = Button.new()
	time_scale_btn.text = "SPEED: 1.0x (Normal)"
	time_scale_btn.position = Vector2(1080, 15)
	time_scale_btn.size = Vector2(180, 32)
	time_scale_btn.pressed.connect(_toggle_time_scale)
	canvas.add_child(time_scale_btn)

	# Tombol Kembali ke Main Menu
	var back_btn := Button.new()
	back_btn.text = "< MAIN MENU (ESC)"
	back_btn.position = Vector2(1080, 55)
	back_btn.size = Vector2(180, 32)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	canvas.add_child(back_btn)

	# Scroll Container untuk Tombol-tombol Skill di Bagian Bawah
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 545)
	scroll.size = Vector2(1240, 160)
	canvas.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	for data in SKILLS:
		var btn := Button.new()
		var key_str := OS.get_keycode_string(data["key"])
		btn.text = "[%s] %s (%s)" % [key_str, data["name"], data["mecha"]]
		btn.custom_minimum_size = Vector2(390, 36)
		btn.modulate = data["color"]
		var s_data = data
		btn.pressed.connect(func(): _trigger_skill(s_data))
		grid.add_child(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			return

		for data in SKILLS:
			if event.keycode == data["key"]:
				_trigger_skill(data)
				get_viewport().set_input_as_handled()
				return

func _trigger_skill(data: Dictionary) -> void:
	if not is_instance_valid(vfx_manager) or not is_instance_valid(caster_dummy):
		return

	var s_name: StringName = data["skill"]
	var m_name: String = data["mecha"]
	var pos: Vector2 = caster_dummy.global_position
	var facing: int = 1

	if info_label:
		info_label.text = "⚡ %s - %s: %s" % [m_name, data["name"], data["desc"]]
		info_label.modulate = data["color"]

	# 1. Panggil sinyal aktivasi skill global ke VFXManager
	EventBus.skill_cast.emit(caster_dummy, s_name, pos, facing)

	# 2. Jika skill berbasis serangan kontak langsung, simulasikan juga efek hit impact ke target dummy
	if s_name == &"BlinkSlash" or s_name == &"HydraulicPiledriver" or s_name == &"IaidoCrescent" or s_name == &"CataclysmSlash":
		get_tree().create_timer(0.08 / current_time_scale).timeout.connect(func():
			if is_instance_valid(target_dummy) and is_instance_valid(vfx_manager):
				vfx_manager._on_hit_confirmed(caster_dummy, target_dummy, {"name": String(s_name), "damage": 120})
		)

func _toggle_time_scale() -> void:
	if current_time_scale == 1.0:
		current_time_scale = 0.25
	elif current_time_scale == 0.25:
		current_time_scale = 0.5
	else:
		current_time_scale = 1.0

	Engine.time_scale = current_time_scale
	if time_scale_btn:
		time_scale_btn.text = "SPEED: %.2fx" % current_time_scale
