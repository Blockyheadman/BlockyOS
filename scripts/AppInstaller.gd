extends Control

var user_path := OS.get_user_data_dir()
var apps : Array
var app_button = preload("res://scenes/InstalledAppButton.tscn")

onready var installed_apps_list = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/VBoxContainer/InstalledApps

func _ready():
	var installed_apps = File.new()
	var array_line = 0
	installed_apps.open(user_path + "/apps/installed-apps.txt", File.READ)
	
	while installed_apps.get_position() < installed_apps.get_len():
		var app_name = installed_apps.get_line()
		var app_dir = File.new()
		if app_dir.file_exists(user_path + "/apps/" + app_name + ".pck"):
			app_dir.close()
			apps.append(app_name)
		else:
			printerr("App doesn't seem to be installed to the system. Redownload the app and retry.")
		array_line = array_line + 1
	installed_apps.close()
	
	for i in apps.size():
		var instance = app_button.instance()
		instance.name = apps[i]
		print("BUTTON NAME: " + str(instance.name))
		instance.get_child(1).text = str(apps[i-1])
		instance.connect("RemovePressed", self, "remove_button")
		installed_apps_list.add_child(instance, true)
	
	$AppSelector.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)

func remove_button(button : String):
	var rm_file = Directory.new()
	rm_file.remove("user://apps/" + button + ".pck")
	get_viewport().get_node("Desktop").update_apps()
	installed_apps_list.get_node(button).queue_free()
	_on_Refresh_pressed()

func _on_Install_pressed():
	$AppSelector.popup_centered()

func _on_Refresh_pressed():
	apps.clear()
	
	var list : Array = installed_apps_list.get_children()
	for i in list.size():
		var button : Node = list[i]
		button.disconnect("RemovePressed", self, "remove_button")
		button.queue_free()
	list.clear()
	
	var installed_apps = File.new()
	var array_line = 0
	installed_apps.open(user_path + "/apps/installed-apps.txt", File.READ)
	
	while installed_apps.get_position() < installed_apps.get_len():
		var app_name = installed_apps.get_line()
		var app_dir = File.new()
		if app_dir.file_exists(user_path + "/apps/" + app_name + ".pck"):
			app_dir.close()
			apps.append(app_name)
		else:
			printerr("App doesn't seem to be installed to the system. Redownload the app and retry.")
		array_line = array_line + 1
	installed_apps.close()
	
	for i in apps.size():
		var instance = app_button.instance()
		instance.name = apps[i]
		print("BUTTON NAME: " + str(instance.name))
		instance.get_child(1).text = str(apps[i-1])
		instance.connect("RemovePressed", self, "remove_button")
		installed_apps_list.add_child(instance, true)

func _on_AppSelector_files_selected(paths : PoolStringArray):
	for i in paths:
		print(i)
		var file_name : String = i
		var file_array := file_name.split("/")
		file_name = file_array[file_array.size()-1]
		file_name.erase(file_name.length()-4, 4)
		print(file_name)
		
		var file = File.new()
		var new_file = File.new()
		file.open(i, File.READ)
		new_file.open("user://apps/" + file_name + ".pck", File.WRITE)
		while file.get_position() < file.get_len():
			new_file.store_64(file.get_64())
		file.close()
		new_file.close()
		get_viewport().get_node("Desktop").update_apps()
		_on_Refresh_pressed()
