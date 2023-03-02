extends Control

onready var fling_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/Fling/Button
onready var window_bg_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/BGWindowEffect/Button
onready var window_snap_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/WindowSnap/Button
onready var csec_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/CSec/Button

func _ready():
	#$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer.queue_free()
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.text = """Currently, the OS doesn't support an app downloader. Hopefully it can in the future but for now that's something hard to work on. What you can do is go to\n""" + str(OS.get_user_data_dir() + "/apps/") + """\nand put apps into that folder. If you wanna create apps for the OS, I will have a guide sometime soon for it. Supported app files are .pck files and hopefully in the future, I'll make it so you have some apps built-in. You will need to use Godot 3.5.1 or newer to make apps for it. Godot 4 is not going to be supported.

Thanks for installing! :)
-- Blockyheadman"""
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.queue_free()
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
	
	Global.save_settings()

func save():
	var save_dict = {
		"fling_enabled" : Global.fling_enabled,
		"bg_window_effect" : Global.bg_window_effect,
		"window_snap" : Global.window_snap,
		"clock_seconds_enabled" : Global.csec_enabled
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
