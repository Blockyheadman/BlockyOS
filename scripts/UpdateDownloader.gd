extends Control

onready var version_container = $VersionSelector/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/VBoxContainer
onready var file_checker = $FileChecker

var download_version : String
var app_versions : Array

var await_finished := false

func _ready():
	if get_parent() is AppWindow:
		get_parent().window_min_size = Vector2(320,300)
	
	set_process(false)
	
	file_checker.request("https://raw.githubusercontent.com/Blockyheadman/BlockyOS/main/versions.json")

func _exit_tree():
	if Global.http_request:
		Global.http_request.queue_free()
		Global.http_request = null

func set_app_data(app_ver : String):
	if OS.get_name() == "Windows":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.exe"
	elif OS.get_name() == "X11":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.x86_64"
	elif OS.get_name() == "OSX":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.zip"
	elif OS.get_name() == "Android":
		download_version = "https://github.com/Blockyheadman/BlockyOS/releases/download/v" + app_ver + "/BlockyOS.apk"
	else:
		show_error_screen("App cannot be installed on this device.. So how did you get this error?..", "2046")
		return
	print(download_version)
	
	var error = Global.download_file(download_version, OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/BlockyOS.exe")
	print(error)
	if error != OK:
		if error == 1:
			show_error_screen("HTTP Request failed to request the file.", str(error))
		elif error == 2:
			show_error_screen("This can only download one file a time right now. Sorry!", str(error))
		elif error == 2046:
			show_error_screen("File cannot be downloaded on this device.", str(error))
		return
#		if get_parent() is AppWindow:
#			set_process(false)
#			get_parent().close_window()
	elif error == OK:
		#$VersionSelector.queue_free()
		$Await.rect_position = Vector2(self.rect_size.x+8, 8)
		$Await.modulate = Color(1,1,1,0)
		$Await.visible = true
		
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.connect("finished", self, "await_tween_finished")
		tween.tween_property($VersionSelector, "rect_position", Vector2(-self.rect_size.x, 8), 1.5)
		tween.parallel().tween_property($VersionSelector, "modulate", Color(1,1,1,0), 1.5)
		tween.parallel().tween_property($Await, "rect_position", Vector2(8, 8), 1.5)
		tween.parallel().tween_property($Await, "modulate", Color(1,1,1,1), 1.5)
		if get_parent() is AppWindow:
			if !get_parent().maximized and !get_parent().snapped_left and !get_parent().snapped_right:
				tween.parallel().tween_property(get_parent(), "rect_size", Vector2(340, 320), 1.0)
				tween.parallel().tween_property(get_parent(), "window_min_size", Vector2(360, 340), 1.0)
			else:
				get_parent().window_min_size = Vector2(360, 340)

func await_tween_finished():
	await_finished = true

func _process(delta):
	if $Await.visible == true:
		$Await/VBoxContainer/ScrollContainer/VBoxContainer/MainContainer/LoadingIcon.rect_rotation += 7.5
	
	if Global.download_status == OK:
		if get_parent() is AppWindow:
			set_process(false)
			get_parent().close_window()
			OS.execute(Global.downloaded_file_path, [], false)
			get_tree().quit()
	elif Global.download_status != -1 and await_finished:
		set_process(false)
#		OS.alert("The app was unable to install properly. Error code " + str(Global.download_status), "Error!")
		show_error_screen("The app was unable to install properly.", str(Global.download_status))
#		if get_parent() is AppWindow:
#			get_parent().close_window()

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
		#OS.alert("Unable to search online for app versions. Try again later.\nError code " + str(response_code))
		show_error_screen("Unable to search online for app versions. Try again later.", str(response_code))
#		if get_parent() is AppWindow:
#			get_parent().close_window()

func show_error_screen(info_text : String, error_code : String):
	$Error/VBoxContainer/ScrollContainer/VBoxContainer/InfoLabel.text = info_text
	$Error/VBoxContainer/DescriptionLabel.text = "Error code " + str(error_code)
	
	$Error.rect_position = Vector2(self.rect_size.x+8, 8)
	$Error.modulate = Color(1,1,1,0)
	$Error.visible = true
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	
	tween.tween_property($VersionSelector, "rect_position", Vector2(-self.rect_size.x, 8), 1.5)
	tween.parallel().tween_property($VersionSelector, "modulate", Color(1,1,1,0), 1.5)
	tween.parallel().tween_property($Await, "rect_position", Vector2(-self.rect_size.x, 8), 1.5)
	tween.parallel().tween_property($Await, "modulate", Color(1,1,1,0), 1.5)
	
	tween.parallel().tween_property($Error, "rect_position", Vector2(8, 8), 1.5)
	tween.parallel().tween_property($Error, "modulate", Color(1,1,1,1), 1.5)
	tween.parallel().tween_property(get_parent(), "rect_size", Vector2(544, 320), 1.5)
	tween.parallel().tween_property(get_parent(), "window_min_size", Vector2(320, 330), 1.5)
