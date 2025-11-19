extends Camera2D

@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var game_manager: Node2D

var is_selecting: bool = false
var selection_start: Vector2 = Vector2.ZERO
var selection_end: Vector2 = Vector2.ZERO

var mouse_world_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set zoom limits
	zoom = Vector2.ONE

func _process(delta: float) -> void:
	handle_camera_movement(delta)
	handle_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventKey:
		handle_key(event)

func handle_camera_movement(delta: float) -> void:
	var movement = Vector2.ZERO

	if Input.is_action_pressed("camera_up"):
		movement.y -= 1
	if Input.is_action_pressed("camera_down"):
		movement.y += 1
	if Input.is_action_pressed("camera_left"):
		movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		movement.x += 1

	if movement != Vector2.ZERO:
		position += movement.normalized() * pan_speed * delta

	# Clamp camera position
	var viewport_size = get_viewport_rect().size / zoom
	position.x = clamp(position.x, viewport_size.x / 2, GameConfig.MAP_WIDTH - viewport_size.x / 2)
	position.y = clamp(position.y, viewport_size.y / 2, GameConfig.MAP_HEIGHT - viewport_size.y / 2)

func handle_mouse_position() -> void:
	mouse_world_pos = get_global_mouse_position()

func handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start selection or place building
			if game_manager.build_mode != "":
				game_manager.try_place_building(mouse_world_pos)
			else:
				is_selecting = true
				selection_start = mouse_world_pos
				selection_end = mouse_world_pos
		else:
			# End selection
			if is_selecting:
				complete_selection()
				is_selecting = false

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# Issue command
			game_manager.issue_command(mouse_world_pos)

	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom in
		var new_zoom = clamp(zoom.x * (1 + zoom_speed), min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom out
		var new_zoom = clamp(zoom.x * (1 - zoom_speed), min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_selecting:
		selection_end = get_global_mouse_position()

func handle_key(event: InputEventKey) -> void:
	if not event.pressed:
		return

	# Select all
	if event.keycode == KEY_A and event.ctrl_pressed:
		game_manager.select_all_player_units()
		get_viewport().set_input_as_handled()

	# Build shortcuts
	elif event.keycode == KEY_Q and not event.ctrl_pressed:
		game_manager.set_build_mode("wall")
	elif event.keycode == KEY_E and not event.ctrl_pressed:
		game_manager.set_build_mode("tower")

	# Cancel
	elif event.keycode == KEY_ESCAPE:
		if game_manager.build_mode != "":
			game_manager.set_build_mode("")
		else:
			game_manager.selected_units.clear()
			game_manager.emit_signal("selection_changed", [])

	# Control groups
	elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var group_num = event.keycode - KEY_0
		if event.ctrl_pressed:
			# Assign control group
			game_manager.control_groups[group_num] = game_manager.selected_units.duplicate()
		else:
			# Select control group
			if game_manager.control_groups.has(group_num):
				game_manager.selected_units = game_manager.control_groups[group_num].filter(
					func(u): return is_instance_valid(u) and u.health > 0
				)
				game_manager.emit_signal("selection_changed", game_manager.selected_units)

func complete_selection() -> void:
	var rect = Rect2()
	rect.position = Vector2(min(selection_start.x, selection_end.x), min(selection_start.y, selection_end.y))
	rect.size = Vector2(abs(selection_end.x - selection_start.x), abs(selection_end.y - selection_start.y))

	game_manager.select_units_in_rect(rect)

func get_selection_rect() -> Rect2:
	if not is_selecting:
		return Rect2()

	var rect = Rect2()
	rect.position = Vector2(min(selection_start.x, selection_end.x), min(selection_start.y, selection_end.y))
	rect.size = Vector2(abs(selection_end.x - selection_start.x), abs(selection_end.y - selection_start.y))
	return rect

func get_mouse_world_position() -> Vector2:
	return mouse_world_pos
