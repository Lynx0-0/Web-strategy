extends Node2D

# This script handles rendering of selection box, build preview, grid, and territories

var game_manager: Node2D
var camera: Camera2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not game_manager or not camera:
		return

	draw_grid()
	draw_territories()
	draw_selection_box()
	draw_build_preview()

func draw_grid() -> void:
	var cam_pos = camera.position
	var viewport_size = get_viewport_rect().size / camera.zoom
	var half_viewport = viewport_size / 2

	var start_x = floor((cam_pos.x - half_viewport.x) / GameConfig.GRID_SIZE) * GameConfig.GRID_SIZE
	var start_y = floor((cam_pos.y - half_viewport.y) / GameConfig.GRID_SIZE) * GameConfig.GRID_SIZE
	var end_x = cam_pos.x + half_viewport.x
	var end_y = cam_pos.y + half_viewport.y

	var grid_color = Color("#1a1a2e")

	var x = start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
		x += GameConfig.GRID_SIZE

	var y = start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
		y += GameConfig.GRID_SIZE

func draw_territories() -> void:
	for territory in game_manager.territories:
		if territory.owner != 0:
			var color = GameConfig.PLAYER_COLORS[territory.owner]
			color.a = 0.125  # Semi-transparent
			draw_rect(Rect2(
				territory.x,
				territory.y,
				GameConfig.TERRITORY_SIZE,
				GameConfig.TERRITORY_SIZE
			), color)

func draw_selection_box() -> void:
	var cam_controller = camera as Node2D
	if cam_controller.has_method("get_selection_rect"):
		var rect = cam_controller.get_selection_rect()
		if rect.size != Vector2.ZERO:
			draw_rect(rect, Color(0.29, 0.87, 0.5, 0.1))  # Fill
			draw_rect(rect, Color("#4ade80"), false, 1.0)  # Border

func draw_build_preview() -> void:
	if game_manager.build_mode == "":
		return

	var mouse_pos = camera.get_mouse_world_position() if camera.has_method("get_mouse_world_position") else get_global_mouse_position()
	var can_afford = true
	var size: int
	var cost: int

	if game_manager.build_mode == "tower":
		size = GameConfig.TOWER_SIZE
		cost = GameConfig.TOWER_COST
	else:
		size = GameConfig.WALL_SIZE
		cost = GameConfig.WALL_COST

	can_afford = game_manager.players[1].pixels >= cost

	var preview_color = Color("#4ade80") if can_afford else Color("#ef4444")
	preview_color.a = 0.5

	if game_manager.build_mode == "tower":
		draw_circle(mouse_pos, size, preview_color)

		# Range preview
		var range_color = Color("#4ade80")
		range_color.a = 0.3
		var dash_count = 32
		for i in range(dash_count):
			if i % 2 == 0:
				var start_angle = (float(i) / dash_count) * TAU
				var end_angle = (float(i + 1) / dash_count) * TAU
				draw_arc(mouse_pos, GameConfig.TOWER_RANGE, start_angle, end_angle, 8, range_color, 1.0)
	else:
		draw_rect(Rect2(
			mouse_pos.x - size / 2.0,
			mouse_pos.y - size / 2.0,
			size,
			size
		), preview_color)
