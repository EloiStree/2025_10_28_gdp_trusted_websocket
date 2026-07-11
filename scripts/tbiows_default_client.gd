extends Node
class_name TbioWsDefaultClient

signal connected()
signal disconnected(code: int, reason: String)

signal received_text(message: String)
signal received_byte(data: PackedByteArray)

signal sent_text(message: String)
signal sent_byte(data: PackedByteArray)

signal connection_error(error: Error)


var _ws := WebSocketPeer.new()

@export var _host := "127.0.0.1"
@export var _port := 3616
@export var  RECONNECT_INTERVAL := 3.0

var _connected := false
var _reconnect_timer := 0.0


func _process(delta: float) -> void:
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_CONNECTING or state == WebSocketPeer.STATE_OPEN:
		_ws.poll()
		state = _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:

		if !_connected:
			_connected = true
			print("Connected to ", _host, ":", _port)
			connected.emit()

		while _ws.get_available_packet_count() > 0:
			var packet := _ws.get_packet()

			if _ws.was_string_packet():
				received_text.emit(packet.get_string_from_utf8())
			else:
				received_byte.emit(packet)

	elif state == WebSocketPeer.STATE_CLOSED:

		if _connected:
			_connected = false
			disconnected.emit(_ws.get_close_code(), _ws.get_close_reason())

		_reconnect_timer += delta

		if _reconnect_timer >= RECONNECT_INTERVAL:
			_reconnect_timer = 0.0
			_connect()

	elif state == WebSocketPeer.STATE_CONNECTING:
		_reconnect_timer = 0.0


func start(ipv4: String, port: int = 3616) -> void:
	_host = ipv4
	_port = port
	_connect()


func _connect() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		return

	_ws = WebSocketPeer.new()

	var err := _ws.connect_to_url("ws://%s:%d" % [_host, _port])

	if err != OK:
		connection_error.emit(err)
		print("Connection failed: ", err)
	else:
		print("Connecting to ", _host, ":", _port)


func disconnect_from_server() -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.close(1000, "Client disconnect")


func send_text(text: String) -> Error:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNCONFIGURED

	var err := _ws.send_text(text)

	if err == OK:
		sent_text.emit(text)

	return err


func send_byte(data: PackedByteArray) -> Error:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNCONFIGURED

	var err := _ws.send(data)

	if err == OK:
		sent_byte.emit(data)

	return err


func push_random_ssd1306() -> void:
	var bytes := PackedByteArray()
	bytes.resize(1024)
	for i in 1024:
		bytes[i] = randi() % 256
	send_byte(bytes)
