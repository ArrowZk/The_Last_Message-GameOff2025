extends Node2D
class_name MainTower

## ==================================================
## TORRE PRINCIPAL - Objetivo que los enemigos atacan
## ==================================================

@export var max_health: float = 1000.0

var health: float

## Señales
signal health_changed(new_health: float)
signal base_destroyed()

## ==================================================
## INICIALIZACIÓN
## ==================================================
func _ready():
	add_to_group("main_tower") 
	health = max_health
	print("Main Tower initialized | Health: %d" % health)

## ==================================================
## SISTEMA DE DAÑO
## ==================================================
func take_damage(amount: float):
	"""Recibe daño de enemigos"""
	health -= amount
	health = max(0, health)  # No bajar de 0
	
	health_changed.emit(health)
	
	print("Main Tower damaged | Health: %.0f/%.0f (%.1f%%)" % [
		health, 
		max_health, 
		(health / max_health) * 100
	])
	
	if health <= 0:
		die()

func die():
	"""Destrucción de la base"""
	print("💥 Main Tower destroyed!")
	base_destroyed.emit()

## ==================================================
## UTILIDADES
## ==================================================
func get_health_percentage() -> float:
	"""Retorna porcentaje de vida (0.0 a 1.0)"""
	return health / max_health

func heal(amount: float):
	"""Cura la torre (opcional para power-ups)"""
	health = min(health + amount, max_health)
	health_changed.emit(health)
