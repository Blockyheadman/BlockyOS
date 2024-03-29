extends Control

signal close_app_window_button

var window_anim_playable := true
var user_path := OS.get_user_data_dir()
var apps : Array

var time = Time.get_time_string_from_system()
var permissions_granted : PoolStringArray

func _ready():
	var set_error = Global.load_settings()
	while set_error != 0:
		set_error = Global.load_settings()
	
	print("LOCALIZED PATH: %s" % ProjectSettings.localize_path("res://resources/textures/Backgrounds/DefaultBackground.png"))
	print("GLOBALIZED PATH: %s" % ProjectSettings.globalize_path("res://resources/textures/Backgrounds/DefaultBackground.png"))
	
	OS.min_window_size = Vector2(640,360)
	
	if OS.has_feature("debug"):
		$Debugging/DebugTools.visible = true
	elif OS.has_feature("release"):
		$Debugging/DebugTools.queue_free()
	
	if OS.get_name() == "HTML5":
		$MenuBar/StartMenu/VBoxContainer/UpdateDownloader.queue_free()
	
	$MenuBar/StartMenu.visible = false
	$MenuBar/StartMenu.rect_size = Vector2(224, 0)
	$MenuBar/StartMenu.rect_position = Vector2(0, get_viewport_rect().size.y+20)
	$MenuBar/StartMenu.modulate = Color(1,1,1,0)
	print("User OS Path: " + str(user_path))
	var apps_dir = Directory.new()
	if !apps_dir.dir_exists(user_path + "/apps"):
		apps_dir.make_dir(user_path + "/apps")
	var apps_file = File.new()
	if !apps_file.file_exists(user_path + "/apps/installed-apps.txt"):
		apps_file.open(user_path + "/apps/installed-apps.txt", File.WRITE)
		apps_file.store_string("")
		apps_file.close()
	update_apps()
	print("\nApps installed: " + str(apps))
	
	get_tree().connect("files_dropped", self, "dropped_files")
	
	OS.request_permissions()
	permissions_granted = OS.get_granted_permissions()
	
	if OS.get_name() == "Android":
		if permissions_granted.find("android.permission.READ_EXTERNAL_STORAGE") == -1:
			$MenuBar/StartMenu/VBoxContainer/InstallApps.disabled = true

func _input(event):
	if event is InputEventKey:
		if event.scancode == 16777254:
			if !event.pressed:
				OS.window_fullscreen = !OS.window_fullscreen
	
	if event is InputEventMouse:
		var windows_children = $Windows/WindowLayer.get_children()
		if event.position.x >= 0 and event.position.y >= $MenuBar/StartButton.rect_position.y:
			if event.position.x <= $MenuBar/StartButton.rect_position.x + $MenuBar/StartButton.rect_size.x:
				if event.position.y <= $MenuBar/StartButton.rect_position.y + $MenuBar/StartButton.rect_size.y:
					for i in windows_children.size():
						if !Global.start_menu_shown:
							windows_children[i].hide()
		else:
			for i in windows_children.size():
				if !Global.start_menu_shown and windows_children[i].minimized == false:
					windows_children[i].show()

func _process(_delta):
	
	time = Time.get_time_string_from_system()
	
	if !Global.csec_enabled:
		time.erase(time.length()-3, 3)
		
		if Time.get_time_dict_from_system()["second"] % 2 != 0:
			time.erase(time.length()-3, 1)
			time = time.insert(time.length()-2, " ")
	
	$MenuBar/Clock/Label.text = time

# CUSTOM FUNCTIONS BELOW

# checks for dropped files on the desktop and adds the apps.
func dropped_files(files: PoolStringArray, _screen: int) -> void:
	for i in files.size():
		if files[i].ends_with(".pck"):
			var app_name
			if OS.get_name() == "Windows": app_name = files[i].split("\\")
			else: app_name = files[i].split("/")
			app_name = app_name[app_name.size()-1]
			print("\nImporting %s app" % app_name)
			var file = File.new()
			var app = File.new()
			file.open(files[i], File.READ)
			app.open(user_path + "/apps/" + app_name, File.WRITE)
			
			while file.get_position() < file.get_len():
				app.store_64(file.get_64())
			file.close()
			app.close()
			
			update_apps()

# removes all nodes from the AppsGridContainer
func clear_app_buttons() -> void:
	for i in apps.size():# - 1:
		if has_node("Apps/AppsGridContainer/" + str(apps[i])):
			var button_path = get_node("Apps/AppsGridContainer/" + apps[i]).get_path()
			print("removing node: " + str(get_node("Apps/AppsGridContainer").get_node(apps[i])))
			print(get_node("Apps/AppsGridContainer/" + apps[i]))
			get_node(button_path).queue_free()
			print(get_node("Apps/AppsGridContainer/" + apps[i]))

# resets the AppsGridContainer and creates new buttons for each app.
func refresh_app_list() -> void:
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
			app_dir.close()
			#if !get_node("AppsGridContainer").get_child(array_line):
			if !has_node("Apps/AppsGridContainer/" + node_data):
				var button_scene = load("res://scenes/AppButton.tscn")
				var instanced_button : Node = button_scene.instance()
				get_node("Apps/AppsGridContainer").add_child(instanced_button)
				print("Node Name: " + str(get_node("Apps/AppsGridContainer").get_child(array_line).name))
				instanced_button.name = node_data
				instanced_button.get_child(0).get_child(1).text = node_data
				instanced_button.get_child(0).get_child(0).flat = true
				instanced_button.get_child(0).get_child(0).text = ""
				instanced_button.get_child(0).get_child(0).hint_tooltip = str(node_data)
				var button_image = Image.new()
				var error = get_pck_icon(node_data)
				if error != "0":
					button_image.load(error)
					var button_icon = ImageTexture.new()
					button_icon.create_from_image(button_image)
					instanced_button.get_child(0).get_child(0).icon = button_icon
					instanced_button.get_child(0).get_child(0).connect("button_pressed", self, "_on_button_pressed")
					print(dir_contents("res://" + str(node_data)))
				else:
					printerr("This app is not supported or broken.")
					var rm_file = Directory.new()
					rm_file.remove("user://apps/" + node_data + ".pck")
					update_apps()
			else:
				printerr(node_data + " button already exists. Skipping creation.")
		else:
			printerr("App doesn't seem to be installed to the system. Redownload the app and retry.")
		
		array_line = array_line + 1
	
	installed_apps.close()

# opens an app when a button was pressed on the apps screen
func _on_button_pressed(button) -> void:
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
			elif pck_file.file_exists("res://" + pressed_button + "/scenes/Main.tscn"):
				app_node_scene = load("res://" + str(pressed_button) + "/scenes/Main.tscn")
				print("\n" + str(app_node_scene))
				app_node = app_node_scene.instance()
				print("\n" + str(app_node))
				open_app(app_node, pressed_button)
			else:
				printerr("The " + pressed_button + " 'Main.tscn' file doesn't exist. Skipping opening app.")
			
		else:
			printerr("Failed to load pck file.")
	else:
		printerr("File doesn't exist. Not able to open.")
		update_apps()
	pck_file.close()

# changes taskbar panel when pressing the app window's minimize button (OpenWindows)
func _on_window_button_pressed(button, is_button: bool) -> void:
	var panel_selected = load("res://resources/presets/AppButtonSelected.tres")
	var panel_unselected = load("res://resources/presets/AppButtonUnselected.tres")
	
	var pressed_button = button.name
	print(str(pressed_button) + " window button was pressed")
	var window_node = get_node("Windows/WindowLayer").get_node(pressed_button)
	print(window_node)
	print(str(window_node.visible) + " is the visible state")
	#window_node.visible = !window_node.visible
	if is_button == true:
		if window_anim_playable == true:
			if window_node.visible == false:
				window_node.minimized = false
				window_anim_playable = false
				window_node.raise()
				get_node("MenuBar/OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_selected)
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
				window_node.minimized = true
				window_node.maximized = false
				window_node.snapped_left = false
				window_node.snapped_right = false
				window_anim_playable = false
				get_node("MenuBar/OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_unselected)
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.connect("finished", self, "window_anim_done", [window_node, true])
				tween.tween_property(window_node, "rect_position", Vector2(window_node.rect_position.x+152, get_viewport_rect().size.y), 0.75)
				tween.parallel().tween_property(window_node, "rect_size", Vector2(240, 0), 0.75)
				tween.parallel().tween_property(window_node, "modulate", Color(1,1,1,0), 0.75)
	else:
		get_node("MenuBar/OpenWindowsBar/ScrollContainer/HBoxContainer").get_node(str(button)).get_child(1).add_stylebox_override("panel", panel_unselected)

# hides window when the anim is finished
func window_anim_done(window_node, hiding: bool) -> void:
	if hiding == true:
		window_node.hide()
	window_anim_playable = true

# creates the window, app icon for the toolbar, the app's visuals, and connects all the actions together.
func open_app(app_node, app_name: String) -> void:
	var app_name_new = app_name
	
	var app_window_path = load("res://scenes/AppWindow.tscn")
	var app_window_node = app_window_path.instance()
	get_node("Windows/WindowLayer").add_child(app_window_node)
	app_window_node.name = app_name
	app_window_node.window_title = app_name
	app_window_node.connect("window_hidden", self, "_on_window_button_pressed")
	app_window_node.show()
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
	
	print("\n" + str(get_node(str("Windows/WindowLayer/" + app_name_new))))
	get_node(str("Windows/WindowLayer/" + app_name_new)).add_child(app_node)
	
	get_node("MenuBar/OpenWindowsBar/ScrollContainer/HBoxContainer").add_child(app_button_node, true)

# same as 'open_app()' but instead opens an app with built-in resources
func open_built_in_app(app_node, app_name: String, icon) -> void:
	var app_name_new = app_name
	
	var app_window_path = load("res://scenes/AppWindow.tscn")
	var app_window_node = app_window_path.instance()
	get_node("Windows/WindowLayer").add_child(app_window_node)
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
	
	print("\n" + str(get_node(str("Windows/WindowLayer/" + app_name_new))))
	get_node(str("Windows/WindowLayer/" + app_name_new)).add_child(app_node)
	
	get_node("MenuBar/OpenWindowsBar/ScrollContainer/HBoxContainer").add_child(app_button_node, true)

# lists all available files from the specified directory
func dir_contents(path: String) -> void:
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
func dir_files_to_array(path: String) -> Array:
	var dir = Directory.new()
	var file_array := []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				file_array.append(file_name)
			file_name = dir.get_next()
	else:
		print("\nAn error occurred when trying to access the path.")
	#print(file_array)
	return file_array

# puts all directories found in a directory into an array
func dir_dirs_to_array(path: String) -> Array:
	var dir = Directory.new()
	var file_array := []
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
func get_pck_icon(app_name: String) -> String:
	var pck_file = "user://apps/" + app_name + ".pck"
	var err = ProjectSettings.load_resource_pack(pck_file)
	if err == true:
		dir_contents("res://" + app_name)
		print("\nsuccessfully loaded pck file.")
		print("\ngetting icon from res://" + app_name + "/" + app_name + ".png")
		var icon := File.new()
		if icon.file_exists("res://" + app_name + "/" + app_name + ".png"):
			icon.close()
			return "res://" + app_name + "/" + app_name + ".png"
		else:
			icon.close()
			return "0"
	return "0"

# connects the window's close signal to the app's toolbar icon to free it
func _on_window_closed(app_name: String) -> void:
	print("emitting 'close_app_window_button' signal")
	emit_signal("close_app_window_button", app_name)

# looks into the apps directory, searches for new apps, and adds or removes apps based on what happened with them.
func update_apps() -> void:
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

# hides the start menu
func hide_start_menu() -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($MenuBar/StartMenu, "rect_size", Vector2(224,0), 1)
	tween.parallel().tween_property($MenuBar/StartMenu, "rect_position", Vector2(0,740), 0.85)
	tween.parallel().tween_property($MenuBar/StartMenu, "modulate", Color(1,1,1,0), 1)
	$MenuBar/StartButton/Button.pressed = false

# ANIMATIONS GO HERE
func _on_StartButton_mouse_entered() -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($MenuBar/StartButton/Button, "rect_size", Vector2(64,64), 0.4)
	tween.parallel().tween_property($MenuBar/StartButton/Button, "rect_position", Vector2(-2,-2), 0.4)

func _on_StartButton_mouse_exited() -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($MenuBar/StartButton/Button, "rect_size", Vector2(60,60), 0.4)
	tween.parallel().tween_property($MenuBar/StartButton/Button, "rect_position", Vector2(0,0), 0.4)

# WHEN DIFFERENT SYSTEM BUTTONS PRESSED/TOGGLED

func _on_StartButton_toggled(button_pressed: bool) -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if button_pressed == true:
		#$MenuBar/StartMenu.grab_focus()
		$MenuBar/StartMenu.visible = true
		tween.tween_property($MenuBar/StartMenu, "rect_size", Vector2(224,220), 1)
		tween.parallel().tween_property($MenuBar/StartMenu, "rect_position", Vector2(0,get_viewport_rect().size.y-280), 1)
		tween.parallel().tween_property($MenuBar/StartMenu, "modulate", Color(1,1,1,1), 1)
		Global.start_menu_shown = true
	else:
		#$MenuBar/StartMenu.focus_mode = Control.FOCUS_NONE
		tween.tween_property($MenuBar/StartMenu, "rect_size", Vector2(224,0), 1)
		tween.parallel().tween_property($MenuBar/StartMenu, "rect_position", Vector2(0,get_viewport_rect().size.y+20), 0.85)
		tween.parallel().tween_property($MenuBar/StartMenu, "modulate", Color(1,1,1,0), 1)
		var windows_children = $Windows/WindowLayer.get_children()
		print(windows_children)
		Global.start_menu_shown = false

func _on_InstallApps_pressed() -> void:
	hide_start_menu()
	
	var icon = load("res://resources/textures/Download.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/AppInstaller.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	open_built_in_app(app_node, "App Installer", icon)

func _on_UpdateApps_pressed() -> void:
	hide_start_menu()
	update_apps()

func _on_UpdateDownloader_pressed() -> void:
	hide_start_menu()
	
	var icon = load("res://resources/textures/Update.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/UpdateDownloader.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	
	open_built_in_app(app_node, "Update Downloader", icon)

func _on_Settings_pressed() -> void:
	hide_start_menu()
	
	var icon = load("res://resources/textures/Settings.png")
	var app_node_scene
	var app_node
	app_node_scene = load("res://scenes/Settings.tscn")
	print("\n" + str(app_node_scene))
	app_node = app_node_scene.instance()
	print("\n" + str(app_node))
	
	open_built_in_app(app_node, "Settings", icon)
