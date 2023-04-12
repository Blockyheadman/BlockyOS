extends Node

# Globals variables for system settings
var fling_enabled := true
var bg_window_effect := false
var window_snap := true
var csec_enabled := false

var verison_major : int = 1
var verison_minor : int = 1
var verison_revision : int = 4
var version_full : String = str(verison_major) + "." + str(verison_minor) + "." + str(verison_revision)

var online_version
var online_ver_major
var online_ver_minor
var online_ver_rev

var downloaded_file_path : String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/file.txt"
var download_status : int = -1

var http_request

# Global variables for system events.
var start_menu_shown = false

func save():
	var save_dict = {
		"fling_enabled" : fling_enabled,
		"bg_window_effect" : bg_window_effect,
		"window_snap" : window_snap,
		"clock_seconds_enabled" : csec_enabled
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

func load_settings():
	var save = File.new()
	if not save.file_exists("user://user.bset"):
		save_settings()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save.open("user://user.bset", File.READ)
	while save.get_position() < save.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save.get_line())

		print("Success! 'fling_enabled' Value exists!")
		fling_enabled = node_data["fling_enabled"]
		bg_window_effect = node_data["bg_window_effect"]
		window_snap = node_data["window_snap"]
		csec_enabled = node_data["clock_seconds_enabled"]

	save.close()

# 1 means it failed to download without a reason, 2 means it's already downloading a file
func download_file(file_url : String, file_destination : String):
	if http_request:
		#OS.alert("We can only download one file a time right now. Sorry!", "Woah there!")
		return 2
	else:
		if OS.get_name() != "HTML5":
			download_status = -1
			downloaded_file_path = file_destination
			http_request = HTTPRequest.new()
			add_child(http_request, true)
			http_request.connect("request_completed", self, "_http_request_completed")
		
			var error = http_request.request(file_url)
			return OK
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
			app.open(downloaded_file_path, File.WRITE)
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
