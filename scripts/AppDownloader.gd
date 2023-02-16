extends Control

var apps_list : PoolStringArray

func _ready():
	$FileDownloader.save_path = str(OS.get_user_data_dir() + "/apps/")

func _on_Clikcer_pressed():
	#apps_list.append("https://github.com/Blockyheadman/ClikcerZip/blob/main/Clikcer-main.zip")
	apps_list.append("https://clikcer.ml/download/Clikcer.zip")
	$FileDownloader.file_urls = apps_list
	$ScrollContainer/VBoxContainer/DownloadStatusBar/VBoxContainer/AppsList.text = str(apps_list)

func _on_DLButton_pressed():
	$FileDownloader.start_download()
	#download("https://clikcer.ml/download/Clikcer.zip", str(OS.get_user_data_dir()) + "/apps")

func download(url : String, target : String):
	$Downloader.download_file = target # where to save the downloaded file
	$Downloader.request(url) # start the download

func _on_FileDownloader_downloads_finished():
	apps_list = PoolStringArray()
	$FileDownloader.file_urls = apps_list
	$ScrollContainer/VBoxContainer/DownloadStatusBar/VBoxContainer/AppsList.text = str(apps_list)
	unzip_file(ProjectSettings.globalize_path("user://apps/"), "Clikcer")

func _on_FileDownloader_stats_updated(_downloaded_size, _downloaded_percent, _file_name, _file_size):
	$ScrollContainer/VBoxContainer/DownloadStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ProgressBar.value = _downloaded_percent
	$ScrollContainer/VBoxContainer/DownloadStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/Size.text = "File size: " + str(_file_size) + " KiB"

func _on_ResetAppList_pressed():
	apps_list = PoolStringArray()
	$FileDownloader.file_urls = apps_list
	$ScrollContainer/VBoxContainer/DownloadStatusBar/VBoxContainer/AppsList.text = str(apps_list)

func unzip_file(zip : String, result : String):
	print(zip)
	var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
	var loaded = gdunzip.load(zip + "/Clikcer.zip")
	
	var app_dir = Directory.new()
	app_dir.open(OS.get_user_data_dir() + "/apps")
	app_dir.make_dir(result)
	
	if loaded:
		for f in gdunzip.files.values():
			print('File name: ' + f['file_name'])
			# "compression_method" will be either -1 for uncompressed data, or
			# File.COMPRESSION_DEFLATE for deflate streams
			print('Compression method: ' + str(f['compression_method']))
			print('Compressed size: ' + str(f['compressed_size']))
			print('Uncompressed size: ' + str(f['uncompressed_size']))
	else:
		print('Failed loading zip file')
