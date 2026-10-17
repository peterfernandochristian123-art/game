extends Node

## Input Buffer Singleton untuk Fighting to Zero
## Menyediakan antrean input circular buffer 5-frame (83.3 ms pada 60 FPS)
## Mendukung abstraksi kontrol PC (Gamepad/Keyboard) dan Mobile Touch

class BufferedInput:
	var action: StringName
	var vector: Vector2
	var frame_timestamp: int

	func _init(p_action: StringName = &"", p_vector: Vector2 = Vector2.ZERO, p_frame: int = 0) -> void:
		action = p_action
		vector = p_vector
		frame_timestamp = p_frame

const BUFFER_WINDOW_FRAMES: int = 5

var current_frame: int = 0
var buffer_queue: Array[BufferedInput] = []

func _ready() -> void:
	if OS.is_debug_build():
		print("[INPUT] Global InputBuffer Autoload diinisialisasi (Buffer window: %d frame)." % BUFFER_WINDOW_FRAMES)

func _physics_process(_delta: float) -> void:
	current_frame += 1
	_prune_expired_inputs()

func buffer_action(action_name: StringName, direction_vector: Vector2 = Vector2.ZERO) -> void:
	var item := BufferedInput.new(action_name, direction_vector, current_frame)
	buffer_queue.append(item)

func consume_action(action_name: StringName) -> bool:
	for i in range(buffer_queue.size() - 1, -1, -1):
		if buffer_queue[i].action == action_name:
			buffer_queue.remove_at(i)
			return true
	return false

func consume_action_with_data(action_name: StringName) -> Dictionary:
	for i in range(buffer_queue.size() - 1, -1, -1):
		if buffer_queue[i].action == action_name:
			var item: BufferedInput = buffer_queue[i]
			var data := {
				"action": item.action,
				"vector": item.vector,
				"frame": item.frame_timestamp
			}
			buffer_queue.remove_at(i)
			return data
	return {}

func has_action(action_name: StringName) -> bool:
	for item in buffer_queue:
		if item.action == action_name:
			return true
	return false

func clear_buffer() -> void:
	buffer_queue.clear()

func _prune_expired_inputs() -> void:
	var cutoff_frame: int = current_frame - BUFFER_WINDOW_FRAMES
	while not buffer_queue.is_empty() and buffer_queue[0].frame_timestamp < cutoff_frame:
		buffer_queue.pop_front()
