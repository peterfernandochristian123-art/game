class_name HeatComponent
extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## Komponen Thermal Engine: mengelola meteran panas mecha (0% - 100%)
## Kenaikan dari aksi (add_heat) dan pendinginan pasif deterministik per physics frame.

signal heat_changed(current: float, max_val: float)
signal overclock_state_changed(is_active: bool)
signal meltdown_triggered()

var current_heat: float = 0.0
var _is_overclocked: bool = false

func is_overclocked() -> bool:
	return _is_overclocked

## Menambah (atau mengurangi bila negatif) panas, dibatasi 0.0 - MAX_HEAT.
func add_heat(amount: float) -> void:
	var previous: float = current_heat
	current_heat = clampf(current_heat + amount, 0.0, CombatConstants.MAX_HEAT)
	if is_equal_approx(previous, current_heat):
		return
	heat_changed.emit(current_heat, CombatConstants.MAX_HEAT)

	_update_overclock_state()

	# Hook untuk Meltdown saat mencapai threshold 100.0%
	if current_heat >= CombatConstants.MELTDOWN_THRESHOLD and previous < CombatConstants.MELTDOWN_THRESHOLD:
		meltdown_triggered.emit()

func _update_overclock_state() -> void:
	var now_overclock: bool = (current_heat >= CombatConstants.OVERCLOCK_THRESHOLD and current_heat < CombatConstants.MELTDOWN_THRESHOLD)
	if now_overclock != _is_overclocked:
		_is_overclocked = now_overclock
		overclock_state_changed.emit(_is_overclocked)

## Dipanggil sekali per physics frame. Pendinginan pasif hanya bila can_cool == true.
func process_frame(can_cool: bool) -> void:
	if can_cool and current_heat > 0.0:
		add_heat(-CombatConstants.PASSIVE_COOLING_PER_FRAME)

func reset() -> void:
	add_heat(-CombatConstants.MAX_HEAT)
