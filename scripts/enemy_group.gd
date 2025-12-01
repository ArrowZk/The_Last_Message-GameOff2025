extends Resource
class_name EnemyGroup

## Recurso que define un grupo de enemigos en una oleada

## Tipo de enemigo (key del diccionario en EnemyManager)
@export var enemy_type: String = "e1"

## Cantidad total de enemigos de este tipo
@export var count: int = 5

## Intervalo entre spawns (segundos)
@export var spawn_interval: float = 1.0

## Índice del spawn point (0 = primero, 1 = segundo, etc.)
@export var spawn_point_index: int = 0

## Delay antes de empezar a spawnear este grupo (relativo al inicio de la oleada)
@export var start_delay: float = 0.0

## Constructor para crear desde código
func _init(type: String = "e1", qty: int = 5, interval: float = 1.0, spawn_idx: int = 0, delay: float = 0.0):
	enemy_type = type
	count = qty
	spawn_interval = interval
	spawn_point_index = spawn_idx
	start_delay = delay
