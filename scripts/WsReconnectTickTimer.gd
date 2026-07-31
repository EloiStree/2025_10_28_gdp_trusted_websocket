class_name WsReconnectTickTimer
extends Node

## How often (seconds) the tick signal is emitted.
@export var interval: float = 5.0

## Start automatically when the node enters the scene tree.
@export var autostart: bool = true

## Emitted every `interval` seconds.
signal tick()

# Internal
var _timer: float = 0.0
var _running: bool = false


func _ready() -> void:
	_reset_timer()
	if autostart:
		start()


func _process(delta: float) -> void:
	if not _running:
		return

	_timer -= delta
	if _timer <= 0.0:
		emit_signal("tick")
		_reset_timer()


# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────
func start() -> void:
	if _running:
		return
	_running = true
	_reset_timer()


func stop() -> void:
	_running = false


func restart() -> void:
	stop()
	start()


func set_interval_and_restart(new_interval: float) -> void:
	interval = max(0.01, new_interval)
	restart()


# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE
# ─────────────────────────────────────────────────────────────────────────────
func _reset_timer() -> void:
	_timer = interval
