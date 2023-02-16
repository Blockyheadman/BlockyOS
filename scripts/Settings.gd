extends Control

func _ready():
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer.queue_free()
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.text = """BlockyOS currently doesn't have any settings to retune. Sorry about that. But! It does have some info you need to know!

Currently, the OS doesn't support an app downloader. Hopefully it can in the future but for now that's something hard to work on. What you can do is go to\n""" + str(OS.get_user_data_dir() + "/apps/") + """\nand put apps into that folder. If you wanna create apps for the OS, I will have a guide sometime soon for it. Supported app files are .pck files and hopefully in the future, I'll make it so you have some apps built-in. You will need to use Godot 3.5.1 or newer to make apps for it. Godot 4 is not going to be supported.

Thanks for installing! :)
-- Blockyheadman"""
