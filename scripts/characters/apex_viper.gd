class_name ApexViper
extends BaseMecha

## Petarung Mecha: Apex-0 "Viper" (Story 3.2)
## Archetype: High-Speed Rushdown / Aerial Assassin
## Kecepatan Jalan: 350 px/s, Dash: 820 px/s (12 frame)
## Total HP: 900 (mobilitas tinggi, pertahanan lebih tipis)

var cryogenic_frames_left: int = 0
var deflection_matrix_frames: int = 0

func _init() -> void:
	max_hp = CombatConstants.VIPER_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.VIPER_WALK_SPEED

func _ready() -> void:
	max_hp = CombatConstants.VIPER_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.VIPER_WALK_SPEED

	attack_resources = {
		&"5L": preload("res://resources/attacks/viper_jab.tres"),
		&"5L1": preload("res://resources/attacks/viper_jab.tres"),
		&"5L2": preload("res://resources/attacks/viper_thrust.tres"),
		&"5H": preload("res://resources/attacks/viper_cleave.tres"),
		&"Skill1": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"BlinkSlash": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"Skill2": preload("res://resources/attacks/viper_deflection_matrix.tres"),
		&"DeflectionMatrix": preload("res://resources/attacks/viper_deflection_matrix.tres")
	}

	super._ready()

	# Warna visual khas Viper: Cyan / Neon Blue
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.2, 0.9, 1.0, 1.0)

	if OS.is_debug_build():
		print("[CHARACTER][ApexViper] Apex-0 Viper diinisialisasi. HP: %d, Jalan: %.1f px/s, Dash: %.1f px/s." % [
			max_hp, walk_speed, get_dash_speed()
		])

## Kecepatan dash dinamis (meningkat +30% saat Absolute Zero Protocol aktif)
func get_dash_speed() -> float:
	if is_cryogenic_active():
		return CombatConstants.VIPER_DASH_SPEED * CombatConstants.VIPER_CRYOGENIC_DASH_BUFF
	return CombatConstants.VIPER_DASH_SPEED

## Durasi dash khusus Viper: 12 frame
func get_dash_duration() -> int:
	return CombatConstants.VIPER_DASH_DURATION_FRAMES

## Mengembalikan true jika mode cryogenic Absolute Zero Protocol sedang aktif
func is_cryogenic_active() -> bool:
	return cryogenic_frames_left > 0

## Selama mode cryogenic, suhu terkunci pada 0.0%
func add_heat(amount: float) -> void:
	if is_cryogenic_active():
		if heat_component:
			heat_component.current_heat = 0.0
		heat_gauge = 0.0
		return
	super.add_heat(amount)

## Skill 1: Blink Slash
## Teleportasi seketika sejauh hingga 400 px menembus garis musuh dan menebas dari belakang
func execute_blink_slash(target_opponent: Node2D = null) -> void:
	var teleport_distance: float = CombatConstants.VIPER_BLINK_SLASH_DISTANCE * float(facing_direction)

	if target_opponent:
		# Jika ada lawan di depan, posisikan mecha 60 px di belakang lawan dan hadap ke lawan
		var target_x: float = target_opponent.global_position.x
		var behind_x: float = target_x + (60.0 * float(facing_direction))
		global_position.x = behind_x
		set_facing_direction(-facing_direction)
	else:
		global_position.x += teleport_distance

	request_attack_by_name(&"BlinkSlash")

## Skill 2: Deflection Matrix
## Memasang jaring energi selama 30 frame pemantul proyektil dan memperlambat musuh (+20% Heat)
func execute_deflection_matrix() -> void:
	deflection_matrix_frames = CombatConstants.VIPER_DEFLECTION_DURATION_FRAMES
	request_attack_by_name(&"DeflectionMatrix")

## Ultimate: Absolute Zero Protocol
## Mode kriogenik 8 detik: Heat terkunci 0%, Dash +30%, dash udara tak terbatas
func activate_absolute_zero_protocol() -> bool:
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return false

	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	cryogenic_frames_left = CombatConstants.VIPER_CRYOGENIC_DURATION_FRAMES

	# Reset suhu seketika ke 0%
	if heat_component:
		heat_component.current_heat = 0.0
	heat_gauge = 0.0

	if OS.is_debug_build():
		print("[ULTIMATE][%s] ABSOLUTE ZERO PROTOCOL AKTIF! 8 Detik Cryogenic Mode!" % name)
	return true

func _physics_process(delta: float) -> void:
	if cryogenic_frames_left > 0:
		cryogenic_frames_left -= 1
		# Dash udara tidak terbatas selama Absolute Zero Protocol
		can_air_dash = true
		if heat_component:
			heat_component.current_heat = 0.0
		heat_gauge = 0.0

	if deflection_matrix_frames > 0:
		deflection_matrix_frames -= 1

	super._physics_process(delta)

func _update_hud() -> void:
	super._update_hud()
	var heat_label := get_node_or_null("../UI/HUD/HeatLabel") as Label
	if heat_label and is_cryogenic_active():
		var sec_left: float = float(cryogenic_frames_left) / 60.0
		heat_label.text = "HEAT: 0%% [ABSOLUTE ZERO! %.1fs]" % sec_left
