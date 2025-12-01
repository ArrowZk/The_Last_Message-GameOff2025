extends Node2D
class_name TowerBase

## ========================================
## CONFIGURACIÓN BASE
## ========================================
@export_group("Stats Base")
@export var base_damage: float = 10.0
@export var base_attack_range: float = 150.0
@export var base_attack_speed: float = 1.0
@export var cost: int = 100
@export var height_offset: float = 0

@export_group("Frequencies")
@export var available_frequencies: Array[Frequency.FrequencyType] = [
	Frequency.FrequencyType.BLUE,
	Frequency.FrequencyType.YELLOW
]
@export var starting_frequency: Frequency.FrequencyType = Frequency.FrequencyType.BLUE

@export_group("Visual")
@export var tower_sprite: Texture2D
@export var projectile_scene: PackedScene


@export_group("Behavior")
@export var rotate_to_target: bool = false

## Variables de frecuencia activa
var current_frequency: Frequency.FrequencyType
var current_frequency_data: Dictionary

## Stats calculados (base * multiplicadores de frecuencia)
var damage: float
var attack_range: float
var attack_speed: float

## Estado de activación
var is_active: bool = true  # Se desactiva si no puede usar frecuencia global

## Nodos
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var range_area: Area2D = $RangeArea if has_node("RangeArea") else null
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D if has_node("RangeArea/CollisionShape2D") else null
@onready var attack_timer: Timer = $AttackTimer if has_node("AttackTimer") else null
@onready var frequency_indicator: Sprite2D = $FrequencyIndicator if has_node("FrequencyIndicator") else null

## Sistema de cola FIFO
var enemies_in_range: Array = []
var current_target: Node = null

enum TowerState { IDLE, ATTACKING }
var current_state: TowerState = TowerState.IDLE

## Señales
signal frequency_changed(new_frequency: Frequency.FrequencyType)
signal target_acquired(enemy: Node)
signal target_lost()
signal tower_deactivated()
signal tower_activated()

## ========================================
## INICIALIZACIÓN
## ========================================
func _ready() -> void:
	add_to_group("towers")
	set_frequency(starting_frequency)
	setup_tower()
	connect_signals()

func setup_tower() -> void:
	# Configurar sprite
	if tower_sprite and sprite:
		sprite.texture = tower_sprite
	
	# Configurar rango (se actualiza en set_frequency)
	if range_collision:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = attack_range
		range_collision.shape = circle_shape
	elif not range_area:
		# Crear Area2D y CollisionShape2D si no existen
		push_warning("Torre '%s' no tiene RangeArea, creando automáticamente..." % name)
		_create_range_area()
	
	# Configurar timer
	if attack_timer:
		attack_timer.wait_time = 1.0 / attack_speed
		attack_timer.one_shot = false
		attack_timer.start()
	else:
		# Crear timer si no existe
		push_warning("Torre '%s' no tiene AttackTimer, creando automáticamente..." % name)
		_create_attack_timer()

func _create_range_area() -> void:
	"""Crea RangeArea automáticamente si no existe"""
	range_area = Area2D.new()
	range_area.name = "RangeArea"
	add_child(range_area)
	
	range_collision = CollisionShape2D.new()
	range_collision.name = "CollisionShape2D"
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = attack_range
	range_collision.shape = circle_shape
	range_area.add_child(range_collision)
	
	# Reconectar señales
	connect_signals()

func _create_attack_timer() -> void:
	"""Crea AttackTimer automáticamente si no existe"""
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.one_shot = false
	add_child(attack_timer)
	
	# Reconectar señales
	connect_signals()

func connect_signals() -> void:
	if range_area:
		range_area.body_entered.connect(_on_enemy_entered_range)
		range_area.body_exited.connect(_on_enemy_exited_range)
	
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)

## ========================================
## SISTEMA DE FRECUENCIAS
## ========================================
func set_frequency(freq: Frequency.FrequencyType) -> void:
	"""Cambia la frecuencia activa de la torre"""
	# Verificar si la torre puede usar esta frecuencia
	if not freq in available_frequencies:
		# Torre NO puede usar esta frecuencia - DESACTIVAR
		deactivate_tower()
		return
	
	# Torre puede usar esta frecuencia - ACTIVAR
	if not is_active:
		activate_tower()
	
	current_frequency = freq
	current_frequency_data = Frequency.get_frequency_data(freq)
	
	# Recalcular stats
	_recalculate_stats()
	
	# Actualizar visual cuando este listos los sprites
	#_update_frequency_visual()
	
	# Emitir señal
	frequency_changed.emit(freq)
	
	print("Torre %s cambió a frecuencia %s" % [name, current_frequency_data.name])

func deactivate_tower() -> void:
	"""Desactiva la torre (no puede usar frecuencia global actual)"""
	if not is_active:
		return
	
	is_active = false
	
	# Detener timer de ataque
	if attack_timer:
		attack_timer.stop()
	
	# Visual de desactivación
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Gris semi-transparente
	
	if frequency_indicator:
		frequency_indicator.visible = false
	
	# Limpiar objetivos
	current_target = null
	#enemies_in_range.clear()
	
	tower_deactivated.emit()
	print("⚠️ Torre %s DESACTIVADA (no puede usar frecuencia global actual)" % name)

func activate_tower() -> void:
	"""Activa la torre"""
	if is_active:
		return
	
	is_active = true
	
	# Reactivar timer
	if attack_timer:
		attack_timer.start()
	
	# Restaurar visual
	if sprite:
		sprite.modulate = Color.WHITE
	
	tower_activated.emit()
	print("✅ Torre %s ACTIVADA" % name)

func _recalculate_stats() -> void:
	"""Recalcula stats aplicando multiplicadores de frecuencia"""
	damage = base_damage * current_frequency_data.damage_mult
	attack_range = base_attack_range * current_frequency_data.range_mult
	attack_speed = base_attack_speed * current_frequency_data.speed_mult
	
	# Actualizar rango de detección
	if range_collision and range_collision.shape:
		range_collision.shape.radius = attack_range
	
	# Actualizar timer
	if attack_timer:
		attack_timer.wait_time = 1.0 / attack_speed

func _update_frequency_visual() -> void:
	"""Actualiza el indicador visual de frecuencia"""
	var freq_color = current_frequency_data.color
	
	# Modular sprite con color de frecuencia
	if sprite:
		sprite.modulate = Color.WHITE.lerp(freq_color, 0.4)
	
	# Actualizar indicador posible sprite por encima del de la torre - quizas iluminacion
	if frequency_indicator:
		frequency_indicator.modulate = freq_color
		frequency_indicator.visible = true

func cycle_frequency() -> void:
	"""Cicla a la siguiente frecuencia disponible"""
	var current_index = available_frequencies.find(current_frequency)
	var next_index = (current_index + 1) % available_frequencies.size()
	set_frequency(available_frequencies[next_index])

func can_use_frequency(freq: Frequency.FrequencyType) -> bool:
	"""Verifica si la torre puede usar una frecuencia"""
	return freq in available_frequencies

## ========================================
## LÓGICA DE ATAQUE
## ========================================
func _process(delta: float) -> void:
	# Si está desactivada, no hacer nada
	if not is_active:
		return
	
	clean_dead_enemies()
	update_current_target()
	
	if current_target and is_instance_valid(current_target):
		current_state = TowerState.ATTACKING
	else:
		current_state = TowerState.IDLE

func clean_dead_enemies() -> void:
	"""Limpia enemigos muertos de la cola"""
	enemies_in_range = enemies_in_range.filter(func(enemy): 
		return enemy and is_instance_valid(enemy)
	)

func update_current_target() -> void:
	"""Actualiza el objetivo (primero de la cola)"""
	if enemies_in_range.is_empty():
		if current_target:
			target_lost.emit()
			current_target = null
	else:
		var new_target = enemies_in_range[0]
		if new_target != current_target:
			current_target = new_target
			target_acquired.emit(current_target)
		
		if not is_instance_valid(current_target):
			enemies_in_range.pop_front()
			update_current_target()

func _on_attack_timer_timeout() -> void:
	"""Timer de ataque"""
	# Solo atacar si está activa
	if is_active and current_state == TowerState.ATTACKING and current_target:
		attack()

func attack() -> void:
	"""Ejecuta un ataque"""
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Rotar si está habilitado
	if rotate_to_target:
		look_at(current_target.global_position)
	
	# Disparar
	if projectile_scene:
		shoot_projectile()
	else:
		apply_damage_to_target()

func shoot_projectile() -> void:
	"""Instancia y dispara un proyectil"""
	if not projectile_scene:
		push_error("Torre no tiene projectile_scene asignado")
		return
	
	var projectile = projectile_scene.instantiate()
	
	# Agregar al nivel
	var level = get_tree().get_first_node_in_group("level")
	if level:
		level.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = global_position
	
	# Configurar proyectil con frecuencia
	if projectile.has_method("setup"):
		projectile.setup(current_target, damage, current_frequency)
	else:
		push_warning("Proyectil no tiene método setup()")

func apply_damage_to_target() -> void:
	"""Daño instantáneo"""
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(damage, current_frequency)

## ========================================
## EVENTOS DE RANGO
## ========================================
func _on_enemy_entered_range(body: Node) -> void:
	"""Enemigo entra al rango"""
	if not body.is_in_group("enemies"):
		return
	
	if body in enemies_in_range:
		return
	
	enemies_in_range.append(body)

func _on_enemy_exited_range(body: Node) -> void:
	"""Enemigo sale del rango"""
	if body in enemies_in_range:
		enemies_in_range.erase(body)
	
	if body == current_target:
		current_target = null

## ========================================
## MEJORAS (UPGRADES)
## ========================================
func upgrade_damage(amount: float) -> void:
	base_damage += amount
	_recalculate_stats()

func upgrade_range(amount: float) -> void:
	base_attack_range += amount
	_recalculate_stats()

func upgrade_attack_speed(amount: float) -> void:
	base_attack_speed += amount
	_recalculate_stats()

## ========================================
## INFORMACIÓN
## ========================================
func get_tower_info() -> Dictionary:
	return {
		"base_damage": base_damage,
		"current_damage": damage,
		"base_range": base_attack_range,
		"current_range": attack_range,
		"base_speed": base_attack_speed,
		"current_speed": attack_speed,
		"cost": cost,
		"frequency": current_frequency_data.name,
		"frequency_color": current_frequency_data.color,
		"available_frequencies": available_frequencies,
		"enemies_in_range": enemies_in_range.size()
	}
