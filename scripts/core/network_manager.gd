class_name NetworkManager
extends Node

## Autoload: manajemen koneksi multiplayer online (ENet, host/join internet/LAN).

signal connection_succeeded()
signal connection_failed(reason: String)
signal server_disconnected()
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 8910
const MAX_CLIENTS: int = 1

var peer: ENetMultiplayerPeer = null
var is_online_match: bool = false
var is_host: bool = false
var local_player_index: int = 1 # 1 = host, 2 = client

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
	reset_connection()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_warning("[NET] Gagal membuat server: %s" % err)
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	is_online_match = true
	is_host = true
	local_player_index = 1
	print("[NET] Hosting on port %d" % port)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	reset_connection()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_warning("[NET] Gagal membuat client: %s" % err)
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	is_online_match = true
	is_host = false
	local_player_index = 2
	print("[NET] Joining %s:%d" % [address, port])
	return OK

func reset_connection() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	is_online_match = false
	is_host = false
	local_player_index = 1

func _on_peer_connected(id: int) -> void:
	print("[NET] Peer connected: %d" % id)
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NET] Peer disconnected: %d" % id)
	peer_left.emit(id)

func _on_connected_to_server() -> void:
	print("[NET] Connected to server")
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	push_warning("[NET] Connection failed")
	connection_failed.emit("Connection failed")
	reset_connection()

func _on_server_disconnected() -> void:
	push_warning("[NET] Server disconnected")
	server_disconnected.emit()
	reset_connection()

func is_network_active() -> bool:
	return is_online_match and multiplayer.multiplayer_peer != null
