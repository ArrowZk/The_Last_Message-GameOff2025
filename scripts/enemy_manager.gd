extends Node
class_name EnemyManager

## ========================================
## CONFIGURACIÓN
## ========================================
@onready var enemies_root = $"../Enemies"

## Diccionario de escenas de enemigos
## Key = ID del enemigo, Value = PackedScene
var enemy_scenes := {
	"e1": preload("res://scenes/enemies/enemy_test.tscn"),
	# "e2": preload("res://scenes/enemies/enemy_fast.tscn"),
	"e2": preload("res://scenes/enemies/enemy_tank.tscn"),
	# "e4": preload("res://scenes/enemies/enemy_boss.tscn"),
}

## Plantillas de configuración para enemigos
var enemy_templates := {
	"e1": {
		"name": "Basic Alien",
		"health": 100,
		"speed": 60,
		"damage": 10,
		"reward": 25,
		"frequency": Frequency.FrequencyType.YELLOW
	},
		"e2": {
		"name": "Tank Alien",
		"health": 250,
		"speed": 30,
		"damage": 50,
		"reward": 50,
		"frequency": Frequency.FrequencyType.RED
	},
	# "e3": {
	#     "name": "Alien Tanque",
	#     "health": 300,
	#     "speed": 30,
	#     "damage": 25,
	#     "reward": 30,
	#     "frequency": Frequency.FrequencyType.RED
	# },
}

## Estadísticas
var total_enemies_spawned: int = 0
var enemies_killed_by_frequency := {
	Frequency.FrequencyType.BLUE: 0,
	Frequency.FrequencyType.YELLOW: 0,
	Frequency.FrequencyType.RED: 0
}

## ========================================
## SPAWNING
## ========================================
func spawn_enemy(type: String, pos: Vector2) -> Node:
	"""Spawns un enemigo en una posición"""
	if not enemy_scenes.has(type):
		push_error("Tipo de enemigo no existe: %s" % type)
		return null
	
	var enemy_scene = enemy_scenes[type]
	var enemy = enemy_scene.instantiate()
	
	enemy.global_position = pos
	enemies_root.add_child(enemy)
	
	# Aplicar plantilla si existe
	if enemy_templates.has(type):
		apply_template(enemy, enemy_templates[type])
	
	total_enemies_spawned += 1
	
	print("👾 Spawned: %s en %s" % [type, pos])
	
	return enemy

func apply_template(enemy: Node, template: Dictionary) -> void:
	"""Aplica una plantilla de configuración a un enemigo"""
	if template.has("health") and "max_health" in enemy:
		enemy.max_health = template.health
		enemy.health = template.health
	
	if template.has("speed") and "speed" in enemy:
		enemy.speed = template.speed
	
	if template.has("damage") and "damage" in enemy:
		enemy.damage = template.damage
	
	if template.has("reward") and "reward" in enemy:
		enemy.reward = template.reward
	
	if template.has("frequency") and "frequency" in enemy:
		enemy.frequency = template.frequency

## ========================================
## REGISTRO Y UTILIDADES
## ========================================
func register_enemy_type(id: String, scene_path: String, template: Dictionary = {}) -> void:
	"""Registra un nuevo tipo de enemigo dinámicamente"""
	var scene = load(scene_path)
	if scene:
		enemy_scenes[id] = scene
		if not template.is_empty():
			enemy_templates[id] = template
		print("✅ Enemigo registrado: %s" % id)
	else:
		push_error("No se pudo cargar escena: %s" % scene_path)

func get_enemy_info(type: String) -> Dictionary:
	"""Retorna información de un tipo de enemigo"""
	if enemy_templates.has(type):
		return enemy_templates[type].duplicate()
	return {}

func get_available_enemy_types() -> Array:
	"""Retorna lista de IDs de enemigos disponibles"""
	return enemy_scenes.keys()

func get_enemies_alive() -> Array:
	"""Retorna array de enemigos vivos"""
	if enemies_root:
		return enemies_root.get_children()
	return []

func get_enemies_count() -> int:
	"""Retorna cantidad de enemigos vivos"""
	if enemies_root:
		return enemies_root.get_child_count()
	return 0

func kill_all_enemies() -> void:
	"""Mata todos los enemigos (útil para debugging)"""
	var enemies = get_enemies_alive()
	for enemy in enemies:
		enemy.queue_free()

## ========================================
## ESTADÍSTICAS
## ========================================
func record_kill(enemy_frequency: Frequency.FrequencyType) -> void:
	"""Registra la muerte de un enemigo por frecuencia"""
	if enemies_killed_by_frequency.has(enemy_frequency):
		enemies_killed_by_frequency[enemy_frequency] += 1

func get_stats() -> Dictionary:
	"""Retorna estadísticas del EnemyManager"""
	return {
		"total_spawned": total_enemies_spawned,
		"current_alive": get_enemies_count(),
		"kills_by_frequency": enemies_killed_by_frequency.duplicate()
	}

func reset_stats() -> void:
	"""Resetea estadísticas"""
	total_enemies_spawned = 0
	enemies_killed_by_frequency = {
		Frequency.FrequencyType.BLUE: 0,
		Frequency.FrequencyType.YELLOW: 0,
		Frequency.FrequencyType.RED: 0
	}
