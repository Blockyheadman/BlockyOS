extends Control

onready var version_container = $VersionSelector/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/VBoxContainer
onready var file_checker = $FileChecker

var download_version : String

var app_versions : Array

func _ready():
	if get_parent() is AppWindow:
		get_parent().window_min_size = Vector2(320,300)
	
	set_process(false)
	
	file_checker.request("https://raw.githubusercontent.com/Blockyheadman/BlockyOS/main/versions.json")

func set_app_data(app_ver : String):
	if OS.get_name() == "Windows":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.exe"
	elif OS.get_name() == "X11":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.x86_64"
	elif OS.get_name() == "OSX":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.zip"
	elif OS.get_name() == "Android":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.apk"
	print(download_version)
	
	var error = Global.download_file(download_version, OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/BlockyOS.exe")
	if error != OK:
		if get_parent() is AppWindow:
			set_process(false)
			get_parent().close_window()
	else:
		$VersionSelector.queue_free()
		$Await.visible = true

func _process(delta):
	if Global.download_status == OK:
		if get_parent() is AppWindow:
			set_process(false)
			get_parent().close_window()
			OS.execute(Global.downloaded_file_path, [], false)
			get_tree().quit()
	elif Global.download_status != -1:
		set_process(false)
		OS.alert("The app was unable to install properly. Error code " + str(Global.download_status), "Error!")
		if get_parent() is AppWindow:
			get_parent().close_window()

func _on_FileChecker_request_completed(result, response_code, headers, body):
	if result == 0 and response_code == 200:
		var data = body.get_string_from_utf8()
		app_versions = Array(data.split("\n", false))
		print(app_versions)
		
		for j in app_versions.size():
			var i = j-1
			var app_button = preload("res://scenes/BOSVersionButton.tscn").instance()
			get_node("VersionSelector/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/VBoxContainer").add_child(app_button, true)
			var button = get_node("VersionSelector/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/VBoxContainer").get_child(j)
			button.name = app_versions[i]
			print(button.name)
			button.app_ver = str(app_versions[i]).replace('"', '')
			button.get_child(1).text = "Version: " + str(app_versions[i]).replace('"', '')
			button.connect("ButtonPressed", self, "set_app_data")
			
		set_process(true)
	else:
		set_process(false)
		OS.alert("Unable to search online for app versions. Try again later.\nError code " + str(response_code))
		if get_parent() is AppWindow:
			get_parent().close_window()
