extends Node2D
class_name Projectile

## ==================================================
## PROYECTIL CON SISTEMA DE FRECUENCIAS
## ==================================================

@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var homing: bool = true

## Variables de proyectil
var target: Node = null
var damage: float = 10.0
var frequency: Frequency.FrequencyType = Frequency.FrequencyType.YELLOW
var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

## Nodos
@onready var sprite: Sprite2D = $Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer

## ==================================================
## INICIALIZACIÓN
## ==================================================
func _ready() -> void:
	setup_lifetime_timer()
	setup_visual()

func setup_lifetime_timer() -> void:
	"""Configura el timer de vida del proyectil"""
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()
	else:
		# Crear timer si no existe
		lifetime_timer = Timer.new()
		add_child(lifetime_timer)
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

func setup(new_target: Node, new_damage: float, proj_frequency: Frequency.FrequencyType) -> void:
	"""Configura proyectil con objetivo, daño y frecuencia"""
	target = new_target
	damage = new_damage
	frequency = proj_frequency
	
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		
		if sprite:
			rotation = direction.angle()
	else:
		push_warning("Projectile created without valid target")
	
	setup_visual()

func setup_visual() -> void:
	"""Configura color del proyectil según frecuencia"""
	if not sprite:
		return
	
	var freq_data = Frequency.get_frequency_data(frequency)
	sprite.modulate = freq_data.color

## ==================================================
## MOVIMIENTO Y COLISIÓN
## ==================================================
func _process(delta: float) -> void:
	# Si el objetivo murió, continuar en línea recta
	if not is_instance_valid(target):
		global_position += velocity * delta
		return
	
	# Seguimiento del objetivo (homing)
	if homing:
		direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		
		if sprite:
			rotation = direction.angle()
	
	# Mover proyectil
	global_position += velocity * delta
	
	# Verificar colisión con objetivo
	if target and is_instance_valid(target):
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target < 15:  # Radio de impacto
			hit_target()

func hit_target() -> void:
	"""Aplica daño al objetivo con efectividad de frecuencia"""
	if target and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(damage, frequency)
		else:
			push_warning("Target doesn't have take_damage() method")
	
	destroy()

func destroy() -> void:
	"""Destruye el proyectil"""
	# Aquí se pueden agregar partículas de impacto
	queue_free()

func _on_lifetime_timeout() -> void:
	"""Destruye el proyectil si excede su tiempo de vida"""
	destroy()
