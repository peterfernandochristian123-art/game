class_name BaseState
extends Node

## Class Abstrak untuk Seluruh State Mecha FSM
## Menyediakan siklus hidup deterministik: enter, exit, physics_update, handle_input

var character: CharacterBody2D = null
var state_machine: Node = null

## Dipanggil oleh StateMachine saat inisialisasi awal
func setup(p_character: CharacterBody2D, p_state_machine: Node) -> void:
	character = p_character
	state_machine = p_state_machine

## Dipanggil saat state dimasuki
func enter() -> void:
	pass

## Dipanggil saat state ditinggalkan
func exit() -> void:
	pass

## Dipanggil setiap tick _physics_process (60 FPS tetap)
func physics_update(_delta: float) -> void:
	pass

## Dipanggil saat ada input event yang belum terabsorpsi
func handle_input(_event: InputEvent) -> void:
	pass
