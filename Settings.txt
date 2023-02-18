extends Control

onready var fling_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/Settings/Fling/Button

func _ready():
	#$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer.queue_free()
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.text = """Currently, the OS doesn't support an app downloader. Hopefully it can in the future but for now that's something hard to work on. What you can do is go to\n""" + str(OS.get_user_data_dir() + "/apps/") + """\nand put apps into that folder. If you wanna create apps for the OS, I will have a guide sometime soon for it. Supported app files are .pck files and hopefully in the future, I'll make it so you have some apps built-in. You will need to use Godot 3.5.1 or newer to make apps for it. Godot 4 is not going to be supported.

Thanks for installing! :)
-- Blockyheadman"""
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.queue_free()
	
	if Global.fling_enabled:
		fling_button.text = "Enabled"
	else:
		fling_button.text = "Disabled"

func _on_FlingButton_pressed():
	Global.fling_enabled = !Global.fling_enabled
	
	if Global.fling_enabled:
		fling_button.text = "Enabled"
	else:
		fling_button.text = "Disabled"
