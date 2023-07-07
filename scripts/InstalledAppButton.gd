extends HBoxContainer
class_name InstalledAppButton

signal RemovePressed

func _ready():
	#$Icon.queue_free()
	pass

func _on_Remove_pressed():
	emit_signal("RemovePressed", self.name)
