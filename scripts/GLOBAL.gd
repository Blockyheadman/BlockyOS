extends Node

# Globals variables for system settings
var fling_enabled = true
var bg_window_effect = false
var window_snap = true
var csec_enabled = false

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
