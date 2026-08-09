class_name TBIoWsUIFourByteToInteger
extends Node


signal on_integer_found(integer_found:int)
signal on_integer_found_as_string(integer_found_as_string:String)

@export var _last_integer_found:int

func push_in_byte_to_be_parsed_with_peer(peer : int,packed_byte_array:PackedByteArray):
	push_in_byte_to_be_parsed(packed_byte_array)

func push_in_byte_to_be_parsed(packed_byte_array:PackedByteArray):
	var integer_found:int = 0
	if packed_byte_array.size() == 4:
		integer_found = packed_byte_array[3] << 24 | packed_byte_array[2] << 16 | packed_byte_array[1] << 8 | packed_byte_array[0]
		_last_integer_found = integer_found

		emit_signal("on_integer_found", integer_found)
		emit_signal("on_integer_found_as_string", str(integer_found))
