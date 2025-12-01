extends CharacterBody2D
class_name EnemyBase

## ==================================================
## CONFIGURACIÓN BASE
## ==================================================
@export_group("Stats")
@export var max_health: float = 100.0
@export var speed: float = 60.0
@export var damage: float = 10.0
@export var reward: int = 10

@export_group("Frequency")
@export var frequency: Frequency.FrequencyType = Frequency.FrequencyType.YELLOW
@export var show_frequency_indicator: bool = true

@export_group("Combat")
@export var attack_range: float = 32.0  # Rango para entrar en modo ataque
@export var attack_cooldown: float = 1.0  # Tiempo entre ataques

## ==================================================
## VARIABLES INTERNAS
## ==================================================
var health: float
var current_frequency_color: Color
var attack_timer: float = 0.0

## Estados
enum State { IDLE, MOVE, ATTACK, DEAD }
var state: State = State.IDLE

## ==================================================
## NODOS
## ==================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var frequency_indicator: Sprite2D = $FrequencyIndicator

## ==================================================
## REFERENCIAS
## ==================================================
var level_manager: Node
var target_position: Vector2
var main_tower_node: Node = null

## ==================================================
## INICIALIZACIÓN
## ==================================================
func _ready() -> void:
	health = max_health
	setup_navigation()
	setup_frequency_visual()
	add_to_group("enemies")
	
	# Obtener level_manager
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if not level_manager:
		level_manager = get_node_or_null("/root/Main/LevelManager")
	
	# Obtener referencia a la torre principal
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and "main_tower" in game_manager:
		main_tower_node = game_manager.main_tower
	
	set_state(State.MOVE)
	
	print("Enemy ready | Type: %s | Health: %.0f | Speed: %.0f" % [
		name,
		max_health,
		speed
	])

func setup_navigation() -> void:
	"""Configura el agente de navegación"""
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = attack_range  # Usar rango de ataque como objetivo
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 12.0
	
	# Centrar en el path
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED
	#nav_agent.path_metadata_flags = NavigationPathQueryParameters2D.PATH_METADATA_INCLUDE_ALL

func setup_frequency_visual() -> void:
	"""Configura el indicador visual de frecuencia"""
	var freq_data = Frequency.get_frequency_data(frequency)
	current_frequency_color = freq_data.color
	
	# Modular sprite con el color de la frecuencia
	if sprite:
		sprite.modulate = Color.WHITE.lerp(current_frequency_color, 0.3)
	
	# Configurar indicador
	if frequency_indicator and show_frequency_indicator:
		frequency_indicator.modulate = current_frequency_color
		frequency_indicator.visible = true

## ==================================================
## SISTEMA DE ESTADOS
## ==================================================
func set_state(new_state: State) -> void:
	"""Cambia el estado del enemigo"""
	if state == State.DEAD:
		return
	
	if state == new_state:
		return
	
	state = new_state
	
	match state:
		State.IDLE:
			if sprite and sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		
		State.MOVE:
			if sprite and sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		
		State.ATTACK:
			if sprite and sprite.sprite_frames.has_animation("attack"):
				sprite.play("attack")
			attack_timer = 0.0  # Resetear timer de ataque
		
		State.DEAD:
			if sprite and sprite.sprite_frames.has_animation("death"):
				sprite.play("death")
			if has_node("CollisionShape2D"):
				$CollisionShape2D.disabled = true
			velocity = Vector2.ZERO
	
	print("Enemy state changed | Enemy: %s | State: %s" % [name, State.keys()[state]])

## ==================================================
## NAVEGACIÓN
## ==================================================
func set_target(pos: Vector2) -> void:
	"""Establece el objetivo de navegación"""
	target_position = pos
	nav_agent.target_position = pos
	
	print("Enemy target set | Enemy: %s | Target: %s" % [name, pos])

## ==================================================
## SISTEMA DE DAÑO CON FRECUENCIAS
## ==================================================
func take_damage(amount: float, attacker_frequency: Frequency.FrequencyType = Frequency.FrequencyType.YELLOW) -> void:
	"""Recibe daño calculando efectividad de frecuencia"""
	if state == State.DEAD:
		return
	
	# Calcular efectividad
	var effectiveness = Frequency.get_effectiveness(attacker_frequency, frequency)
	var final_damage = amount * effectiveness
	
	# Aplicar daño
	health -= final_damage
	
	# Feedback visual
	_show_damage_feedback(effectiveness)
	
	# Debug
	var attacker_name = Frequency.get_frequency_data(attacker_frequency).name
	var defender_name = Frequency.get_frequency_data(frequency).name
	print("Enemy damaged | Enemy: %s | Damage: %.1f | Effectiveness: x%.1f | Attacker: %s vs Defender: %s | Health: %.1f/%.1f" % [
		name,
		final_damage,
		effectiveness,
		attacker_name,
		defender_name,
		health,
		max_health
	])
	
	if health <= 0:
		die()

func _show_damage_feedback(effectiveness: float) -> void:
	"""Muestra feedback visual según efectividad del ataque"""
	var flash_color = Color.WHITE
	
	if effectiveness > 1.0:
		# Efectivo - parpadeo verde
		flash_color = Color(0.5, 1.0, 0.5)
	elif effectiveness < 1.0:
		# Poco efectivo - parpadeo gris
		flash_color = Color(0.7, 0.7, 0.7)
	else:
		# Neutral - parpadeo blanco
		flash_color = Color.WHITE
	
	# Aplicar efecto
	if sprite:
		sprite.modulate = flash_color
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE.lerp(current_frequency_color, 0.3)

func die() -> void:
	"""Muerte del enemigo"""
	if state == State.DEAD:
		return
	
	set_state(State.DEAD)
	
	print("Enemy died | Enemy: %s | Reward: %d" % [name, reward])
	
	# Esperar animación antes de borrar
	var death_time = 0.8
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		death_time = sprite.sprite_frames.get_animation_length("death")
	
	await get_tree().create_timer(death_time).timeout
	queue_free()

## ==================================================
## FÍSICA Y MOVIMIENTO
## ==================================================
func _physics_process(delta: float) -> void:
	match state:
		State.MOVE:
			_move_state(delta)
		State.ATTACK:
			_attack_state(delta)
		State.IDLE, State.DEAD:
			pass

func _move_state(delta: float) -> void:
	"""Lógica de movimiento hacia el objetivo"""
	# Verificar distancia a la torre para entrar en modo ataque
	if main_tower_node and is_instance_valid(main_tower_node):
		var distance_to_tower = global_position.distance_to(target_position)
		
		# Si está cerca de la torre, cambiar a modo ataque
		if distance_to_tower <= attack_range:
			set_state(State.ATTACK)
			return
	
	# Verificar si llegó al objetivo (por navegación)
	if nav_agent.is_navigation_finished():
		set_state(State.ATTACK)
		return
	
	# Movimiento normal
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	_face_direction(dir)

func _attack_state(delta: float) -> void:
	"""Lógica de ataque a la torre principal"""
	velocity = Vector2.ZERO
	
	# Verificar que la torre siga existiendo
	if not main_tower_node or not is_instance_valid(main_tower_node):
		# La torre fue destruida, volver a modo idle
		set_state(State.IDLE)
		return
	# Verificar distancia - si se alejó mucho, volver a moverse
	var distance_to_tower = global_position.distance_to(target_position)
	if distance_to_tower > attack_range * 1.5:  # Margen de 150%
		set_state(State.MOVE)
		return
	
	# Sistema de cooldown de ataque
	attack_timer += delta
	
	if attack_timer >= attack_cooldown:
		# Atacar la torre
		if main_tower_node.has_method("take_damage"):
			main_tower_node.take_damage(damage)
			print("Enemy attacking | Enemy: %s | Damage: %.1f | Tower health: %.1f" % [
				name,
				damage,
				main_tower_node.health if "health" in main_tower_node else 0
			])
		
		# Resetear timer
		attack_timer = 0.0
		
		# Reproducir animación de ataque si existe
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")

func _face_direction(dir: Vector2) -> void:
	"""Voltear sprite según dirección"""
	if sprite and abs(dir.x) > abs(dir.y):
		sprite.flip_h = dir.x < 0

## ==================================================
## MÉTODOS DE UTILIDAD
## ==================================================
func get_health_percentage() -> float:
	"""Retorna porcentaje de vida"""
	return health / max_health

func get_frequency_name() -> String:
	"""Retorna nombre de la frecuencia"""
	var freq_data = Frequency.get_frequency_data(frequency)
	return freq_data.name

func is_weak_to(attacker_freq: Frequency.FrequencyType) -> bool:
	"""Verifica si es débil a una frecuencia"""
	return Frequency.get_effectiveness(attacker_freq, frequency) > 1.0

func is_resistant_to(attacker_freq: Frequency.FrequencyType) -> bool:
	"""Verifica si es resistente a una frecuencia"""
	return Frequency.get_effectiveness(attacker_freq, frequency) < 1.0
