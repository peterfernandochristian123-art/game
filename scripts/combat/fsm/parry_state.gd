class_name ParryState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat mengeksekusi Spark Parry (Tangkisan Presisi Baja)
## Jendela Aktif: Frame 2..5 (4 frame aktif)
## Whiff Recovery: Frame 6..19 (14 frame rentan Counter-Hit)
## Total Whiff: 19 frame, kembali ke Idle pada frame 20

var current_frame_in_state: int = 0
var parry_succeeded: bool = false

func enter() -> void:
	current_frame_in_state = 0
	parry_succeeded = false
	if character:
		character.velocity.x = 0.0
	if OS.is_debug_build():
		print("[STATE][%s] Memasuki ParryState (Spark Parry)." % (character.name if character else "Unknown"))

func exit() -> void:
	current_frame_in_state = 0
	parry_succeeded = false

func physics_update(_delta: float) -> void:
	if not character:
		return

	# Mecha harus tetap di darat selama parry
	if not character.is_on_floor():
		state_machine.change_state(&"Fall")
		return

	current_frame_in_state += 1

	# Setelah 19 frame whiff selesai, kembali ke Idle
	if current_frame_in_state > CombatConstants.SPARK_PARRY_TOTAL_FRAMES:
		state_machine.change_state(&"Idle")

## Mengembalikan true jika saat ini berada pada frame aktif tangkisan (Frame 2 hingga Frame 5)
func is_parry_active() -> bool:
	return (
		current_frame_in_state >= (CombatConstants.SPARK_PARRY_STARTUP_FRAMES + 1)
		and current_frame_in_state <= (CombatConstants.SPARK_PARRY_STARTUP_FRAMES + CombatConstants.SPARK_PARRY_ACTIVE_FRAMES)
	)

## Mengembalikan true jika saat ini mecha dalam kondisi recovery whiff dan rentan Counter-Hit (Frame 6 hingga 19)
func is_counter_hit_vulnerable() -> bool:
	var start_recovery: int = CombatConstants.SPARK_PARRY_STARTUP_FRAMES + CombatConstants.SPARK_PARRY_ACTIVE_FRAMES + 1
	return (
		current_frame_in_state >= start_recovery
		and current_frame_in_state <= CombatConstants.SPARK_PARRY_TOTAL_FRAMES
	)

## Menangani benturan serangan musuh saat parry aktif
## Mengembalikan true jika parry sukses menyerap dan membatalkan serangan
func handle_parry_hit(attacker: Node2D, _hit_data: Dictionary) -> bool:
	if not is_parry_active():
		return false

	parry_succeeded = true

	# 1. Bekukan (hitstop) penyerang selama 12 frame
	if attacker and attacker.has_method("apply_hitstop"):
		attacker.apply_hitstop(CombatConstants.SPARK_PARRY_HITSTOP_FRAMES)

	var bus = character.get_node_or_null("/root/EventBus")
	if is_instance_valid(bus):
		bus.hitstop_requested.emit(CombatConstants.SPARK_PARRY_HITSTOP_FRAMES)
		bus.parry_triggered.emit(character, attacker)
	elif is_instance_valid(EventBus):
		EventBus.hitstop_requested.emit(CombatConstants.SPARK_PARRY_HITSTOP_FRAMES)
		EventBus.parry_triggered.emit(character, attacker)

	# 2. Curi 15% Ultimate meter lawan
	if attacker and attacker.has_method("drain_ultimate"):
		attacker.drain_ultimate(CombatConstants.SPARK_PARRY_ULTIMATE_STEAL)
	if character and character.has_method("add_ultimate"):
		character.add_ultimate(CombatConstants.SPARK_PARRY_ULTIMATE_STEAL)

	# 3. Pendinginan suhu termal mecha sendiri sebesar -20%
	if character and character.has_method("add_heat"):
		character.add_heat(-CombatConstants.SPARK_PARRY_HEAT_COOLING)
	elif character and character.get("heat_component"):
		character.heat_component.add_heat(-CombatConstants.SPARK_PARRY_HEAT_COOLING)

	# 4. Berikan perlindungan invulnerability 12 frame pada mecha penyerap
	if character and character.has_method("grant_invulnerability"):
		character.grant_invulnerability(CombatConstants.SPARK_PARRY_HITSTOP_FRAMES)

	if OS.is_debug_build():
		print("[COMBAT][%s] SPARK PARRY SUKSES! Musuh dibekukan 12 frame, -20%% Heat, curi 15%% Ultimate!" % character.name)

	# 5. Selesai parry: Mecha langsung kembali ke kondisi netral (Idle) dengan inisiatif penuh
	if state_machine:
		state_machine.change_state(&"Idle")

	return true
