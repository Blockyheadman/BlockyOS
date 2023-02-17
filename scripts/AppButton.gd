extends Button

signal button_pressed

func _ready():
	print(get_node(".").get_parent().get_parent().get_name())

func _on_Button_pressed():
	var button_root = get_parent().get_parent()
	var button_name = button_root.get_name()
	print(str(button_name) + " app button pressed")
	emit_signal("button_pressed", button_root)

func _on_Button_mouse_entered():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(get_parent().get_parent(), "rect_size", Vector2(68,100), 0.4)

func _on_Button_mouse_exited():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(get_parent().get_parent(), "rect_size", Vector2(64,96), 0.4)
