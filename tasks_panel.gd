extends Control

var is_open := true

func _on_ToggleButton_pressed():
	is_open = !is_open
	visible = is_open
