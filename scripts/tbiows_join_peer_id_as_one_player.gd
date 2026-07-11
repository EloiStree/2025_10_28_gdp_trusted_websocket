class_name TbioWsJoinPeersIdAsOnePeer
extends Node

signal on_received_text(text: String)
signal on_received_byte(byte_array: PackedByteArray)

func push_in_received_text(text: String) -> void:
	on_received_text.emit(text)

func push_in_received_byte(byte_array: PackedByteArray) -> void:
	on_received_byte.emit(byte_array)

func push_in_received_text_with_peer_id(peer: int, text: String) -> void:
	on_received_text.emit(text)

func push_in_received_byte_with_peer_id(peer: int, byte_array: PackedByteArray) -> void:
	on_received_byte.emit(byte_array)
