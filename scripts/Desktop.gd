extends Control

signal close_app_window_button

var window_anim_playable = true
var user_path = OS.get_user_data_dir()
var apps : Array

func _ready():
	$StartMenu/VBoxContainer/DownloadApps.queue_free()
	$StartMenu/VBoxContainer/UpdateApps.set_v_size_flags(0)
	OS.min_window_size = Vector2(640,360)
	
	if OS.has_feature("debug"):
		$DebugTools.visible = true
		$DebugTools/GridContainer/WriteInstalledApps.queue_free()
		$DebugTools/GridContainer/RefreshApps.queue_free()
	elif OS.has_feature("release"):
		$DebugTools.queue_free()
	
	$DebugTools.queue_free()
	
	#$DebugTools.visible = false # override for editor purposes
	$StartMenu.visible = false
	$StartMenu.rect_size = Vector2(224, 0)
	$StartMenu.rect_position = Vector2(0, get_viewport_rect().size.y+20)
	$StartMenu.modulate = Color(1,1,1,0)
	print("User OS Path: " + str(user_path))
	var file = File.new()
	if !file.file_exists(user_path + "/apps/installed-apps.txt"):
		file.open(user_path + "/apps/installed-apps.txt", File.WRITE)
		file.store_string("")
		file.close()
	update_apps()
	print("\nApps installed: " + str(apps))
	pass

# removes all nodes from the AppsGridContainer
func clear_app_buttons():
	for i in apps.size():# - 1:
		if has_node("AppsGridContainer/" + str(apps[i])):
			var button_path = get_node("AppsGridContainer/" + apps[i]).get_path()
			print("removing node: " + str(get_node("AppsGridContainer").get_node(apps[i])))
			print(get_node("AppsGridContainer/" + apps[i]))
			get_node(button_path).queue_free()
			print(get_node("AppsGridContainer/" + apps[i]))

# resets the AppsGridContainer and creates new buttons for each app.
func refresh_app_list():
	var installed_apps = File.new()
	var array_line = 0
	
	clear_app_buttons()
	yield(get_tree().create_timer(.1), "timeout")
	
	apps.clear()
	
	installed_apps.open(user_path + "/apps/installed-apps.txt", File.READ)
	while installed_apps.get_position() < installed_apps.get_len():
		print("\nArray Line: " + str(array_line))
		var node_data = installed_apps.get_line()
		apps.append(node_data)
		print("Found installed app: " + str(node_data))
		print("Grabbing files from: " + user_path + "/apps/" + node_data)
		var app_dir = File.new()
		if app_dir.file_exists(user_path + "/apps/" + node_data + ".pck"):
			print("Node Name: " + str(get_node("AppsGridContainer").get_child(array_line)))
			#if !get_node("AppsGridContainer").get_child(array_line):
			if !has_node("AppsGridContainer/" + node_data):
				var button_scene = load("res://scenes/AppButton.tscn")
				var instanced_button : Node = button_scene.instance()
				get_node("AppsGridContainer").add_child(instanced_button)
				instanced_button.name = node_data
				instanced_button.get_child(0).get_child(1).text = node_data
				instanced_button.get_child(0).get_child(0).flat = true
				instanced_button.get_child(0).get_child(0).text = ""
				instanced_button.get_child(0).get_child(0).hint_tooltip = str(node_data)
				var button_image = Image.new()
				button_image.load(get_pck_icon(node_data))
				var button_icon = ImageTexture.new()
				button_icon.create_from_image(button_image)
				instanced_button.get_child(0).get_child(0).icon = button_icon
				instanced_button.get_child(0).get_child(0).connect("button_pressed", self, "_on_button_pressed")
				print(dir_contents("res://" + str(node_data)))
			else:
				printerr(node_data + " button already exists. Skipping creation.")
		else:
			printerr("App doesn't seem to be installed to the system. Redownload the app and retry.")
		
		array_line = array_line + 1
	
	installed_apps.close()

# opens an app when a button was pressed on the apps screen
func _on_button_pressed(button):
	var pressed_button = button.name
	print("\n" + str(pressed_button) + " button was pressed")
	
	var app_node_scene
	var app_node
	var load_app
	var pck_file = File.new()
	if pck_file.file_exists(str(user_path) + "/apps/" + pressed_button + ".pck"):
		print("\n" + str(user_path) + "/apps/" + pressed_button + ".pck")
		load_app = ProjectSettings.load_resource_pack(user_path + "/apps/" + pressed_button + ".pck")
		if load_app:
			dir_contents("res://" + str(pressed_button))
			if pck_file.file_exists("res://" + pressed_button + "/Main.tscn"):
				app_node_scene = load("res://" + str(pressed_button) + "/Main.tscn")
				print("\n" + str(app_node_scene))
				app_node = app_node_scene.instance()
				print("\n" + str(app_node))
				open_app(app_node, pressed_button)
			else:
				printerr("The file, 'res://" + pressed_button + "/Main.tscn' doesn't exist skipping opening app.")
		else:
			printerr("Failed to load pck file.")
	else:
		printerr("File doesn't exist. Not able to open.")
		update_apps()

# hides or shows the window when pressing the app's icon on the toolbar (OpenWindows)
func _on_window_button_pressed(button, is_button : bool):
	var panel_selected = load("res://resources/presets/AppButtonSelected.tres")
	var panel_unselected = load("res://resources/presets/AppButtonUnselected.tres")
	
	var pressed_button = button.name
	print(str(pressed_button) + " window button was pressed")
	var window_node = get_node("Windows").get_node(pressed_button)
	print(window_node)
	print(str(window_node.visible) + " is the visible state")
	#window_node.visible = !window_node.visible
	if is_button == true:
		if window_anim_playable == true:
			if window_node.visible == false:
				window_anim_playable = false
				get_node("OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_selected)
				window_node.rect_size = Vector2(240,0)
				window_node.rect_position = Vector2(get_viewport_rect().size.x/2.48, get_viewport_rect().size.y/2)
				window_node.visible = true
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.connect("finished", self, "window_anim_done", [window_node, false])
				tween.tween_property(window_node, "rect_position", Vector2(window_node.rect_position.x-152, window_node.rect_position.y-158), 0.75)
				tween.parallel().tween_property(window_node, "rect_size", Vector2(544, 320), 0.75)
				tween.parallel().tween_property(window_node, "modulate", Color(1,1,1,1), 0.75)
			elif window_node.visible == true:
				window_anim_playable = false
				get_node("OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_unselected)
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.connect("finished", self, "window_anim_done", [window_node, true])
				tween.tween_property(window_node, "rect_position", Vector2(window_node.rect_position.x+152, get_viewport_rect().size.y), 0.75)
				tween.parallel().tween_property(window_node, "rect_size", Vector2(240, 0), 0.75)
				tween.parallel().tween_property(window_node, "modulate", Color(1,1,1,0), 0.75)
	else:
		get_node("OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_unselected)

# hides window when the anim is finished
func window_anim_done(window_node, hiding):
	if hiding == true:
		window_node.hide()
	window_anim_playable = true

# creates the window, app icon for the toolbar, the app's visuals, and connects all the actions together.
func open_app(app_node, app_name : String):
	var app_name_new = app_name
	
	var app_window_path = load("res://scenes/AppWindow.tscn")
	var app_window_node = app_window_path.instance()
	get_node("Windows").add_child(app_window_node)
	app_window_node.name = app_name
	app_window_node.window_title = app_name
	app_window_node.connect("window_hidden", self, "_on_window_button_pressed")
	app_window_node.show()
	#app_window_node.visible = true
	
	app_window_node.connect("window_closed", self, "_on_window_closed")
	
	var app_button_node = load("res://scenes/AppWindowButton.tscn").instance()
	app_button_node.name = app_name
	app_button_node.get_child(0).text = ""
	app_button_node.get_child(0).flat = true
	app_button_node.get_child(0).hint_tooltip = str(app_name)
	var button_image = Image.new()
	button_image.load(get_pck_icon(app_name))
	var button_icon = ImageTexture.new()
	button_icon.create_from_image(button_image)
	app_button_node.get_child(0).icon = button_icon
	app_button_node.get_child(0).connect("button_pressed", self, "_on_window_button_pressed")
	
	if app_window_node.name != app_button_node.name:
		var count = 1
		while app_window_node.name != app_button_node.name:
			print(count)
			app_window_node.name = app_name + str(count)
			app_button_node.name = app_name + str(count)
			app_name_new = app_name + str(count)
			count = count + 1
	
	print("\n" + str(get_node(str("Windows/" + app_name_new))))
	get_node(str("Windows/" + app_name_new)).add_child(app_node)
	
	get_node("OpenWindowsBar/ScrollContainer/HBoxContainer").add_child(app_button_node, true)

# same as 'open_app()' but instead opens an app with built-in resources
func open_built_in_app(app_node, app_name : String, icon):
	var app_name_new = app_name
	
	var app_window_path = load("res://scenes/AppWindow.tscn")
	var app_window_node = app_window_path.instance()
	get_node("Windows").add_child(app_window_node)
	app_window_node.name = app_name
	app_window_node.window_title = app_name
	app_window_node.connect("window_hidden", self, "_on_window_button_pressed")
	app_window_node.show()
	#app_window_node.visible = true
	
	app_window_node.connect("window_closed", self, "_on_window_closed")
	
	var app_button_node = load("res://scenes/AppWindowButton.tscn").instance()
	app_button_node.name = app_name
	app_button_node.get_child(0).text = ""
	app_button_node.get_child(0).flat = true
	app_button_node.get_child(0).hint_tooltip = str(app_name)
	app_button_node.get_child(0).icon = icon
	app_button_node.get_child(0).connect("button_pressed", self, "_on_window_button_pressed")
	
	if app_window_node.name != app_button_node.name:
		var count = 1
		while app_window_node.name != app_button_node.name:
			print(count)
			app_window_node.name = app_name + str(count)
			app_button_node.name = app_name + str(count)
			app_name_new = app_name + str(count)
			count = count + 1
	
	print("\n" + str(get_node(str("Windows/" + app_name_new))))
	get_node(str("Windows/" + app_name_new)).add_child(app_node)
	
	get_node("OpenWindowsBar/ScrollContainer/HBoxContainer").add_child(app_button_node, true)

# lists all available files from the specified directory
func dir_contents(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		print("\n")
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("\nAn error occurred when trying to access the path.")

# puts all files found in a directory into an array
func dir_files_to_array(path):
	var dir = Directory.new()
	var file_array = []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		print("\n")
		while file_name != "":
			if not dir.current_is_dir():
				file_array.append(file_name)
			file_name = dir.get_next()
	else:
		print("\nAn error occurred when trying to access the path.")
	#print(file_array)
	return file_array

# puts all directories found in a directory into an array
func dir_dirs_to_array(path):
	var dir = Directory.new()
	var file_array = []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
				file_array.append(file_name)
			file_name = dir.get_next()
	else:
		print("\nAn error occurred when trying to access the path.")
	print(file_array)
	return file_array

# gets the app's icon saved inside the pck file
func get_pck_icon(app_name : String):
	var pck_file = "user://apps/" + app_name + ".pck"
	var err = ProjectSettings.load_resource_pack(pck_file)
	if err == true:
		dir_contents("res://" + app_name)
		print("\nsuccessfully loaded pck file.")
		print("\ngetting icon from res://" + app_name + "/" + app_name + ".png")
		return "res://" + app_name + "/" + app_name + ".png"

# connects the window's close signal to the app's toolbar icon to free it
func _on_window_closed(app_name):
	emit_signal("close_app_window_button", app_name)

# looks into the apps directory, searches for new apps, and adds or removes apps based on what happened with them.
func update_apps():
	var app_files : Array = dir_files_to_array(user_path + "/apps")
	app_files.remove(app_files.find("installed-apps.txt"))
	print(app_files)
	
	var installed_apps = File.new()
	var array_line = 0
	var file_name : String
	
	#apps.clear()
	installed_apps.open(user_path + "/apps/installed-apps.txt", File.WRITE)
	while array_line < app_files.size():
		print("Line #" + str(array_line))
		
		file_name = app_files[array_line]
		print(file_name)
		file_name.erase(file_name.length()-4, 4)
		print(file_name)
		
		installed_apps.store_line(str(file_name))
		print("Appended app " + file_name + " to file")
		
		#apps.append(file_name)
		#print("Appened app in 'apps': " + file_name)
		
		array_line = array_line + 1
	
	installed_apps.close()
	
	refresh_app_list()

# DEBUG BUTTON FUNCTIONS

func _on_RefreshApps_pressed():
	refresh_app_list()

func _on_WriteInstalledApps_pressed():
	var app_files : Array = dir_files_to_array(user_path + "/apps")
	app_files.remove(app_files.find("installed-apps.txt"))
	print(app_files)
	
	var installed_apps = File.new()
	var array_line = 0
	var file_name : String
	
	apps.empty()
	installed_apps.open(user_path + "/apps/installed-apps.txt", File.WRITE)
	while array_line < app_files.size():
		print("Line #" + str(array_line))
		
		file_name = app_files[array_line]
		print(file_name)
		file_name.erase(file_name.length()-4, 4)
		print(file_name)
		
		installed_apps.store_line(str(file_name))
		print("Appended app " + file_name + " to file")
		
		apps.append(file_name)
		print("Appened app in 'apps': " + file_name)
		
		array_line = array_line + 1
	
	installed_apps.close()

func _on_OpenApp_pressed():
	var icon = Image.new()
	icon.load("res://resources/textures/Setting.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/Settings.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	open_built_in_app(app_node, "Settings", icon)

# ANIMATIONS GO HERE
func _on_StartButton_mouse_entered():
	#$StartButton/Anim.play("Hover")
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($StartButton/Button, "rect_size", Vector2(56,56), 0.4)
	tween.parallel().tween_property($StartButton/Button, "rect_position", Vector2(-2,-2), 0.4)

func _on_StartButton_mouse_exited():
	#$StartButton/Anim.play_backwards("Hover")
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($StartButton/Button, "rect_size", Vector2(52,52), 0.4)
	tween.parallel().tween_property($StartButton/Button, "rect_position", Vector2(0,0), 0.4)

func _on_StartButton_toggled(button_pressed):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if button_pressed == true:
		$StartMenu.grab_focus()
		$StartMenu.visible = true
		tween.tween_property($StartMenu, "rect_size", Vector2(224,220), 1)
		tween.parallel().tween_property($StartMenu, "rect_position", Vector2(0,get_viewport_rect().size.y-272), 1)
		tween.parallel().tween_property($StartMenu, "modulate", Color(1,1,1,1), 1)
	else:
		$StartMenu.focus_mode = Control.FOCUS_NONE
		tween.tween_property($StartMenu, "rect_size", Vector2(224,0), 1)
		tween.parallel().tween_property($StartMenu, "rect_position", Vector2(0,get_viewport_rect().size.y+20), 0.85)
		tween.parallel().tween_property($StartMenu, "modulate", Color(1,1,1,0), 1)

func _on_DownloadApps_pressed():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($StartMenu, "rect_size", Vector2(224,0), 1)
	tween.parallel().tween_property($StartMenu, "rect_position", Vector2(0,740), 0.85)
	tween.parallel().tween_property($StartMenu, "modulate", Color(1,1,1,0), 1)
	$StartButton/Button.pressed = false
	
	var icon = load("res://resources/textures/Download.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/AppDownloader.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	open_built_in_app(app_node, "App Downloader", icon)

func _on_UpdateApps_pressed():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($StartMenu, "rect_size", Vector2(224,0), 1)
	tween.parallel().tween_property($StartMenu, "rect_position", Vector2(0,740), 0.85)
	tween.parallel().tween_property($StartMenu, "modulate", Color(1,1,1,0), 1)
	$StartButton/Button.pressed = false
	
	update_apps()

func _on_Settings_pressed():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($StartMenu, "rect_size", Vector2(224,0), 1)
	tween.parallel().tween_property($StartMenu, "rect_position", Vector2(0,740), 0.85)
	tween.parallel().tween_property($StartMenu, "modulate", Color(1,1,1,0), 1)
	$StartButton/Button.pressed = false
	
	var icon = load("res://resources/textures/Settings.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/Settings.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	
	open_built_in_app(app_node, "Settings", icon)
