class_name AIController
extends Node

## Pengendali Kecerdasan Buatan (AI) untuk Mode Versus (Story 5.5)
## Menyediakan 3 Profil Tingkat Kesulitan: Novice, Veteran, Ace
## Beroperasi frame-by-frame pada 60 FPS tanpa beban lag / alokasi dinamis berat

enum Difficulty {
	NOVICE,
	VETERAN,
	ACE
}

@export var difficulty: Difficulty = Difficulty.VETERAN:
	set(val):
		difficulty = val
		_apply_difficulty_profile()

@export var enabled: bool = true

# Referensi Mecha AI dan Musuh (Pemain)
var mecha: Node2D = null
var opponent: Node2D = null

# Parameter Profil Kesulitan Terkonfigurasi
var reaction_delay_frames: int = 12
var block_chance: float = 0.70
var parry_chance: float = 0.35
var combo_extension_chance: float = 0.60
var dash_punish_chance: float = 0.60
var aggression: float = 0.65
var preferred_spacing: float = 110.0
var overclock_focus: bool = false

# Internal State Tracking & Timers
var _reaction_timer: int = 0
var _pending_defense_action: StringName = &""
var _is_reacting: bool = false
var _defending_active: bool = false
var _action_cooldown: int = 0
var _whiff_punish_cooldown: int = 0
var _combo_step: int = 0
var _rng := RandomNumberGenerator.new()

signal difficulty_changed(new_diff: Difficulty)

func _ready() -> void:
	_rng.randomize()
	_apply_difficulty_profile()

	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)

func setup(controlled_mecha: Node2D, target_opponent: Node2D, diff: Difficulty = Difficulty.VETERAN) -> void:
	mecha = controlled_mecha
	opponent = target_opponent
	difficulty = diff
	_apply_difficulty_profile()

func set_difficulty(new_diff: Difficulty) -> void:
	difficulty = new_diff

func _apply_difficulty_profile() -> void:
	match difficulty:
		Difficulty.NOVICE:
			reaction_delay_frames = 24
			block_chance = 0.20
			parry_chance = 0.05
			combo_extension_chance = 0.15
			dash_punish_chance = 0.15
			aggression = 0.35
			preferred_spacing = 140.0
			overclock_focus = false
		Difficulty.VETERAN:
			reaction_delay_frames = 12
			block_chance = 0.70
			parry_chance = 0.35
			combo_extension_chance = 0.65
			dash_punish_chance = 0.60
			aggression = 0.65
			preferred_spacing = 100.0
			overclock_focus = false
		Difficulty.ACE:
			reaction_delay_frames = 6
			block_chance = 0.95
			parry_chance = 0.85
			combo_extension_chance = 0.95
			dash_punish_chance = 0.95
			aggression = 0.90
			preferred_spacing = 75.0
			overclock_focus = true

	difficulty_changed.emit(difficulty)

func _physics_process(_delta: float) -> void:
	if not enabled or not is_instance_valid(mecha) or not is_instance_valid(opponent):
		return

	# Kurangi cooldown
	if _action_cooldown > 0:
		_action_cooldown -= 1
	if _whiff_punish_cooldown > 0:
		_whiff_punish_cooldown -= 1

	# Pastikan mecha menghadap musuh jika sedang idle/walk
	_update_facing()

	# 1. Evaluasi Pertahanan (Reaksi terhadap serangan pemain)
	_process_defense_reaction()

	# 2. Jika sedang bertahan, jangan timpa input gerakan
	if _is_defending():
		return

	# 3. Evaluasi Punish terhadap Whiff / Recovery lawan
	if _try_whiff_punish():
		return

	# 4. Spacing & Netral Movement
	_process_spacing_and_approach()

func _update_facing() -> void:
	if not mecha or not opponent:
		return
	var dx: float = opponent.global_position.x - mecha.global_position.x
	if absf(dx) > 10.0:
		var target_facing := 1 if dx > 0.0 else -1
		if mecha.has_method("set_facing_direction"):
			mecha.set_facing_direction(target_facing)

func _is_opponent_attacking() -> bool:
	if not opponent or not ("state_machine" in opponent):
		return false
	var sm = opponent.get("state_machine")
	if sm and sm.get("current_state"):
		return sm.current_state.name == &"Attack"
	return false

func _is_opponent_in_recovery_or_whiff() -> bool:
	if not opponent or not ("state_machine" in opponent):
		return false
	var sm = opponent.get("state_machine")
	if sm and sm.get("current_state"):
		var sname: StringName = sm.current_state.name
		if sname == &"Attack":
			var cur_state = sm.current_state
			# Bila dalam recovery phase
			if cur_state.get("state_phase") == 2: # 2 = RECOVERY
				return true
		elif sname == &"Hitstun":
			return true
	return false

func _is_defending() -> bool:
	return _is_reacting or _defending_active

func _process_defense_reaction() -> void:
	var opp_attacking := _is_opponent_attacking()
	var dist: float = absf(opponent.global_position.x - mecha.global_position.x)

	# Jika musuh mulai menyerang dan berada dalam jangkauan berbahaya (< 180px)
	if opp_attacking and dist < 180.0:
		if not _is_reacting and not _defending_active:
			# Jadwalkan reaksi berdasarkan profil
			_is_reacting = true
			_reaction_timer = reaction_delay_frames
			var roll := _rng.randf()
			if roll < parry_chance:
				_pending_defense_action = &"parry"
			elif roll < (parry_chance + block_chance):
				_pending_defense_action = &"block"
			else:
				_pending_defense_action = &"none"
	elif not opp_attacking:
		if _defending_active and _pending_defense_action == &"block":
			_stop_blocking()
		_pending_defense_action = &""
		_reaction_timer = 0
		_is_reacting = false
		_defending_active = false

	# Jalankan countdown reaksi
	if _reaction_timer > 0:
		_reaction_timer -= 1
		if _reaction_timer == 0:
			_is_reacting = false
			_defending_active = true
			_execute_defense_action()

func _execute_defense_action() -> void:
	match _pending_defense_action:
		&"parry":
			if mecha.has_method("trigger_simulated_action"):
				mecha.trigger_simulated_action(&"parry")
			_pending_defense_action = &""
		&"block":
			# Tahan arah mundur dari posisi lawan
			var dir_away: float = 1.0 if opponent.global_position.x < mecha.global_position.x else -1.0
			mecha.set("simulated_horizontal_input", dir_away)
		&"none":
			_pending_defense_action = &""

func _stop_blocking() -> void:
	mecha.set("simulated_horizontal_input", 0.0)

func _try_whiff_punish() -> bool:
	if _action_cooldown > 0 or _whiff_punish_cooldown > 0:
		return false

	if _is_opponent_in_recovery_or_whiff():
		var dist: float = absf(opponent.global_position.x - mecha.global_position.x)
		if dist <= 100.0:
			# Punish langsung dengan serangan
			_execute_attack()
			_whiff_punish_cooldown = 20
			return true
		elif dist <= 240.0 and _rng.randf() <= dash_punish_chance:
			# Dash mendekat untuk punish
			var dir_toward: float = 1.0 if opponent.global_position.x > mecha.global_position.x else -1.0
			mecha.set("simulated_horizontal_input", dir_toward)
			if mecha.has_method("trigger_simulated_action"):
				mecha.trigger_simulated_action(&"dash")
			_whiff_punish_cooldown = 30
			return true
	return false

func _process_spacing_and_approach() -> void:
	if _action_cooldown > 0:
		return

	var dist: float = absf(opponent.global_position.x - mecha.global_position.x)
	var dir_to_opp: float = 1.0 if opponent.global_position.x > mecha.global_position.x else -1.0

	# Manajemen Overclock khusus Ace
	if overclock_focus:
		var current_heat: float = mecha.get("heat_gauge") if ("heat_gauge" in mecha) else 0.0
		if current_heat > 95.0:
			# Mundur sejenak untuk pendinginan pasif
			mecha.set("simulated_horizontal_input", -dir_to_opp * 0.8)
			return

	if dist > (preferred_spacing + 50.0):
		# Di luar jangkauan: maju mendekat
		mecha.set("simulated_horizontal_input", dir_to_opp)
		if dist > 260.0 and _rng.randf() < (aggression * 0.4):
			if mecha.has_method("trigger_simulated_action"):
				mecha.trigger_simulated_action(&"dash")
				_action_cooldown = 25
	elif dist < (preferred_spacing - 25.0):
		# Terlalu dekat: sesekali mundur atau serang
		if _rng.randf() < aggression:
			_execute_attack()
		else:
			mecha.set("simulated_horizontal_input", -dir_to_opp * 0.6)
	else:
		# Berada di sweet-spot spacing: serang jika kesempatan terbuka
		mecha.set("simulated_horizontal_input", 0.0)
		if _rng.randf() < (aggression * 0.5):
			_execute_attack()

func _execute_attack() -> void:
	if not mecha or not mecha.has_method("trigger_simulated_action"):
		return

	# Cek apakah mecha sedang bisa menyerang
	var sm = mecha.get("state_machine")
	if sm and sm.get("current_state"):
		var cur_name: StringName = sm.current_state.name
		if cur_name != &"Idle" and cur_name != &"Walk":
			return

	# Pilih jurus berdasarkan profile & resource
	var ult_gauge: float = mecha.get("current_ultimate") if ("current_ultimate" in mecha) else 0.0
	var heat_val: float = mecha.get("heat_gauge") if ("heat_gauge" in mecha) else 0.0

	# Ace / Veteran: Pemicu Ultimate jika penuh (100) dan di Overclock Zone
	if difficulty == Difficulty.ACE and ult_gauge >= 100.0 and heat_val >= 80.0:
		mecha.trigger_simulated_action(&"ultimate")
		_action_cooldown = 40
		_combo_step = 0
		return

	# Pilihan Normal Light vs Normal Heavy
	if _rng.randf() < 0.6:
		mecha.trigger_simulated_action(&"attack_light")
		_combo_step = 1
	else:
		mecha.trigger_simulated_action(&"attack_heavy")
		_combo_step = 2

	_action_cooldown = 15

func _on_hit_confirmed(attacker_id: int, _defender_id: int, _hit_info: Dictionary) -> void:
	if not mecha or mecha.get_instance_id() != attacker_id:
		return

	# Lanjutkan Target Chain Cancel jika roll berhasil
	if _rng.randf() <= combo_extension_chance:
		_continue_combo_chain()

func _continue_combo_chain() -> void:
	if not mecha or not mecha.has_method("trigger_simulated_action"):
		return

	match _combo_step:
		1: # Setelah 5L -> Sambung ke 5H
			mecha.trigger_simulated_action(&"attack_heavy")
			_combo_step = 2
		2: # Setelah 5H -> Sambung ke Skill1
			mecha.trigger_simulated_action(&"skill1")
			_combo_step = 3
		3: # Setelah Skill -> Jika Ace & Ultimate siap -> Ultimate
			if difficulty == Difficulty.ACE:
				var ult: float = mecha.get("current_ultimate") if ("current_ultimate" in mecha) else 0.0
				if ult >= 100.0:
					mecha.trigger_simulated_action(&"ultimate")
			_combo_step = 0
		_:
			_combo_step = 0
