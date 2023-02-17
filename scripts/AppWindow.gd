extends WindowDialog

signal window_closed
signal window_hidden

var window_anim_playable = true
var maximized = false
var prev_size = Vector2()
var prev_pos = Vector2()

var max_anim_done = true

func _ready():
	modulate = Color(0,0,0,0)
# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "window_size_changed")
	
	self.rect_size = Vector2(240,0)
	self.rect_position = Vector2(get_viewport_rect().size.x/2.48, get_viewport_rect().size.y/2)
	get_close_button().hide()
	#$Anim.play("Window Opened")
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	#tween.tween_property(self, "rect_position", Vector2((get_viewport_rect().size.x/2)-self.rect_size.x/0.89, (get_viewport_rect().size.y/3)/1.22), 0.75)
	tween.tween_property(self, "rect_position", Vector2(self.rect_position.x-152, self.rect_position.y-158), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(544, 320), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,1), 0.5)

func _process(_delta):
	if maximized == true && max_anim_done == true:
		rect_position = Vector2(0,20)
	
	elif maximized == false:
		self.prev_size = rect_size
		self.prev_pos = rect_position

func _on_CloseButton_pressed():
	maximized = false
	print("emitting signal with parameter " + self.name)
	emit_signal("window_closed", self.name)
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "close_anim_done")
	tween.tween_property(self, "rect_position", Vector2(self.rect_position.x+152, self.rect_position.y+158), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color8(255,255,255,0), 0.75)


func _on_MaximizeButton_pressed():
	if max_anim_done == true:
		if maximized == false:
			max_anim_done = false
			maximized = true
			
			self.resizable = false
			"""print(OS.window_size.x)
			self.rect_size = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y-72)
			print(rect_size)
			self.rect_position = Vector2(0,20)"""
			
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.connect("finished", self, "maximize_anim_done")
			tween.tween_property(self, "rect_position", Vector2(0, 20), 0.5)
			tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y-72), 0.5)
		
		elif maximized == true:
			maximized = false
			
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(self, "rect_position", prev_pos, 0.5)
			tween.parallel().tween_property(self, "rect_size", prev_size, 0.5)
			self.resizable = true

func _on_MinimizeButton_pressed():
	emit_signal("window_hidden", self, false)
	#self.hide()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "minimize_anim_done")
	tween.tween_property(self, "rect_position", Vector2(self.rect_position.x+152, get_viewport_rect().size.y), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.75)

func close_anim_done():
	self.queue_free()

func minimize_anim_done(): 
	self.hide()
	maximized = false

func maximize_anim_done():
	max_anim_done = true

func window_size_changed():
	if maximized == true:
		max_anim_done = false
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.connect("finished", self, "maximize_anim_done")
		tween.tween_property(self, "rect_position", Vector2(0, 20), 0.5)
		tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y-72), 0.5)
