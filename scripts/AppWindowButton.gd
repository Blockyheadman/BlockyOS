extends Button

signal button_pressed

var panel_selected = load("res://resources/presets/AppButtonSelected.tres")
var panel_unselected = load("res://resources/presets/AppButtonUnselected.tres")

func _ready():
	var desktop = get_parent().get_parent().get_parent().get_parent().get_parent()
	desktop.connect("close_app_window_button", self, "_on_window_closed")
	print(get_parent().get_name())

func _on_Button_toggled(button_pressed):
	var button_root = get_node(".").get_parent()
	var button_name = button_root.get_name()
	print(str(button_name) + " window button pressed")
	emit_signal("button_pressed", button_root, true)

func _on_window_closed(app_name):
	print("recieved signal from " + app_name)
	if get_parent().name == app_name:
		pass
		get_parent().queue_free()

func _window_visibility(visibility):
	if visibility == true:
		get_parent().get_child(1).add_stylebox_override("Panel", panel_selected)
	else:
		get_parent().get_child(1).add_stylebox_override("Panel", panel_unselected)

func _on_Button_mouse_entered():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(get_parent().get_node("Panel"), "rect_position", Vector2(6, 40), 0.25)
	tween.parallel().tween_property(get_parent().get_node("Panel"), "rect_size", Vector2(28, 8), 0.25)

func _on_Button_mouse_exited():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(get_parent().get_node("Panel"), "rect_position", Vector2(8, 40), 0.25)
	tween.parallel().tween_property(get_parent().get_node("Panel"), "rect_size", Vector2(24, 8), 0.25)
