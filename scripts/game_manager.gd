extends Node
class_name GameManager

## ========================================
## REFERENCIAS
## ========================================
@onready var level_manager: Node = $"../LevelManager"
@onready var enemy_manager: Node = $"../EnemyManager"
@onready var victory_screen = $"../VictoryScreen"
@onready var game_over_screen = $"../GameOverScreen"
## ========================================
## ESTADO DEL JUEGO
## ========================================
var main_tower_position: Vector2
var main_tower: Node2D
var current_wave_index: int = 0
var is_wave_active: bool = false
var enemies_alive: int = 0
var total_kills: int = 0
## Recursos del jugador
var player_currency: int = 200  # Dinero inicial

## Frecuencia global de todas las torres
var global_frequency: Frequency.FrequencyType = Frequency.FrequencyType.BLUE

## ========================================
## SISTEMA DE OLEADAS
## ========================================
var waves: Array[WaveData] = []
var current_wave_spawners: Array = []  # Timers activos de spawn

## Señales
signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_completed()
signal currency_changed(new_amount: int)
signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node)
signal global_frequency_changed(new_frequency: Frequency.FrequencyType)

## ========================================
## INICIALIZACIÓN
## ========================================
func _ready() -> void:
	add_to_group("game_manager")
	main_tower = level_manager.current_level.get_node("MainTower")
	main_tower.base_destroyed.connect(_on_base_destroyed)
	# Esperar a que el nivel esté listo
	await get_tree().process_frame
	
	setup_level()
	load_waves()
	print("Game Manager initialized | Currency: %d | Waves: %d" % [player_currency, waves.size()])
	# Conectar señal de oleada completada para auto-iniciar siguiente
	wave_completed.connect(_on_wave_completed_auto_start)
	# Iniciar primera oleada automáticamente después de un pequeño delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func setup_level() -> void:
	"""Configurar referencias del nivel"""
	if not level_manager or not level_manager.current_level:
		push_error("LevelManager no está listo")
		return
	
	# Obtener posición de la torre principal
	var main_tower = level_manager.current_level.get_node_or_null("MainTower/TargetPosition")
	if main_tower:
		main_tower_position = main_tower.global_position
		print("📍 Torre principal en: ", main_tower_position)
	else:
		push_warning("No se encontró MainTower/TargetPosition")

func load_waves() -> void:
	var level_id = level_manager.current_level_index
	waves = WaveData.get_waves_for_level(level_id)
## ========================================
## CONTROL DE OLEADAS
## ========================================
func start_next_wave() -> void:
	"""Inicia la siguiente oleada"""
	if is_wave_active:
		print("⚠️ Ya hay una oleada activa")
		return
	
	if current_wave_index >= waves.size():
		print("🎉 ¡Todas las oleadas completadas!")
		all_waves_completed.emit()
		return
	
	start_wave(current_wave_index)
	current_wave_index += 1

func start_wave(wave_id: int) -> void:
	"""Inicia una oleada específica"""
	if wave_id < 0 or wave_id >= waves.size():
		push_error("Oleada inválida: %d" % wave_id)
		return
	
	var wave = waves[wave_id]
	is_wave_active = true
	enemies_alive = 0
	
	print("\n🌊 ========== %s ==========" % wave.wave_name)
	print("   Enemigos totales: ", wave.get_total_enemy_count())
	print("   Duración estimada: %.1fs" % wave.get_estimated_duration())
	
	wave_started.emit(wave_id)
	
	# Delay antes de empezar
	await get_tree().create_timer(wave.delay_before_start).timeout
	
	# Spawn de grupos
	spawn_wave_groups(wave)

func spawn_wave_groups(wave: WaveData) -> void:
	"""Spawns todos los grupos de una oleada"""
	current_wave_spawners.clear()
	
	# Verificar que la oleada tenga grupos
	if wave.enemy_groups.is_empty():
		push_warning("Oleada sin grupos de enemigos")
		return
	
	# Usar modo de spawn configurado en la oleada
	if wave.is_sequential():
		# SECUENCIAL: Ejecuta grupos uno después del otro
		print("Wave spawn mode | Mode: SEQUENTIAL")
		for group in wave.enemy_groups:
			await spawn_enemy_group(group)
	else:
		# PARALELO: Ejecuta todos los grupos simultáneamente
		print("Wave spawn mode | Mode: PARALLEL")
		for group in wave.enemy_groups:
			_spawn_group_async(group)

func _spawn_group_async(group: EnemyGroup) -> void:
	"""Helper asíncrono para spawn de grupo"""
	await spawn_enemy_group(group)

func spawn_enemy_group(group: EnemyGroup) -> void:
	"""Spawns un grupo de enemigos"""
	# Validar spawn point
	if group.spawn_point_index >= level_manager.spawn_points.size():
		push_error("Spawn point %d no existe" % group.spawn_point_index)
		return
	
	# Delay inicial del grupo
	if group.start_delay > 0:
		await get_tree().create_timer(group.start_delay).timeout
	
	# Spawn de enemigos con intervalo
	for i in range(group.count):
		await spawn_enemy_from_group(group)
		
		# Esperar intervalo (excepto en el último)
		if i < group.count - 1:
			await get_tree().create_timer(group.spawn_interval).timeout

func spawn_enemy_from_group(group: EnemyGroup) -> void:
	"""Spawns un enemigo individual de un grupo"""
	var spawn_point = level_manager.spawn_points[group.spawn_point_index]
	var enemy = enemy_manager.spawn_enemy(group.enemy_type, spawn_point.global_position)
	
	if enemy:
		enemy.set_target(main_tower_position)
		enemies_alive += 1
		enemy_spawned.emit(enemy)
		
		# Conectar muerte del enemigo
		if not enemy.tree_exiting.is_connected(_on_enemy_died):
			enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: Node) -> void:
	"""Callback cuando un enemigo muere"""
	enemies_alive -= 1
	total_kills += 1
	enemy_died.emit(enemy)
	
	# Dar recompensa
	if "reward" in enemy:
		CurrencyPopup.create(enemy.reward, enemy.global_position, self)
		add_currency(enemy.reward)
	
	print("Enemy killed | Alive: %d | Total kills: %d" % [enemies_alive, total_kills])
	
	# Verificar si la oleada terminó
	if enemies_alive <= 0 and is_wave_active:
		await get_tree().create_timer(1.0).timeout  # Pequeño delay
		complete_wave()

func complete_wave() -> void:
	"""Completa la oleada actual"""
	is_wave_active = false
	var completed_wave = current_wave_index - 1
	
	print("✅ Oleada %d completada!" % completed_wave)
	wave_completed.emit(completed_wave)

func _on_wave_completed_auto_start(wave_index: int) -> void:
	"""Callback para auto-iniciar siguiente oleada después de completar una"""
	print("Wave auto-start | Completed wave: %d | Next wave: %d" % [wave_index, current_wave_index])
	
	# Verificar si hay más oleadas
	if current_wave_index >= waves.size():
		print("All waves completed! Showing victory screen...")
		_on_all_waves_completed()
		return
	
	# Delay antes de iniciar siguiente oleada (tiempo para que jugador se prepare)
	await get_tree().create_timer(3.0).timeout
	
	# Iniciar siguiente oleada
	start_next_wave()

# En all_waves_completed signal:
func _on_all_waves_completed():
	victory_screen.show_victory({"kills": total_kills})

# Cuando base destruida:
func _on_base_destroyed():
	game_over_screen.show_game_over()
## ========================================
## SISTEMA DE RECURSOS
## ========================================
func add_currency(amount: int) -> void:
	"""Agrega dinero al jugador"""
	player_currency += amount
	currency_changed.emit(player_currency)

func spend_currency(amount: int) -> bool:
	"""Gasta dinero del jugador"""
	if player_currency >= amount:
		player_currency -= amount
		currency_changed.emit(player_currency)
		return true
	return false

func get_currency() -> int:
	"""Retorna el dinero actual"""
	return player_currency

## ========================================
## SISTEMA DE FRECUENCIA GLOBAL
## ========================================
func set_global_frequency(freq: Frequency.FrequencyType) -> void:
	"""Cambia la frecuencia de TODAS las torres activas"""
	global_frequency = freq
	
	# Cambiar frecuencia de todas las torres existentes
	var towers = get_tree().get_nodes_in_group("towers")
	var changed_count = 0
	var deactivated_count = 0
	
	for tower in towers:
		if tower.has_method("set_frequency"):
			# Intentar cambiar frecuencia
			var was_active = tower.is_active if "is_active" in tower else true
			tower.set_frequency(freq)
			
			# Verificar si se desactivó
			if "is_active" in tower and not tower.is_active:
				deactivated_count += 1
			elif "is_active" in tower and tower.is_active:
				changed_count += 1
	
	# Emitir señal
	global_frequency_changed.emit(freq)
	
	var freq_data = Frequency.get_frequency_data(freq)
	print("🔄 Frecuencia global: %s | Activas: %d | Desactivadas: %d" % [
		freq_data.name,
		changed_count,
		deactivated_count
	])

func cycle_global_frequency() -> void:
	"""Cicla entre las frecuencias disponibles"""
	var freqs = [
		Frequency.FrequencyType.BLUE,
		Frequency.FrequencyType.YELLOW,
		Frequency.FrequencyType.RED
	]
	
	var current_index = freqs.find(global_frequency)
	var next_index = (current_index + 1) % freqs.size()
	set_global_frequency(freqs[next_index])

func get_global_frequency_name() -> String:
	"""Retorna el nombre de la frecuencia global actual"""
	var freq_data = Frequency.get_frequency_data(global_frequency)
	return freq_data.name

func get_global_frequency_color() -> Color:
	"""Retorna el color de la frecuencia global actual"""
	var freq_data = Frequency.get_frequency_data(global_frequency)
	return freq_data.color

## ========================================
## MÉTODOS DE UTILIDAD
## ========================================
func get_wave_info(wave_id: int) -> Dictionary:
	"""Retorna información de una oleada"""
	if wave_id < 0 or wave_id >= waves.size():
		return {}
	
	var wave = waves[wave_id]
	return {
		"name": wave.wave_name,
		"enemy_count": wave.get_total_enemy_count(),
		"duration": wave.get_estimated_duration(),
		"groups": wave.enemy_groups.size()
	}

func get_current_wave_progress() -> Dictionary:
	"""Retorna progreso de la oleada actual"""
	return {
		"wave_index": current_wave_index - 1,
		"is_active": is_wave_active,
		"enemies_alive": enemies_alive,
		"total_waves": waves.size()
	}

## ========================================
## DEBUG
## ========================================
func spawn_test_enemy() -> void:
	"""Spawn de enemigo de prueba"""
	if level_manager.spawn_points.is_empty():
		push_error("No hay spawn points")
		return
	
	var sp = level_manager.spawn_points[0]
	var enemy = enemy_manager.spawn_enemy("e1", sp.global_position)
	if enemy:
		enemy.set_target(main_tower_position)
		enemies_alive += 1

func skip_wave() -> void:
	"""Salta la oleada actual (debug)"""
	if is_wave_active:
		# Matar todos los enemigos
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			enemy.queue_free()
		
		enemies_alive = 0
		complete_wave()
