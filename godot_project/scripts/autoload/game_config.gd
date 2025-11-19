extends Node

# Game Configuration - Singleton

# Map
const MAP_WIDTH: int = 2000
const MAP_HEIGHT: int = 1500
const GRID_SIZE: int = 50

# Units
const UNIT_SIZE: float = 3.0
const ATTACK_RANGE: float = 15.0
const ATTACK_DAMAGE: float = 1.0
const MOVE_SPEED: float = 50.0

# Wall Building
const WALL_HEALTH: int = 5
const WALL_COST: int = 10
const WALL_SIZE: int = 4

# Tower Building
const TOWER_HEALTH: int = 20
const TOWER_COST: int = 50
const TOWER_RANGE: float = 150.0
const TOWER_DAMAGE: float = 0.5
const TOWER_SIZE: int = 12
const TOWER_UNIT_GEN_RATE: float = 3.0  # seconds
const TOWER_MAX_STORED: int = 50
const TOWER_SPAWN_RADIUS: float = 30.0
const TOWER_AURA_RANGE: float = 50.0
const TOWER_AURA_BONUS: float = 0.5

# Economy
const STARTING_PIXELS: int = 500
const INCOME_PER_TERRITORY: int = 1
const INCOME_INTERVAL: float = 5.0  # seconds
const BASE_POP_CAP: int = 1000
const POP_PER_TOWER: int = 100

# Territory
const TERRITORY_SIZE: int = 25

# Spatial Hash
const CELL_SIZE: int = 50

# AI
const AI_UPDATE_INTERVAL: float = 2.0  # seconds

# Bonuses
const WALL_DEFENSE_BONUS: float = 0.3
const TOWER_DEFENSE_BONUS: float = 0.5

# Colors
const PLAYER_COLORS: Dictionary = {
	1: Color("#4ade80"),  # Green
	2: Color("#ef4444")   # Red
}

const UI_COLORS: Dictionary = {
	"background": Color("#1a1a2e"),
	"panel": Color("#16213e"),
	"border": Color("#0f3460"),
	"accent": Color("#e94560"),
	"text": Color("#ffffff"),
	"gold": Color("#ffd700")
}
