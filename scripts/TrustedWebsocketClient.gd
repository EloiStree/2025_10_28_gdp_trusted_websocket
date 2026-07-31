@tool
class_name TrustedWebSocketClient
extends Node

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG (editable in the inspector)
# ─────────────────────────────────────────────────────────────────────────────
@export var websocket_url: String = "ws://127.0.0.1:4513"
@export var use_secure_connection: bool = false : set = _set_use_secure

## Text sent automatically after successful connection.
@export_multiline var hello_message: String = "HELLO"

## READ-ONLY: true when socket is OPEN
@export var is_connected: bool = false : set = _set_is_connected

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────
signal text_received(message: String)
signal bytes_received(data: PackedByteArray)
signal connected()
signal disconnected(code: int, reason: String)
signal connection_error(error: int)

# ─────────────────────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────────────────────
var _socket: WebSocketPeer = null
var _has_sent_hello: bool = false

# ─────────────────────────────────────────────────────────────────────────────
# GODOT CALLBACKS
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_create_socket()
	_connect_to_server()
	set_process(true)

func _process(_delta: float) -> void:
	if not _socket:
		return

	_socket.poll()
	var state = _socket.get_ready_state()

	# Update exported flag
	_set_is_connected(state == WebSocketPeer.STATE_OPEN)

	match state:
		WebSocketPeer.STATE_OPEN:
			_handle_incoming()

			# Send hello once
			if not _has_sent_hello and hello_message.strip_edges() != "":
				_has_sent_hello = true
				if push_text(hello_message):
					print("[TrustedWebSocketClient] Sent hello: ", hello_message)

			# First time we go OPEN
			if not is_connected:
				emit_signal("connected")
				print("[TrustedWebSocketClient] Connected!")

		WebSocketPeer.STATE_CONNECTING:
			pass

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			emit_signal("disconnected", code, reason)
			print("[TrustedWebSocketClient] Disconnected: ", code, " - ", reason)
			_cleanup_socket()

func _exit_tree() -> void:
	close_connection(1001, "Node removed")

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────
## Send text message (returns true on success)
func push_text(message: String) -> bool:
	if not _is_open():
		push_warning("push_text(): socket not open")
		return false
	var err = _socket.send_text(message)
	if err != OK:
		push_error("Failed to send text: " + error_string(err))
	return err == OK

## Send binary data
func push_bytes(data: PackedByteArray) -> bool:
	if not _is_open():
		push_warning("push_bytes(): socket not open")
		return false
	var err = _socket.send(data)
	if err != OK:
		push_error("Failed to send bytes: " + error_string(err))
	return err == OK

## Close the connection cleanly
func close_connection(code: int = 1000, reason: String = "") -> void:
	if _socket and _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close(code, reason)
	_has_sent_hello = false

## **NEW METHOD**: Check if connected → reconnect if not
func ensure_connected() -> void:
	if _is_open():
		return  # already good

	print("[TrustedWebSocketClient] Not connected → forcing reconnect...")
	_connect_to_server()

# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _create_socket() -> void:
	if _socket:
		_socket = null
	_socket = WebSocketPeer.new()

func _connect_to_server() -> void:
	var url = _format_url()
	print("[TrustedWebSocketClient] Connecting to ", url)

	_create_socket()
	_has_sent_hello = false
	var err = _socket.connect_to_url(url)
	if err != OK:
		push_error("Connection failed: " + error_string(err))
		emit_signal("connection_error", err)
		_cleanup_socket()

func _format_url() -> String:
	var url = websocket_url.strip_edges()
	if use_secure_connection:
		if not url.begins_with("wss://"):
			url = "wss://" + url.lstrip("ws://").lstrip("wss://")
	else:
		if not url.begins_with("ws://"):
			url = "ws://" + url.lstrip("ws://").lstrip("wss://")
	return url

func _handle_incoming() -> void:
	while _socket.get_available_packet_count() > 0:
		var packet = _socket.get_packet()
		if _socket.was_string_packet():
			emit_signal("text_received", packet.get_string_from_utf8())
		else:
			emit_signal("bytes_received", packet)

func _cleanup_socket() -> void:
	if _socket:
		_socket = null
	_set_is_connected(false)

func _is_open() -> bool:
	return _socket != null && _socket.get_ready_state() == WebSocketPeer.STATE_OPEN

# ─────────────────────────────────────────────────────────────────────────────
# EXPORT SETTERS
# ─────────────────────────────────────────────────────────────────────────────
func _set_is_connected(value: bool) -> void:
	if is_connected != value:
		is_connected = value
		if Engine.is_editor_hint():
			property_list_changed.emit()

func _set_use_secure(value: bool) -> void:
	use_secure_connection = value
	if Engine.is_editor_hint():
		property_list_changed.emit()
