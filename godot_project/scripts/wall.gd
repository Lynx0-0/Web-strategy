extends StaticBody2D

signal destroyed

var owner_id: int = 1
var health: float = GameConfig.WALL_HEALTH
var max_health: float = GameConfig.WALL_HEALTH
var building_type: String = "wall"
var size: int = GameConfig.WALL_SIZE
var game_manager: Node2D

func _ready() -> void:
	add_to_group("buildings")

func _process(_delta: float) -> void:
	queue_redraw()

func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		emit_signal("destroyed")
		game_manager.remove_entity(self)

func _draw() -> void:
	var color = GameConfig.PLAYER_COLORS[owner_id]

	# Wall body
	var rect = Rect2(-size / 2.0, -size / 2.0, size, size)
	draw_rect(rect, color)

	# Darker outline
	draw_rect(rect, Color.BLACK, false, 1.0)
