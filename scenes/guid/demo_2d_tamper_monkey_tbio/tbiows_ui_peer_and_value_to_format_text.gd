class_name TbioWsUiPeerAndValueToFormatText
extends Node

signal on_text_formated_to_display(text:String)

@export var _display_format:String = "Peer %s: %s"
@export_group("For Debugging")
@export var _label_to_display:Label
@export var _text_edit_to_display:TextEdit


func push_in_peer_and_value_to_format_text(peer_id:int, value_to_format:String) -> void:
	var text:String = _display_format % [peer_id, value_to_format]
	on_text_formated_to_display.emit(text)
	if _label_to_display:
		_label_to_display.text = text
	if _text_edit_to_display:
		_text_edit_to_display.text = text
