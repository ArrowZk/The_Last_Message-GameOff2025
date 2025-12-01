extends TowerBase
class_name AOETower

## Torre que hace daño de área a todos los enemigos en rango

@export var aoe_radius: float = 100.0  # Radio del área de efecto
@export var damage_per_second: float = 10.0  # Daño continuo

# Visual del área (opcional)
var area_visual: Sprite2D

func _ready() -> void:
	# Stats base
	base_damage = 5.0  # Daño por tick
	base_attack_range = 150.0
	base_attack_speed = 2.0  # 2 ticks por segundo
	cost = 150
	
	# Frecuencias disponibles
	available_frequencies = [
		Frequency.FrequencyType.YELLOW,
		Frequency.FrequencyType.RED
	]
	starting_frequency = Frequency.FrequencyType.YELLOW
	
	# No usa proyectiles
	projectile_scene = null
	rotate_to_target = false
	
	super._ready()
	
	create_area_visual()

func create_area_visual():
	"""Crea indicador visual del área de efecto"""
	area_visual = Sprite2D.new()
	# Aquí necesitarías un sprite circular semi-transparente
	# O crear uno con código:
	area_visual.modulate = Color(1.0, 0.3, 0.3, 0.3)  # Rojo semi-transparente
	area_visual.scale = Vector2(aoe_radius / 50.0, aoe_radius / 50.0)
	add_child(area_visual)

func attack() -> void:
	"""Ataque de área - daña a TODOS los enemigos en rango"""
	if not is_active:
		return
	
	if enemies_in_range.is_empty():
		return
	
	# Daño a todos los enemigos en rango
	for enemy in enemies_in_range:
		if enemy and is_instance_valid(enemy):
			apply_damage_to_target_aoe(enemy)
	
	# Efecto visual (opcional)
	show_aoe_effect()

func apply_damage_to_target_aoe(enemy: Node) -> void:
	"""Aplica daño a un enemigo con efectividad de frecuencia"""
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage, current_frequency)

func show_aoe_effect():
	"""Muestra efecto visual del ataque"""
	if area_visual:
		# Animación simple de pulso
		var original_scale = area_visual.scale
		var tween = create_tween()
		tween.tween_property(area_visual, "scale", original_scale * 1.3, 0.1)
		tween.tween_property(area_visual, "scale", original_scale, 0.1)
		
		# Flash de color
		tween.parallel().tween_property(area_visual, "modulate:a", 0.6, 0.1)
		tween.tween_property(area_visual, "modulate:a", 0.3, 0.1)

## Sobrescribir método para no usar proyectiles
func shoot_projectile() -> void:
	# AOE no usa proyectiles
	pass
