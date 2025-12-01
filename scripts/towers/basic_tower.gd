extends TowerBase
class_name BasicTower

## Torre básica con ataque simple
## Hereda toda la funcionalidad de TowerBase

func _ready() -> void:
	# Configurar stats específicos de esta torre
	damage = 15.0
	attack_range = 200.0
	attack_speed = 1.5
	cost = 100
	
	# IMPORTANTE: Para torres isométricas, no rotar
	rotate_to_target = false
	
	# Llamar al ready del padre
	super._ready()
	
	# Configuraciones adicionales específicas
	setup_basic_tower()

func setup_basic_tower() -> void:
	# Agregar la torre al grupo para fácil identificación
	add_to_group("basic_towers")
	
	print("BasicTower creada - Damage:", damage, " Range:", attack_range, " Speed:", attack_speed)

## Ejemplo de método especial para esta torre
func upgrade() -> void:
	upgrade_damage(5)
	upgrade_attack_speed(0.2)
	print("BasicTower mejorada! Nuevo daño:", damage, " Nueva velocidad:", attack_speed)
