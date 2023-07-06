extends Control

onready var info_label = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel
onready var fling_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/Fling/Button
onready var window_bg_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/BGWindowEffect/Button
onready var window_snap_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/WindowSnap/Button
onready var csec_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/CSec/Button
onready var color_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/ChangeColor/Button
onready var reset_color = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/ChangeColor/ResetColor
onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
onready var bg_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/Background/Button

func _ready():
	#info_label.text = info_label.text.replace("{app_path}", str(OS.get_user_data_dir() + "/apps/"))
	info_label.queue_free()
	
	description_label.text = description_label.text.replace("{version}", str(Global.version_full) + "." + str(Global.version_state))

func _process(delta):
	if Global.fling_enabled:
		fling_button.text = "Enabled"
	else:
		fling_button.text = "Disabled"
	
	if Global.bg_window_effect:
		window_bg_button.text = "Enabled"
	else:
		window_bg_button.text = "Disabled"
	
	if Global.window_snap:
		window_snap_button.text = "Enabled"
	else:
		window_snap_button.text = "Disabled"
	
	if Global.csec_enabled:
		csec_button.text = "Enabled"
	else:
		csec_button.text = "Disabled"
		
		bg_button.icon = Global.bg_texture
	
	color_button.color = Global.button_hover_color
	
	Global.save_settings()

func save():
	var save_dict = {
		"fling_enabled" : Global.fling_enabled,
		"bg_window_effect" : Global.bg_window_effect,
		"window_snap" : Global.window_snap,
		"clock_seconds_enabled" : Global.csec_enabled,
		"default_dl_path" : Global.default_dl_path,
		"desktop_background" : Global.desktop_background,
		"accent_color" : Global.button_hover_color
	}
	return save_dict

func _on_FlingButton_pressed():
	Global.fling_enabled = !Global.fling_enabled

func _on_WindowBGButton_pressed():
	Global.bg_window_effect = !Global.bg_window_effect

func _on_WindowSnapButton_pressed():
	Global.window_snap = !Global.window_snap

func _on_CSecButton_pressed():
	Global.csec_enabled = !Global.csec_enabled

func _on_ChangeBGButton_pressed():
	$BGDialog.popup_centered()

func _on_BGDialog_file_selected(path):
	var texture = create_image(path)
	Global.desktop_background = path
	Global.bg_texture = texture
	get_viewport().get_node("Desktop/Background").texture = texture
	bg_button.icon = texture

func _on_ResetBG_pressed():
	reset_background(false)

func _on_color_changed(color : Color):
	Global.button_hover_color = color
	Global.button_pressed_color = Color(
		clamp(color.r - 0.35, 0, 1),
		clamp(color.g - 0.35, 0, 1),
		clamp(color.b - 0.35, 0, 1)
	)

func _on_color_picked():
	var button_preset : Theme = load("res://resources/presets/GeneralButton.tres")
	Global.button_hover_style.bg_color = Global.button_hover_color
	Global.button_pressed_style.bg_color = Global.button_pressed_color
	button_preset.set_stylebox("hover", "Button", Global.button_hover_style)
	button_preset.set_stylebox("pressed", "Button", Global.button_pressed_style)
	if Global.button_hover_color.v > 0.5:
		button_preset.set_color("font_color_hover", "Button", Color(0,0,0,1))
	else:
		button_preset.set_color("font_color_hover", "Button", Color(1,1,1,1))
	if Global.button_pressed_color.v > 0.5:
		button_preset.set_color("font_color_pressed", "Button", Color(0,0,0,1))
	else:
		button_preset.set_color("font_color_pressed", "Button", Color(0.84,0.84,0.84,1))

func _on_ResetColor_pressed():
	color_button.color = Color(0, 1, 0.67, 1)
	Global.button_hover_color = Color(0, 1, 0.67, 1)
	Global.button_pressed_color = Color(0, 0.65, 0.43, 1)
	_on_color_picked()

func reset_background(error : bool):
	if !error:
		get_viewport().get_node("Desktop/Background").texture = Global.default_bg
		bg_button.icon = Global.default_bg
		Global.desktop_background =  "resources/textures/Backgrounds/DefaultBackground.png"
		Global.bg_texture = Global.default_bg
	else:
		get_viewport().get_node("Desktop/Background").texture = Global.corrupt_bg
		bg_button.icon = Global.corrupt_bg
		Global.desktop_background = "resources/textures/Backgrounds/CorruptedBackground.png"
		Global.bg_texture = Global.corrupt_bg
		return Global.corrupt_bg

func create_image(path : String):
	var bg_image = Image.new()
	var error = bg_image.load(path)
	if error != OK:
		return reset_background(true)
	var texture = ImageTexture.new()
	texture.create_from_image(bg_image)
	return texture
