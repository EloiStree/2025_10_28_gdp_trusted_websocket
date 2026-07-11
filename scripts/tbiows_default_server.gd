class_name TbioWsDefaultServer
extends Node

# Custom signals to notify other nodes
signal on_client_connected(peer_id: int)
signal on_client_disconnected(peer_id: int, code: int, reason: String)
signal on_received_from_client_text(peer_id: int, message: String)
signal on_received_from_client_byte(peer_id: int, data: PackedByteArray)

signal on_send_from_server_to_client_text(text:String)
signal on_send_from_server_to_client_byte( data: PackedByteArray)

# The port we will listen to.
const PORT = 3616

# Our TCP Server instance.
var _tcp_server = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id := 1


func _ready():
	# Start listening on the given port.
	var err = _tcp_server.listen(PORT)
	if err == OK:
		print("Server started on port %d." % PORT)
	else:
		push_error("Unable to start server.")
		set_process(false)


func _process(_delta):
	# Accept new connections
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		print("+ Peer %d connected." % last_peer_id)
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
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
					print("< Got text data from peer %d: %s" % [peer_id, packet_text])
					on_received_from_client_text.emit(peer_id, packet_text)
				else:
					print("< Got binary data from peer %d: %d bytes" % [peer_id, packet.size()])
					on_received_from_client_byte.emit(peer_id, packet)
					
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
	


func _on_timer_timeout() -> void:
	pass # Replace with function body.
