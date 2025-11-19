extends Control

var game_manager: Node2D

func _draw() -> void:
	if not game_manager:
		return

	var w = size.x
	var h = size.y
	var scale_x = w / GameConfig.MAP_WIDTH
	var scale_y = h / GameConfig.MAP_HEIGHT

	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0a0a15"))

	# Draw territories
	for territory in game_manager.territories:
		if territory.owner != 0:
			var color = GameConfig.PLAYER_COLORS[territory.owner]
			color.a = 0.4
			draw_rect(Rect2(
				territory.x * scale_x,
				territory.y * scale_y,
				GameConfig.TERRITORY_SIZE * scale_x,
				GameConfig.TERRITORY_SIZE * scale_y
			), color)

	# Draw buildings
	for building in game_manager.buildings:
		if not is_instance_valid(building):
			continue
		var color = GameConfig.PLAYER_COLORS[building.owner_id]
		var bsize = 4 if building.building_type == "tower" else 2
		draw_rect(Rect2(
			building.global_position.x * scale_x - bsize / 2,
			building.global_position.y * scale_y - bsize / 2,
			bsize,
			bsize
		), color)

	# Draw unit clusters
	var unit_counts = {}
	for unit in game_manager.units:
		if not is_instance_valid(unit):
			continue
		var key = "%d,%d,%d" % [int(unit.global_position.x / 50), int(unit.global_position.y / 50), unit.owner_id]
		if not unit_counts.has(key):
			unit_counts[key] = 0
		unit_counts[key] += 1

	for key in unit_counts.keys():
		var parts = key.split(",")
		var ux = int(parts[0])
		var uy = int(parts[1])
		var owner = int(parts[2])
		var count = unit_counts[key]

		var color = GameConfig.PLAYER_COLORS[owner]
		var usize = min(4, 1 + count / 10.0)
		draw_rect(Rect2(
			ux * 50 * scale_x,
			uy * 50 * scale_y,
			usize,
			usize
		), color)

	# Draw camera viewport
	var camera = game_manager.camera
	if camera:
		var viewport_size = get_viewport_rect().size / camera.zoom
		draw_rect(Rect2(
			(camera.position.x - viewport_size.x / 2) * scale_x,
			(camera.position.y - viewport_size.y / 2) * scale_y,
			viewport_size.x * scale_x,
			viewport_size.y * scale_y
		), Color.WHITE, false, 1.0)
