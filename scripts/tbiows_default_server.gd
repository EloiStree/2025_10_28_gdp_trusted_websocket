class_name TbioWsDefaultServer
extends Node

# Custom signals to notify other nodes
signal on_client_connected(peer_id: int)
signal on_client_disconnected(peer_id: int, code: int, reason: String)
signal on_received_from_client_text(peer_id: int, message: String)
signal on_received_from_client_byte(peer_id: int, data: PackedByteArray)
signal on_received_from_client_text_with_ip(ipv4: String, message: String)
signal on_received_from_client_byte_with_ip(ipv4: String, data: PackedByteArray)
signal on_received_from_client_text_anonym( message: String)
signal on_received_from_client_byte_anonym( data: PackedByteArray)

signal on_send_from_server_to_client_text(text:String)
signal on_send_from_server_to_client_byte( data: PackedByteArray)

# The port we will listen to.
@export var _port = 3616
@export var _listen_interface :String ="0.0.0.0"
# Our TCP Server instance.
var _tcp_server = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id := 1

@export var _auto_start_server_at_ready: bool = true

func _ready():
	if _auto_start_server_at_ready:
		start_server()

func set_ip_and_port_then_start_server(ip_mask:String,port:int):
	self.set_ip_mask_interface(ip_mask)
	self.set_port_and_start_server(port)

func set_port_and_start_server(port: int) -> void:
	_port = port
	start_server()

func set_ip_mask_interface(mask_interface: String="0.0.0.0") -> void:
	_listen_interface = mask_interface

func set_port(port: int) -> void:
	_port = port

func start_server() -> void:
	# Start listening on the given port.
	var err = _tcp_server.listen(_port,_listen_interface)
	if err == OK:
		print("Server started on port %d." % _port)
	else:
		push_error("Unable to start server.")
		set_process(false)

@export var _use_print_peer_connected:bool = true
@export var _use_print_package_received_for_debug:bool=false

func _process(_delta):
	# Accept new connections
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		var connection = _tcp_server.take_connection()
		var peer_ip = connection.get_connected_host()
		var peer_port = connection.get_connected_port()
		
		if _use_print_peer_connected:
			print("+ Peer %d connected." % last_peer_id)
			print("  - IP: %s" % peer_ip)
			print ("  - Port: %d" % peer_port)
			print ("  - Peer ID: %d" % last_peer_id)
			print ("  - Total connected: %d" % (_peers.size() + 1))

		var ws = WebSocketPeer.new()
		ws.accept_stream(connection)
		_peers[last_peer_id] = ws
		on_client_connected.emit(last_peer_id)

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]

		peer.poll()

		var peer_state = peer.get_ready_state()
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var packet = peer.get_packet()
				if peer.was_string_packet():
					var packet_text = packet.get_string_from_utf8()
					if _use_print_package_received_for_debug:
						print("< Got text data from peer %d: %s" % [peer_id, packet_text])
					on_received_from_client_text.emit(peer_id, packet_text)
					on_received_from_client_text_anonym.emit(packet_text)
					on_received_from_client_text_with_ip.emit(peer.get_connected_host(), packet_text)
				else:
					if _use_print_package_received_for_debug:
						print("< Got binary data from peer %d: %d bytes" % [peer_id, packet.size()])
					on_received_from_client_byte.emit(peer_id, packet)
					on_received_from_client_byte_anonym.emit(packet)
					on_received_from_client_byte_with_ip.emit(peer.get_connected_host(), packet)
					
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			var code = peer.get_close_code()
			var reason = peer.get_close_reason()
			print("- Peer %s closed with code: %d, reason %s. Clean: %s" % [peer_id, code, reason, code != -1])
			on_client_disconnected.emit(peer_id, code, reason)


# --- Broadcasting Functions ---

func broadcast_text(message: String) -> void:
	for peer_id in _peers:
		var peer = _peers[peer_id]
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer.send_text(message)
	on_send_from_server_to_client_text.emit(message)

func broadcast_byte(data: PackedByteArray) -> void:
	for peer_id in _peers:
		var peer = _peers[peer_id]
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer.send(data)
	on_send_from_server_to_client_byte.emit(data)
	

func broadcast_ping_and_random():
	broadcast_ping()
	broadcast_random_integer()

func broadcast_ping():
	broadcast_text("ping")
	
func broadcast_random_integer():
	var bytes := PackedByteArray()
	bytes.append(randi() % 256)
	broadcast_byte(bytes)
