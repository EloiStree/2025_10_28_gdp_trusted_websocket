class_name BytesToDebugLabels
extends Node

@export var debug_label_text: Label
@export var debug_label_bytes_count: Label
@export var debug_label_bytes_description: Label
@export var debug_label_iid_index: Label
@export var debug_label_iid_value: Label
@export var debug_label_iid_date: Label


func push_text(given_text: String) -> void:
	debug_label_text.text = given_text


func push_bytes(given_bytes: PackedByteArray) -> void:
	debug_label_bytes_count.text = str(given_bytes.size())
	debug_label_bytes_description.text = _bytes_to_hex_string(given_bytes)

	if given_bytes.size() == 16:
		# 32-bit index
		var index := given_bytes.decode_s32(0)
		debug_label_iid_index.text = str(index)

		# 32-bit value
		var value := given_bytes.decode_s32(4)
		debug_label_iid_value.text = str(value)

		# 64-bit unsigned (e.g., timestamp)
		var u64_value := given_bytes.decode_u64(8)
		debug_label_iid_date.text = str(u64_value)  # or format if it's a timestamp
	else:
		debug_label_iid_index.text = "N/A"
		debug_label_iid_value.text = "N/A"
		debug_label_iid_date.text = "N/A"


# Utility: convert bytes to a spaced hex string
func _bytes_to_hex_string(bytes: PackedByteArray) -> String:
	var out := []
	for b in bytes:
		out.append("%02X" % b)
	return " ".join(out)
