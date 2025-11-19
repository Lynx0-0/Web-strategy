extends Node

# Spatial Hash for efficient collision detection - Singleton

var cell_size: int = 50
var cells: Dictionary = {}

func _ready() -> void:
	cell_size = GameConfig.CELL_SIZE

func clear() -> void:
	cells.clear()

func get_key(x: float, y: float) -> String:
	var cx: int = int(floor(x / cell_size))
	var cy: int = int(floor(y / cell_size))
	return "%d,%d" % [cx, cy]

func insert(entity: Node2D) -> void:
	var key: String = get_key(entity.global_position.x, entity.global_position.y)
	if not cells.has(key):
		cells[key] = []
	cells[key].append(entity)

func query(pos: Vector2, range_val: float) -> Array:
	var results: Array = []
	var min_cx: int = int(floor((pos.x - range_val) / cell_size))
	var max_cx: int = int(floor((pos.x + range_val) / cell_size))
	var min_cy: int = int(floor((pos.y - range_val) / cell_size))
	var max_cy: int = int(floor((pos.y + range_val) / cell_size))

	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key: String = "%d,%d" % [cx, cy]
			if cells.has(key):
				for entity in cells[key]:
					if is_instance_valid(entity):
						var dist_sq: float = pos.distance_squared_to(entity.global_position)
						if dist_sq <= range_val * range_val:
							results.append(entity)

	return results

func query_rect(rect: Rect2) -> Array:
	var results: Array = []
	var min_cx: int = int(floor(rect.position.x / cell_size))
	var max_cx: int = int(floor(rect.end.x / cell_size))
	var min_cy: int = int(floor(rect.position.y / cell_size))
	var max_cy: int = int(floor(rect.end.y / cell_size))

	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var key: String = "%d,%d" % [cx, cy]
			if cells.has(key):
				for entity in cells[key]:
					if is_instance_valid(entity):
						if rect.has_point(entity.global_position):
							results.append(entity)

	return results
