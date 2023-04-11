extends WindowDialog
class_name AppWindow

signal window_closed
signal window_hidden

var window_anim_playable = true
var maximized = false
var minimized = false
var snapped_left = false
var snapped_right = false
var prev_size = Vector2()
var prev_pos = Vector2()

var snap_primed = false
var snap_priming = false

var max_anim_done = true

var fling_speed := Vector2()
var window_resizing = false

var mouse_clicked = false

var window_min_size = Vector2(272,160)

func _ready():
	modulate = Color(0,0,0,0)
# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", self, "window_size_changed")
	
	self.rect_size = Vector2(240,0)
	self.rect_position = Vector2(get_viewport_rect().size.x/2.48, get_viewport_rect().size.y/2)
	get_close_button().hide()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "set_window_min_size", [false])
	#tween.tween_property(self, "rect_position", Vector2((get_viewport_rect().size.x/2)-self.rect_size.x/0.89, (get_viewport_rect().size.y/3)/1.22), 0.75)
	tween.tween_property(self, "rect_position", Vector2(self.rect_position.x-152, self.rect_position.y-158), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(544, 320), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,1), 0.5)
	
	if !OS.has_feature("debug"):
		$DebugLabel.queue_free()

func set_window_min_size(reset : bool):
	print("setting window min size.")
	rect_min_size = window_min_size
	if reset:
		rect_min_size = Vector2(0,0)

func _process(_delta):
	#print("Window State: " + str(minimized))
	
	if Global.fling_enabled == true:
		if $DebugLabel.visible == false and OS.has_feature("debug"):
			$DebugLabel.show()
		if prev_size != self.rect_size:
			window_resizing = true
		else:
			window_resizing = false
		fling_speed = Vector2(round(self.rect_position.x - prev_pos.x), round(self.rect_position.y - prev_pos.y))
		if OS.has_feature("debug"):
			if window_resizing and !snap_priming:
				$DebugLabel.text = "Resizing Window"
				pass
			else:
				if !snap_priming:
					$DebugLabel.text = "Fling: " + str(fling_speed)
				pass
				#fling_speed = Vector2(round(self.rect_position.x - prev_pos.x), round(self.rect_position.y - prev_pos.y))
	else:
		if OS.has_feature("debug"):
			if $DebugLabel.visible == true:
				$DebugLabel.hide()
	
	if maximized == true && max_anim_done == true:
		rect_position = Vector2(0,20)
	
	if snapped_left and max_anim_done and !mouse_clicked:
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.connect("finished", self, "maximize_anim_done")
		tween.tween_property(self, "rect_position", Vector2(0, 20), 0.25)
		tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y-80), 0.25)
	
	elif snapped_right and max_anim_done and !mouse_clicked:
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.connect("finished", self, "maximize_anim_done")
		tween.tween_property(self, "rect_position", Vector2(get_viewport_rect().size.x/2, 20), 0.25)
		tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y-80), 0.25)
	
	elif snapped_left == true && max_anim_done == true:
		$WindowRaiser.visible = false
		#rect_position = Vector2(0,20)
		if rect_position.x != 0 and mouse_clicked:
			print("unsnapping left.")
			snapped_left = false
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(self, "rect_size", prev_size, 0.5)
			self.resizable = true
	
	elif snapped_right == true && max_anim_done == true:
		$WindowRaiser.visible = false
		#rect_position = Vector2(get_viewport_rect().size.x/2,20)
		if rect_position.x != get_viewport_rect().size.x/2 and mouse_clicked:
			print("unsnapping right.")
			snapped_right = false
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(self, "rect_size", prev_size, 0.5)
			self.resizable = true
	
	if snap_primed and mouse_clicked:
		if rect_position.x < 0 or rect_position.x + rect_size.x > get_viewport_rect().size.x:
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property($SnapPanel, "modulate", Color(1,1,1,1), 0.75)
		else:
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property($SnapPanel, "modulate", Color(1,1,1,0), 0.75)
			snap_primed = false
			snap_priming = false
			$SnapTimer.stop()
	
	if !maximized and !snapped_left and !snapped_right:
		$WindowRaiser.visible = true
		self.prev_size = rect_size
		self.prev_pos = rect_position
	
	if get_index() < get_parent().get_child_count()-1:
		$WindowRaiser.raise()
	elif get_index() == get_parent().get_child_count()-1:
		move_child(get_node("WindowRaiser"), 0)
	else:
		move_child(get_node("WindowRaiser"), 0)
	
	if Global.bg_window_effect and !snapped_left and !snapped_right:
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property($WindowRaiser, "modulate", Color(1,1,1,1), 0.75)
	else:
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property($WindowRaiser, "modulate", Color(1,1,1,0), 0.75)
	
	#print(self.name + " is at position " + str(self.get_index()))
	#print("there are a total of " + str(get_parent().get_child_count()) + " children.")

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				raise()
				
			elif !event.pressed:
				if rect_position.x < 0:
					if Global.window_snap and snap_primed:
						print("snapping left")
						snap_left()
				
				elif rect_position.x + rect_size.x > get_viewport_rect().size.x:
					if Global.window_snap and snap_primed:
						print("snapping left")
						snap_right()
				
				if !snap_primed:
					$SnapTimer.stop()
				
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.tween_property($SnapPanel, "modulate", Color(1,1,1,0), 0.75)
				
				snap_priming = false
				snap_primed = false
	
			if event.pressed:
				mouse_clicked = true
				if OS.has_feature("debug"):
					$DebugLabel.text = str(mouse_clicked)
			else:
				mouse_clicked = false
				if OS.has_feature("debug"):
					$DebugLabel.text = str(mouse_clicked)
	
	if mouse_clicked and !snap_priming and Global.window_snap:
		if rect_position.x < 0:
			$SnapTimer.start(0)
			snap_priming = true
			if OS.has_feature("debug"):
				$DebugLabel.text = "priming left snapping"
		elif rect_position.x + rect_size.x > get_viewport_rect().size.x:
			$SnapTimer.start(0)
			snap_priming = true
			if OS.has_feature("debug"):
				$DebugLabel.text = "priming right snapping"
	
	if Global.fling_enabled == true:
		if !maximized and !snapped_left and !snapped_right:
			if event is InputEventMouseButton:
				if event.button_index == 1:
					if event.pressed:
						window_resizing = true
					else:
						window_resizing = false
			
			if event.is_action_released("LMB"):
				if fling_speed.y <= -15:
					_on_MaximizeButton_pressed()
				elif fling_speed.y >= 15:
					_on_MinimizeButton_pressed()
				elif fling_speed.x >= 15:
					close_window_right()
				elif fling_speed.x <= -15:
					close_window_left()
			
			if event is InputEventScreenTouch:
				if !event.pressed:
					if fling_speed.y <= -20:
						_on_MaximizeButton_pressed()
					elif fling_speed.y >= 20:
						_on_MinimizeButton_pressed()
					elif fling_speed.x >= 20:
						close_window_right()
					elif fling_speed.x <= -20:
						close_window_left()
		elif maximized:
			if event.is_action_released("LMB"):
				if fling_speed.y >= 20:
					_on_MaximizeButton_pressed()
			if event is InputEventScreenTouch:
				if !event.pressed:
					if fling_speed.y >= 20:
						_on_MaximizeButton_pressed()

func _on_SnapTimer_timeout():
	snap_primed = true
	
	$DebugLabel.text = "snap is primed"
	
	#var tween = get_tree().create_tween()
	#tween.set_ease(Tween.EASE_OUT)
	#tween.set_trans(Tween.TRANS_CUBIC)
	#tween.tween_property($SnapPanel, "modulate", Color(1,1,1,1), 0.75)
	
	$SnapPanel.raise()

func close_window():
	yield(get_tree().create_timer(0.15), "timeout")
	_on_CloseButton_pressed()

func _on_CloseButton_pressed():
	set_window_min_size(true)
	#maximized = false
	print("emitting signal with parameter " + self.name)
	emit_signal("window_closed", self.name)
	
	minimized = false
	snapped_left = false
	snapped_right = false
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "close_anim_done")
	tween.tween_property(self, "rect_position", Vector2((self.rect_position.x+self.rect_size.x/2)-120, (self.rect_position.y+self.rect_size.y/2)-20), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.75)

func close_window_left():
	set_window_min_size(true)
	maximized = false
	print("emitting signal with parameter " + self.name)
	emit_signal("window_closed", self.name)
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "close_anim_done")
	tween.tween_property(self, "rect_position", Vector2(0-self.rect_size.x, (self.rect_position.y+self.rect_size.y/2)-20), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.75)

func close_window_right():
	set_window_min_size(true)
	maximized = false
	print("emitting signal with parameter " + self.name)
	emit_signal("window_closed", self.name)
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.connect("finished", self, "close_anim_done")
	tween.tween_property(self, "rect_position", Vector2(get_viewport_rect().size.x+self.rect_size.x, (self.rect_position.y+self.rect_size.y/2)-20), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.75)

func snap_left():
	if max_anim_done == true:
		if snapped_left == false:
			raise()
			
			max_anim_done = false
			snapped_left = true
			
			self.resizable = false
			
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.connect("finished", self, "maximize_anim_done")
			tween.tween_property(self, "rect_position", Vector2(0, 20), 0.5)
			tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y-80), 0.5)

func snap_right():
	if max_anim_done == true:
		if snapped_right == false:
			raise()
			
			max_anim_done = false
			snapped_right = true
			
			self.resizable = false
			
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.connect("finished", self, "maximize_anim_done")
			tween.tween_property(self, "rect_position", Vector2(get_viewport_rect().size.x/2, 20), 0.5)
			tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y-80), 0.5)

func _on_MaximizeButton_pressed():
	if max_anim_done == true:
		if !maximized:
			raise()
			
			max_anim_done = false
			maximized = true
			snapped_left = false
			snapped_right = false
			
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
			tween.parallel().tween_property(self, "rect_size", Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y-80), 0.5)
		
		elif maximized:
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
	tween.tween_property(self, "rect_position", Vector2((self.rect_position.x+self.rect_size.x/2)-120, get_viewport_rect().size.y), 0.75)
	tween.parallel().tween_property(self, "rect_size", Vector2(240, 0), 0.75)
	tween.parallel().tween_property(self, "modulate", Color(1,1,1,0), 0.75)
	
	minimized = true
	maximized = false
	snapped_left = false
	snapped_right = false

func close_anim_done():
	self.queue_free()

func minimize_anim_done(): 
	self.hide()

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
