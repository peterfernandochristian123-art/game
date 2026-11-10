class_name OnlineLobby
extends Control

## Lobi sederhana untuk multiplayer online (host/join ENet).

const MatchConfigScript = preload("res://scripts/core/match_config.gd")

@onready var ip_edit: LineEdit = $Panel/VBox/IPRow/IPEdit
@onready var port_edit: LineEdit = $Panel/VBox/PortRow/PortEdit
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var host_btn: Button = $Panel/VBox/Buttons/HostBtn
@onready var join_btn: Button = $Panel/VBox/Buttons/JoinBtn
@onready var back_btn: Button = $Panel/VBox/Buttons/BackBtn

var _net: Node = null

func _ready() -> void:
	_net = get_node_or_null("/root/NetworkManager")
	if host_btn:
		host_btn.pressed.connect(_on_host_pressed)
	if join_btn:
		join_btn.pressed.connect(_on_join_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	if ip_edit and ip_edit.text.is_empty():
		ip_edit.text = "127.0.0.1"
	if port_edit and port_edit.text.is_empty():
		port_edit.text = "8910"
	if _net:
		if not _net.connection_succeeded.is_connected(_on_connected_ok):
			_net.connection_succeeded.connect(_on_connected_ok)
		if not _net.connection_failed.is_connected(_on_failed):
			_net.connection_failed.connect(_on_failed)
		if not _net.server_disconnected.is_connected(_on_server_lost):
			_net.server_disconnected.connect(_on_server_lost)
		if not _net.peer_joined.is_connected(_on_peer_joined):
			_net.peer_joined.connect(_on_peer_joined)
	_set_status("Pilih HOST untuk buat room, atau JOIN untuk masuk ke host.")

func _set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

func _get_port() -> int:
	if port_edit:
		return int(port_edit.text)
	return 8910

func _on_host_pressed() -> void:
	if not _net:
		_set_status("NetworkManager tidak ditemukan (autoload).")
		return
	var port := _get_port()
	var err = _net.host_game(port)
	if err == OK:
		MatchConfigScript.set_mode(&"online")
		_set_status("Hosting di port %d... menunggu pemain lain." % port)
	else:
		_set_status("Gagal host: %s" % err)

func _on_join_pressed() -> void:
	if not _net:
		_set_status("NetworkManager tidak ditemukan (autoload).")
		return
	var addr: String = ip_edit.text.strip_edges() if ip_edit else "127.0.0.1"
	var port := _get_port()
	var err = _net.join_game(addr, port)
	if err == OK:
		MatchConfigScript.set_mode(&"online")
		_set_status("Menghubungkan ke %s:%d..." % [addr, port])
	else:
		_set_status("Gagal join: %s" % err)

func _on_connected_ok() -> void:
	_set_status("Terhubung! Memulai match online...")
	_start_online_match()

func _on_peer_joined(_id: int) -> void:
	if _net and _net.is_host:
		_set_status("Pemain bergabung! Memulai match online...")
		await get_tree().create_timer(0.5).timeout
		_start_online_match()

func _on_failed(reason: String) -> void:
	_set_status("Koneksi gagal: %s" % reason)

func _on_server_lost() -> void:
	_set_status("Server terputus.")

func _start_online_match() -> void:
	if multiplayer.is_server():
		rpc("_rpc_start_match")
	_go_to_match()

@rpc("authority", "call_local", "reliable")
func _rpc_start_match() -> void:
	_go_to_match()

func _go_to_match() -> void:
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/online_versus_mode.tscn")

func _on_back_pressed() -> void:
	if _net:
		_net.reset_connection()
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/main_menu.tscn")
