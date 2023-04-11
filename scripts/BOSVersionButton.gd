extends HBoxContainer
class_name BOSVersionButton

signal ButtonPressed

export var app_ver : String = "1.0.0"

func _on_Button_pressed():
	emit_signal("ButtonPressed", app_ver)
