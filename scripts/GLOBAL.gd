extends Node

var default_bg := preload("res://resources/textures/Backgrounds/DefaultBackground.png")
var corrupt_bg := preload("res://resources/textures/Backgrounds/CorruptedBackground.png")

# Globals variables for system settings
var fling_enabled := true
var bg_window_effect := false
var window_snap := true
var csec_enabled := false
var default_dl_path : String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
var desktop_background : String = "res://resources/textures/Backgrounds/DefaultBackground.png"

var bg_texture

var verison_major : int = 1
var verison_minor : int = 2
var verison_revision : int = 1
var version_full : String = str(verison_major) + "." + str(verison_minor) + "." + str(verison_revision)
var version_state : String = "Stable"

var online_version
var online_ver_major
var online_ver_minor
var online_ver_rev

var download_file_path : String = default_dl_path + "/BlockyOS.exe"
var download_status : int = -1

var button_hover_style := StyleBoxFlat.new()
var button_hover_color : Color = Color(0, 1, 0.67, 1)
var button_pressed_style := StyleBoxFlat.new()
var button_pressed_color : Color = Color(0, 0.65, 0.43, 1)
var button_font := DynamicFont.new()

var http_request

# Global variables for system events.
var start_menu_shown = false

func _ready():
	button_hover_style.bg_color = button_hover_color
	button_hover_style.set_border_width_all(2)
	button_hover_style.border_color = Color (1,1,1,1)
	button_hover_style.set_corner_radius_all(5)
	
	button_pressed_style.bg_color = button_pressed_color
	button_pressed_style.set_border_width_all(2)
	button_pressed_style.border_color = Color (1,1,1,1)
	button_pressed_style.set_corner_radius_all(5)
	
	button_font.font_data = load("res://resources/fonts/ariblk.ttf")

func save() -> Dictionary:
	var save_dict := {
		"fling_enabled" : fling_enabled,
		"bg_window_effect" : bg_window_effect,
		"window_snap" : window_snap,
		"clock_seconds_enabled" : csec_enabled,
		"default_dl_path" : default_dl_path,
		"desktop_background" : desktop_background,
		"accent_color" : button_hover_color
	}
	return save_dict

func save_settings():
	var save = File.new()
	save.open("user://user.bset", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# Store the save dictionary as a new line in the save file.
		save.store_line(to_json(node_data))
	save.close()

func load_settings() -> int:
	var save = File.new()
	if not save.file_exists("user://user.bset"):
		save_settings()
		return 1

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save.open("user://user.bset", File.READ)
	while save.get_position() < save.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data : Dictionary = parse_json(save.get_line())
		
		fling_enabled = node_data["fling_enabled"]
		bg_window_effect = node_data["bg_window_effect"]
		window_snap = node_data["window_snap"]
		csec_enabled = node_data["clock_seconds_enabled"]
		
		if node_data.get("default_dl_path") == null:
			print("download path not found!")
			save.close()
			save_settings()
			return 1
		else: default_dl_path = node_data["default_dl_path"]
		
		if node_data.get("desktop_background") == null:
			print("desktop bg not found!")
			save.close()
			save_settings()
			return 1
		else:
			desktop_background = node_data["desktop_background"]
			load_bg_image(desktop_background)
		if node_data.get("accent_color") == null:
			print ("accent color not found!")
			save.close()
			save_settings()
			return 1
		else:
			var color = node_data["accent_color"]
			color = color.split(",")
			button_hover_color = Color(color[0], color[1], color[2], color[3])
			button_pressed_color = Color(
				clamp(button_hover_color.r - 0.35, 0, 1),
				clamp(button_hover_color.g - 0.35, 0, 1),
				clamp(button_hover_color.b - 0.35, 0, 1)
			)
			
			var button_preset : Theme = load("res://resources/presets/GeneralButton.tres")
			button_hover_style.bg_color = button_hover_color
			button_pressed_style.bg_color = button_pressed_color
			button_preset.set_stylebox("hover", "Button", button_hover_style)
			button_preset.set_stylebox("pressed", "Button", button_pressed_style)
			if button_hover_color.v > 0.5:
				button_preset.set_color("font_color_hover", "Button", Color(0,0,0,1))
			else:
				button_preset.set_color("font_color_hover", "Button", Color(1,1,1,1))
			if button_pressed_color.v > 0.5:
				button_preset.set_color("font_color_pressed", "Button", Color(0,0,0,1))
			else:
				button_preset.set_color("font_color_pressed", "Button", Color(0.84,0.84,0.84,1))
	
	save.close()
	return 0

# 1 means it failed to download without a reason, 2 means it's already downloading a file
func download_file(file_url : String, file_destination : String):
	if http_request:
		#OS.alert("We can only download one file a time right now. Sorry!", "Woah there!")
		return 2
	else:
		if OS.get_name() != "HTML5":
			download_status = -1
			http_request = HTTPRequest.new()
			add_child(http_request, true)
			http_request.connect("request_completed", self, "_http_request_completed")
			
			var error = http_request.request(file_url)
			
			if error != OK:
				#OS.alert("HTTP Request failed to request the file. Error code " + str(error), "Woah there!")
				http_request.queue_free()
				http_request = null
				return 1
		else:
			http_request.queue_free()
			http_request = null
			return 2046 # this means incompatable platform

func _http_request_completed(result, response_code, _headers, body):
	if result == 0:
		if response_code == 200:
			var app = File.new()
			app.open(download_file_path, File.WRITE)
			app.store_buffer(body)
			app.close()
			http_request.queue_free()
			http_request = null
			download_status = OK
		else:
			http_request.queue_free()
			http_request = null
			download_status = response_code
	else:
		http_request.queue_free()
		http_request = null
		download_status = result

func load_bg_image(path : String):
	var bg_image := Image.new()
	var error := bg_image.load(path)
	var texture := ImageTexture.new()
	if error != OK:
		printerr("Error loading image. Error: %s" % error)
		desktop_background = "res://resources/textures/Backgrounds/DefaultBackground.png"
		bg_texture = default_bg
		get_viewport().get_node("Desktop/Background").texture = default_bg
		save_settings()
		return
	
	print("Loading image at '%s'" % path)
	texture.create_from_image(bg_image)
	
	desktop_background = path
	bg_texture = texture
	get_viewport().get_node("Desktop/Background").texture = texture
