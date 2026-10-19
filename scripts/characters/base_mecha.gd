class_name BaseMecha
extends CharacterBody2D

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const HeatComponentScript = preload("res://scripts/combat/components/heat_component.gd")
const MeltdownState = preload("res://scripts/combat/fsm/meltdown_state.gd")
const ParryState = preload("res://scripts/combat/fsm/parry_state.gd")
const BlockstunState = preload("res://scripts/combat/fsm/blockstun_state.gd")
const CliffhangerState = preload("res://scripts/combat/fsm/cliffhanger_state.gd")
const AttackData = preload("res://scripts/combat/resources/attack_data.gd")

## Base Controller untuk Mecha Tempur dalam Fighting to Zero
## Mengintegrasikan Hierarchical State Machine (Mecha HSM), Physics 60 FPS, dan Orientasi Visual

@export_group("Movement Stats")
@export var walk_speed: float = CombatConstants.DEFAULT_WALK_SPEED
@export var jump_velocity: float = CombatConstants.JUMP_VELOCITY
@export var gravity: float = CombatConstants.GRAVITY

@export_group("Combat Stats")
@export var max_hp: int = 1000
@export var max_heat: float = 100.0
@export var passive_damage_reduction: float = 0.0

@export_group("Ultimate Stats")
@export var max_ultimate: float = CombatConstants.MAX_ULTIMATE

var current_hp: int = 1000
var heat_gauge: float = 0.0
var current_ultimate: float = 0.0
var facing_direction: int = 1 # 1: Kanan, -1: Kiri

# Hitstop, Super Armor, & Invulnerability Frames (Story 2.3, 3.3)
var hitstop_frames: int = 0
var invulnerability_frames: int = 0
var super_armor_frames: int = 0
var simulated_horizontal_input: float = 0.0

# Cliffhanger System (Story 4.2)
var cliffhanger_grabs_used: int = 0

func can_cliffhanger() -> bool:
	return cliffhanger_grabs_used < CombatConstants.CLIFFHANGER_MAX_GRAB_COUNT and current_hp > 0

func trigger_cliffhanger(side: StringName) -> bool:
	if not can_cliffhanger():
		return false
	if state_machine:
		var ch_state = state_machine.get_node_or_null("Cliffhanger")
		if ch_state and ch_state.has_method("setup_ledge"):
			ch_state.setup_ledge(side)
		state_machine.change_state(&"Cliffhanger")
		return true
	return false

func reset_cliffhanger() -> void:
	cliffhanger_grabs_used = 0

func has_super_armor() -> bool:
	return super_armor_frames > 0

# Combo Tracking & Bounce Limits (Story 3.1)
var combo_hit_count: int = 0
var ground_bounce_count: int = 0
var wall_bounce_count: int = 0

var attack_resources: Dictionary = {
	&"5L": preload("res://resources/attacks/normal_light.tres"),
	&"5H": preload("res://resources/attacks/normal_heavy.tres"),
	&"Skill1": preload("res://resources/attacks/skill_slash.tres")
}

# Dash State & Cooldown Variables (Story 1.2)
var can_air_dash: bool = true
var dash_cooldown_frames: int = 0

# Coyote Time & Platform Tracking (Story 1.3)
var coyote_frames_left: int = 0
var was_on_floor_last_frame: bool = true

# Hitbox & Hurtbox Components (Story 1.4)
var hurtbox: Area2D = null
var hitbox: Area2D = null

# Heat Component (Story 2.1 & 2.2)
var heat_component: HeatComponentScript = null

@onready var state_machine: StateMachine = $StateMachine
@onready var visual_root: Node2D = _find_visual_node()

func _ready() -> void:
	current_hp = max_hp
	_setup_combat_colliders()
	_setup_heat_component()
	_setup_fsm_states()
	_setup_input_fallbacks()
	
	# Set default layer dan mask: Layer 1 (World)
	collision_layer = 1
	collision_mask = 1

	if OS.is_debug_build():
		print("[STATE][%s] BaseMecha siap. Kecepatan jalan: %.1f px/s, Lompat: %.1f px/s." % [
			name, walk_speed, jump_velocity
		])

func _setup_fsm_states() -> void:
	if not state_machine:
		return
	if not state_machine.has_node("Meltdown"):
		var meltdown_node := MeltdownState.new()
		meltdown_node.name = "Meltdown"
		state_machine.add_child(meltdown_node)
		state_machine.states[&"Meltdown"] = meltdown_node
		meltdown_node.setup(self, state_machine)
	if not state_machine.has_node("Parry"):
		var parry_node := ParryState.new()
		parry_node.name = "Parry"
		state_machine.add_child(parry_node)
		state_machine.states[&"Parry"] = parry_node
		parry_node.setup(self, state_machine)
	if not state_machine.has_node("Blockstun"):
		var blockstun_node := BlockstunState.new()
		blockstun_node.name = "Blockstun"
		state_machine.add_child(blockstun_node)
		state_machine.states[&"Blockstun"] = blockstun_node
		blockstun_node.setup(self, state_machine)
	if not state_machine.has_node("Cliffhanger"):
		var cliffhanger_node := CliffhangerState.new()
		cliffhanger_node.name = "Cliffhanger"
		state_machine.add_child(cliffhanger_node)
		state_machine.states[&"Cliffhanger"] = cliffhanger_node
		cliffhanger_node.setup(self, state_machine)

func is_overclocked() -> bool:
	return heat_component != null and heat_component.is_overclocked()

func _setup_heat_component() -> void:
	if has_node("HeatComponent"):
		heat_component = get_node("HeatComponent")
	else:
		heat_component = HeatComponentScript.new()
		heat_component.name = "HeatComponent"
		add_child(heat_component)

	if not heat_component.heat_changed.is_connected(_on_heat_changed):
		heat_component.heat_changed.connect(_on_heat_changed)
	if not heat_component.meltdown_triggered.is_connected(_on_meltdown_triggered):
		heat_component.meltdown_triggered.connect(_on_meltdown_triggered)
	heat_gauge = heat_component.current_heat

func _on_meltdown_triggered() -> void:
	if state_machine:
		state_machine.change_state(&"Meltdown")

func _on_heat_changed(current: float, _max_val: float) -> void:
	heat_gauge = current

## Pendinginan pasif: hanya saat state aktif Idle atau Walk (-0.2 heat per physics frame)
func _update_heat_cooling() -> void:
	if not heat_component:
		return
	var can_cool: bool = false
	if state_machine and state_machine.current_state:
		var state_name: StringName = state_machine.current_state.name
		can_cool = state_name == &"Idle" or state_name == &"Walk"
	heat_component.process_frame(can_cool)

func add_heat(amount: float) -> void:
	if heat_component:
		heat_component.add_heat(amount)

func _setup_combat_colliders() -> void:
	# Hurtbox (Layer 2)
	if has_node("Hurtbox"):
		hurtbox = get_node("Hurtbox") as Area2D
	else:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(24, 38)
		shape.shape = rect
		hurtbox.add_child(shape)
		add_child(hurtbox)

	hurtbox.collision_layer = 1 << (CombatConstants.LAYER_HURTBOX - 1)
	hurtbox.collision_mask = 0

	# Hitbox (Layer 3 memantau Layer 2)
	if has_node("Hitbox"):
		hitbox = get_node("Hitbox") as Area2D
	else:
		hitbox = Area2D.new()
		hitbox.name = "Hitbox"
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28, 20)
		shape.shape = rect
		shape.position = Vector2(18 * facing_direction, -4)
		hitbox.add_child(shape)
		add_child(hitbox)

	# Visual Slash Effect untuk feedback pukulan
	if not hitbox.has_node("SlashVisual"):
		var slash := ColorRect.new()
		slash.name = "SlashVisual"
		slash.size = Vector2(30, 20)
		slash.position = Vector2(6 * facing_direction, -10)
		slash.color = Color(1.0, 0.9, 0.2, 0.9) # Golden energy blade
		slash.visible = false
		hitbox.add_child(slash)

	hitbox.collision_layer = 1 << (CombatConstants.LAYER_STRIKE_HITBOX - 1)
	hitbox.collision_mask = 1 << (CombatConstants.LAYER_HURTBOX - 1)
	hitbox.monitoring = false
	hitbox.monitorable = false

	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var victim: Node2D = area.owner if area.owner else area.get_parent()
	if not victim or victim == self:
		return
	if not state_machine:
		return
	var attack_state = state_machine.get_node_or_null("Attack")
	if attack_state and attack_state.has_method("can_hit_target") and attack_state.can_hit_target(victim):
		attack_state.register_hit_target(victim)
		if victim.has_method("take_hit"):
			var outgoing_data: Dictionary = attack_state.current_attack_data.duplicate()
			# Buff Damage Overclock (+20% damage jika attacker di zona Overclock - Story 2.2 AC 2)
			if is_overclocked():
				var base_dmg: int = outgoing_data.get("damage", 40)
				outgoing_data["damage"] = int(round(float(base_dmg) * CombatConstants.OVERCLOCK_DAMAGE_MULTIPLIER))
			victim.take_hit(self, outgoing_data)

func set_hitbox_active(active: bool) -> void:
	if hitbox:
		hitbox.monitoring = active
		hitbox.monitorable = active
		# Sinkronisasi posisi offset hitbox dengan arah hadap mecha
		if hitbox.has_node("CollisionShape2D"):
			var shape = hitbox.get_node("CollisionShape2D")
			shape.position.x = absf(shape.position.x) * float(facing_direction)
		if hitbox.has_node("SlashVisual"):
			var slash = hitbox.get_node("SlashVisual") as ColorRect
			slash.visible = active
			if facing_direction > 0:
				slash.position.x = 4.0
			else:
				slash.position.x = -34.0

func is_hitbox_active() -> bool:
	return hitbox != null and hitbox.monitoring

func take_hit(attacker: Node2D, hit_data: Dictionary) -> void:
	if invulnerability_frames > 0:
		return

	# Cek apakah sedang berada di ParryState dan jendela aktif parry terbuka (Story 2.3 AC 3)
	if state_machine and state_machine.current_state and state_machine.current_state.name == &"Parry":
		var parry_state = state_machine.current_state
		if parry_state.has_method("is_parry_active") and parry_state.is_parry_active():
			if parry_state.has_method("handle_parry_hit"):
				parry_state.handle_parry_hit(attacker, hit_data)
				return

	# Cek Normal Blocking & Chip Damage (Story 2.4 AC 1 & 2; Story 3.3 Grabs/Unblockables ignore block)
	var is_unblockable: bool = hit_data.get("is_unblockable", false) or hit_data.get("is_grab", false)
	if can_block() and is_holding_block(attacker) and not is_unblockable:
		var is_energy: bool = hit_data.get("is_energy", false) or hit_data.get("type", "") == "energy"
		var block_dmg: int = 0
		if is_energy:
			var base_dmg: int = hit_data.get("damage", 40)
			block_dmg = int(round(float(base_dmg) * CombatConstants.CHIP_DAMAGE_RATIO))
			if base_dmg > 0 and block_dmg == 0:
				block_dmg = 1

		current_hp = max(0, current_hp - block_dmg)

		# Terapkan blockstun dan knockback teredam (60%)
		var kb_val: float = hit_data.get("knockback", 120.0) * CombatConstants.BLOCK_KNOCKBACK_MULTIPLIER
		var kb_dir: float = 1.0 if (attacker and attacker.global_position.x < global_position.x) else -1.0
		var kb_vec: Vector2 = Vector2(kb_dir * kb_val, 0.0)
		var blockstun_frames: int = hit_data.get("blockstun", CombatConstants.DEFAULT_BLOCKSTUN_FRAMES)

		if state_machine:
			var blockstun_state = state_machine.get_node_or_null("Blockstun")
			if blockstun_state and blockstun_state.has_method("setup_blockstun"):
				blockstun_state.setup_blockstun(blockstun_frames, kb_vec)
				state_machine.change_state(&"Blockstun")

		var blocked_data: Dictionary = hit_data.duplicate()
		blocked_data["blocked"] = true
		blocked_data["chip_damage"] = block_dmg
		if is_instance_valid(EventBus):
			EventBus.hit_confirmed.emit(attacker, self, blocked_data)
		else:
			var bus = get_node_or_null("/root/EventBus")
			if bus:
				bus.hit_confirmed.emit(attacker, self, blocked_data)
		return

	# Combo Hit Tracking & Scaling (Story 3.1 AC 2)
	if state_machine and state_machine.current_state and state_machine.current_state.name == &"Hitstun":
		combo_hit_count += 1
	else:
		combo_hit_count = 1
		ground_bounce_count = 0
		wall_bounce_count = 0

	var base_dmg: int = hit_data.get("damage", 40)
	var dmg: int = CombatConstants.calculate_combo_damage(base_dmg, combo_hit_count)

	# Reduksi pasif damage (Story 3.3 Titan-V Bulwark -5% passive armor reduction)
	if passive_damage_reduction > 0.0:
		dmg = int(round(float(dmg) * (1.0 - passive_damage_reduction)))
		dmg = max(1, dmg)

	# Evaluasi Ground Bounce & Wall Bounce Limits (Story 3.1 AC 3)
	var allows_ground_bounce: bool = false
	if hit_data.get("causes_ground_bounce", false):
		if ground_bounce_count < CombatConstants.MAX_GROUND_BOUNCES_PER_COMBO:
			ground_bounce_count += 1
			allows_ground_bounce = true

	var allows_wall_bounce: bool = false
	if hit_data.get("causes_wall_bounce", false):
		if wall_bounce_count < CombatConstants.MAX_WALL_BOUNCES_PER_COMBO:
			wall_bounce_count += 1
			allows_wall_bounce = true

	# Penalti Kerusakan Masuk Meltdown (+25% damage jika mecha sedang di MeltdownShutdown - Story 2.2 AC 3)
	if state_machine and state_machine.current_state and state_machine.current_state.name == &"Meltdown":
		dmg = int(round(float(dmg) * CombatConstants.MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER))

	current_hp = max(0, current_hp - dmg)

	# Super Armor: Full Super Armor (Story 3.3 Bulwark Riot Shield) & 1-Hit Startup Super Armor (Story 2.2 AC 2)
	var absorbed_by_armor: bool = false
	var is_grab: bool = hit_data.get("is_grab", false)

	if not is_grab:
		if has_super_armor():
			absorbed_by_armor = true
			if OS.is_debug_build():
				print("[COMBAT][%s] Full Super Armor menyerap hitstun!" % name)
		elif state_machine and state_machine.current_state and state_machine.current_state.name == &"Attack":
			var attack_state = state_machine.current_state
			if attack_state.has_method("is_startup_super_armor_active") and attack_state.is_startup_super_armor_active():
				attack_state.consume_super_armor()
				absorbed_by_armor = true
				if OS.is_debug_build():
					print("[COMBAT][%s] 1-Hit Super Armor menyerap hitstun!" % name)

	var kb_val: float = hit_data.get("knockback", 120.0)
	var kb_dir: float = 1.0 if (attacker and attacker.global_position.x < global_position.x) else -1.0
	var kb_vec: Vector2 = Vector2(kb_dir * kb_val, 0.0)

	# Jika armor menyerap hitstun atau sedang dalam Meltdown (sudah terkunci), jangan beralih ke Hitstun
	if not absorbed_by_armor:
		if state_machine and state_machine.current_state and state_machine.current_state.name != &"Meltdown":
			var hitstun_state = state_machine.get_node_or_null("Hitstun")
			if hitstun_state and hitstun_state.has_method("setup_hitstun"):
				hitstun_state.setup_hitstun(hit_data.get("hitstun", 14), kb_vec)
				state_machine.change_state(&"Hitstun")

	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.emit(attacker, self, hit_data)
	else:
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.hit_confirmed.emit(attacker, self, hit_data)

func request_attack(attack_data: Variant) -> void:
	if state_machine:
		var attack_state = state_machine.get_node_or_null("Attack")
		if attack_state and attack_state.has_method("setup_attack"):
			attack_state.setup_attack(attack_data)
			state_machine.change_state(&"Attack")

func request_attack_by_name(atk_name: StringName) -> void:
	if atk_name in attack_resources:
		request_attack(attack_resources[atk_name])
	elif atk_name == &"5L":
		request_attack(CombatConstants.LIGHT_ATTACK)
	elif atk_name == &"5H":
		request_attack(CombatConstants.HEAVY_ATTACK)

func reset_combo_state() -> void:
	combo_hit_count = 0
	ground_bounce_count = 0
	wall_bounce_count = 0

func _unhandled_input(event: InputEvent) -> void:
	var buffer = get_node_or_null("/root/InputBuffer")
	if not buffer:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept"):
		buffer.buffer_action(&"jump")
	elif event.is_action_pressed("dash"):
		buffer.buffer_action(&"dash", get_dash_vector())
	elif event.is_action_pressed("attack_light"):
		buffer.buffer_action(&"attack_light")
	elif event.is_action_pressed("attack_heavy"):
		buffer.buffer_action(&"attack_heavy")
	elif event.is_action_pressed("skill1"):
		buffer.buffer_action(&"skill1")
	elif event.is_action_pressed("skill2"):
		buffer.buffer_action(&"skill2")
	elif event.is_action_pressed("ultimate"):
		buffer.buffer_action(&"ultimate")
	elif event.is_action_pressed("parry"):
		buffer.buffer_action(&"parry")

func _physics_process(delta: float) -> void:
	if invulnerability_frames > 0:
		invulnerability_frames -= 1

	if super_armor_frames > 0:
		super_armor_frames -= 1

	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	tick_cooldowns()

	# Deteksi pelepasan kontak platform tanpa lompat (Ledge Departure -> Coyote Time AC 2)
	if was_on_floor_last_frame and not is_on_floor():
		if state_machine and state_machine.current_state and state_machine.current_state.name != &"Jump" and state_machine.current_state.name != &"AirDash":
			notify_ledge_drop()
	was_on_floor_last_frame = is_on_floor()

	# Reset hak air dash dan coyote time secara otomatis begitu mendarat di platform (AC 2, AC 3)
	if is_on_floor():
		coyote_frames_left = 0
		reset_air_dash()

	# Pendinginan heat dihitung sebelum update state (atau memakai state aktif saat tick dimulai)
	_update_heat_cooling()

	if state_machine:
		state_machine.physics_update(delta)

	move_and_slide()
	_update_hud()

func _find_visual_node() -> Node2D:
	if has_node("MechaVisual"):
		return get_node("MechaVisual") as Node2D
	for child in get_children():
		if child is CanvasItem and child != state_machine and not (child is CollisionShape2D):
			return child as Node2D
	return null

func set_facing_direction(dir: int) -> void:
	if dir == 0:
		return
	facing_direction = 1 if dir > 0 else -1
	if visual_root:
		visual_root.scale.x = absf(visual_root.scale.x) * facing_direction

func get_horizontal_axis() -> float:
	var axis: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(axis):
		axis = Input.get_axis("ui_left", "ui_right")
	return clampf(axis, -1.0, 1.0)

func is_jump_requested() -> bool:
	if (
		Input.is_action_just_pressed("jump")
		or Input.is_action_just_pressed("ui_up")
		or Input.is_action_just_pressed("ui_accept")
	):
		return true
	return has_buffered_action(&"jump")

func is_dash_requested() -> bool:
	if Input.is_action_just_pressed("dash"):
		return true
	return has_buffered_action(&"dash")

func is_attack_light_requested() -> bool:
	if Input.is_action_just_pressed("attack_light"):
		return true
	return has_buffered_action(&"attack_light")

func is_attack_heavy_requested() -> bool:
	if Input.is_action_just_pressed("attack_heavy"):
		return true
	return has_buffered_action(&"attack_heavy")

func is_parry_requested() -> bool:
	if Input.is_action_just_pressed("parry"):
		return true
	return has_buffered_action(&"parry")

func is_skill_requested() -> bool:
	if Input.is_action_just_pressed("skill1"):
		return true
	return has_buffered_action(&"skill1")

func is_skill2_requested() -> bool:
	if Input.is_action_just_pressed("skill2"):
		return true
	return has_buffered_action(&"skill2")

func is_ultimate_requested() -> bool:
	if Input.is_action_just_pressed("ultimate"):
		return true
	return has_buffered_action(&"ultimate")

func get_dash_speed() -> float:
	return CombatConstants.DASH_SPEED

func get_dash_duration() -> int:
	return CombatConstants.DASH_DURATION_FRAMES

func apply_hitstop(frames: int) -> void:
	hitstop_frames = max(hitstop_frames, frames)

func grant_invulnerability(frames: int) -> void:
	invulnerability_frames = max(invulnerability_frames, frames)

func add_ultimate(amount: float) -> void:
	current_ultimate = clampf(current_ultimate + amount, 0.0, max_ultimate)

func drain_ultimate(amount: float) -> float:
	var actual_drain: float = minf(current_ultimate, amount)
	current_ultimate = maxf(0.0, current_ultimate - actual_drain)
	return actual_drain

func get_horizontal_axis() -> float:
	if not is_zero_approx(simulated_horizontal_input):
		return simulated_horizontal_input
	var val: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(val):
		val = Input.get_axis("ui_left", "ui_right")
	return val

func can_block() -> bool:
	if not state_machine or not state_machine.current_state:
		return false
	var sname: StringName = state_machine.current_state.name
	return sname == &"Idle" or sname == &"Walk" or sname == &"Blockstun"

func is_holding_block(attacker: Node2D) -> bool:
	if not attacker:
		return false
	var h_input: float = get_horizontal_axis()
	# Jika penyerang di sebelah kiri (attacker.x < mecha.x), holding away adalah menahan kanan (h_input > 0.2)
	if attacker.global_position.x < global_position.x:
		return h_input > 0.2
	# Jika penyerang di sebelah kanan (attacker.x > mecha.x), holding away adalah menahan kiri (h_input < -0.2)
	elif attacker.global_position.x > global_position.x:
		return h_input < -0.2
	return false

func can_dash() -> bool:
	return dash_cooldown_frames <= 0

func tick_cooldowns() -> void:
	if dash_cooldown_frames > 0:
		dash_cooldown_frames -= 1

func reset_air_dash() -> void:
	can_air_dash = true

func notify_ledge_drop() -> void:
	coyote_frames_left = CombatConstants.COYOTE_TIME_FRAMES

func tick_coyote_time() -> void:
	if coyote_frames_left > 0:
		coyote_frames_left -= 1

func can_coyote_jump() -> bool:
	return coyote_frames_left > 0

func consume_coyote_jump() -> void:
	coyote_frames_left = 0

func has_buffered_action(action_name: StringName) -> bool:
	var buffer = get_node_or_null("/root/InputBuffer")
	if buffer and buffer.has_method("has_action"):
		return buffer.has_action(action_name)
	return false

func try_consume_buffered_action(action_name: StringName) -> bool:
	var buffer = get_node_or_null("/root/InputBuffer")
	if buffer and buffer.has_method("consume_action"):
		return buffer.consume_action(action_name)
	return false

func try_consume_buffered_action_with_data(action_name: StringName) -> Dictionary:
	var buffer = get_node_or_null("/root/InputBuffer")
	if buffer and buffer.has_method("consume_action_with_data"):
		return buffer.consume_action_with_data(action_name)
	return {}

func get_dash_vector() -> Vector2:
	var h: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(h):
		h = Input.get_axis("ui_left", "ui_right")

	var v: float = Input.get_axis("move_up", "move_down")
	if is_zero_approx(v):
		v = Input.get_axis("ui_up", "ui_down")

	return resolve_dash_vector(Vector2(h, v), is_on_floor())

func resolve_dash_vector(raw_input: Vector2, on_floor: bool = false) -> Vector2:
	var sign_x: float = 0.0
	var sign_y: float = 0.0

	if raw_input.x > 0.2:
		sign_x = 1.0
	elif raw_input.x < -0.2:
		sign_x = -1.0

	if raw_input.y > 0.2:
		sign_y = 1.0
	elif raw_input.y < -0.2:
		sign_y = -1.0

	# Fallback ke arah hadap mecha jika input vektor nol
	if sign_x == 0.0 and sign_y == 0.0:
		return Vector2(float(facing_direction), 0.0)

	# Di darat, dash bawah murni (Vector2(0, 1)) dibatasi horizontal ke arah hadap (AC 1)
	if on_floor and sign_x == 0.0 and sign_y > 0.0:
		return Vector2(float(facing_direction), 0.0)

	return Vector2(sign_x, sign_y).normalized()

func _setup_input_fallbacks() -> void:
	_bind_key("ui_left", KEY_A)
	_bind_key("ui_right", KEY_D)
	_bind_key("ui_up", KEY_W)
	_bind_key("ui_down", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("move_up", KEY_W)
	_bind_key("move_down", KEY_S)
	_bind_key("jump", KEY_SPACE)
	_bind_key("dash", KEY_SHIFT)
	_bind_key("dash", KEY_X)
	_bind_key("attack_light", KEY_J)
	_bind_key("attack_light", KEY_Z)
	_bind_key("attack_heavy", KEY_K)
	_bind_key("attack_heavy", KEY_C)
	_bind_key("parry", KEY_L)
	_bind_key("parry", KEY_V)
	_bind_key("skill1", KEY_U)
	_bind_key("skill2", KEY_I)
	_bind_key("ultimate", KEY_O)

func _bind_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event.physical_keycode == key or event.keycode == key):
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	InputMap.action_add_event(action, ev)

func _update_hud() -> void:
	var heat_bar := get_node_or_null("../UI/HUD/HeatBar") as ProgressBar
	if heat_bar:
		heat_bar.value = heat_gauge
	var heat_label := get_node_or_null("../UI/HUD/HeatLabel") as Label
	if heat_label:
		if is_overclocked():
			heat_label.text = "HEAT: %d%% [OVERCLOCK! +20%% DMG]" % int(heat_gauge)
		elif state_machine and state_machine.current_state and state_machine.current_state.name == &"Meltdown":
			heat_label.text = "HEAT: %d%% [MELTDOWN SHUTDOWN!]" % int(heat_gauge)
		else:
			heat_label.text = "HEAT: %d%%" % int(heat_gauge)
	var status_label := get_node_or_null("../UI/HUD/StatusLabel") as Label
	if status_label and state_machine and state_machine.current_state:
		var state_text: String = state_machine.current_state.name.to_upper()
		if is_overclocked():
			state_text += " (OVERCLOCK BUFF ACTIVE)"
		elif state_machine.current_state.name == &"Meltdown":
			state_text += " (PENALTY +25% DMG TAKEN)"
		elif state_machine.current_state.name == &"Parry":
			state_text += " (SPARK PARRY)"
		elif state_machine.current_state.name == &"Blockstun":
			state_text += " (GUARDING)"
		status_label.text = "STATE: %s" % state_text
	var dummy := get_node_or_null("../DummyTarget") as CharacterBody2D
	var dummy_label := get_node_or_null("../UI/HUD/DummyHPLabel") as Label
	if dummy and dummy_label:
		var dummy_state = dummy.state_machine.current_state.name.to_upper() if (dummy.state_machine and dummy.state_machine.current_state) else "IDLE"
		dummy_label.text = "TARGET DUMMY HP: %d / %d | STATE: %s" % [dummy.current_hp, dummy.max_hp, dummy_state]
