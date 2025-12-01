extends Resource
class_name WaveData

## Recurso que define una oleada de enemigos

@export var wave_name: String = "Oleada 1"
@export var delay_before_start: float = 3.0  # Tiempo antes de iniciar la oleada
## Control de spawn de grupos
@export_enum("Sequential:0", "Parallel:1") var spawn_mode: int = 0  # 0 = Secuencial, 1 = Paralelo
## Grupos de enemigos en esta oleada
@export var enemy_groups: Array[EnemyGroup] = []

## ====================================
## MÉTODOS DE UTILIDAD
## ====================================
func get_total_enemy_count() -> int:
	"""Retorna el total de enemigos en la oleada"""
	var total = 0
	for group in enemy_groups:
		total += group.count
	return total

func get_estimated_duration() -> float:
	"""Estima la duración total de la oleada"""
	if spawn_mode == 0:  # Secuencial
		# Suma todas las duraciones
		var total_duration = 0.0
		for group in enemy_groups:
			total_duration += group.start_delay + (group.count * group.spawn_interval)
		return total_duration
	else:  # Paralelo
		# Toma la duración más larga
		var max_duration = 0.0
		for group in enemy_groups:
			var group_duration = group.start_delay + (group.count * group.spawn_interval)
			if group_duration > max_duration:
				max_duration = group_duration
		return max_duration

func is_sequential() -> bool:
	"""Retorna true si el spawn es secuencial"""
	return spawn_mode == 0

func is_parallel() -> bool:
	"""Retorna true si el spawn es paralelo"""
	return spawn_mode == 1

static func get_waves_for_level(level_id: int) -> Array[WaveData]:
	var waves: Array[WaveData] = []
	
	match level_id:
		0:  # Nivel 0
			waves.append(create_wave(0))
			waves.append(create_wave(1))
			waves.append(create_wave(2))
		
		1:  # Nivel 1
			waves.append(create_wave(1))
			waves.append(create_wave(2))
		2:  # Nivel 1
			waves.append(create_wave(2))
			waves.append(create_wave(3))
			waves.append(create_wave(4))
		
		_:  # Nivel genérico
			for i in range(5):
				waves.append(create_wave(i))
	
	return waves

## ====================================
## BUILDER PARA CREAR OLEADAS EN CÓDIGO
## ====================================
static func create_wave(wave_id: int) -> WaveData:
	"""Factory para crear oleadas predefinidas"""
	var wave = WaveData.new()
	
	match wave_id:
		0:  # Oleada 1 - Tutorial
			wave.wave_name = "Oleada 0: Test"
			wave.delay_before_start = 2.0
			# Crear array temporal y luego asignar
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", 5, 1.5, 0, 0.0))
			wave.enemy_groups = groups
		
		1:  # Oleada 2 - Aumenta dificultad
			wave.wave_name = "Oleada 1: Inicio"
			wave.delay_before_start = 3.0
			wave.spawn_mode = 0  # Secuencial
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", 2, 1.0, 0, 15.0))
			groups.append(_create_group("e1", 2, 1.5, 0, 5.0))
			wave.enemy_groups = groups
		
		2:  # Oleada 3 - Múltiples spawns
			wave.wave_name = "Oleada 2: Pinza"
			wave.delay_before_start = 3.0
			wave.spawn_mode = 0  # Secuencial
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", 3, 1.0, 0, 0.0))
			groups.append(_create_group("e1", 5, 1.0, 0, 2.0))
			wave.enemy_groups = groups
		
		3:  # Oleada 4 - Mezclado
			wave.wave_name = "Oleada 3: Variado"
			wave.delay_before_start = 4.0
			wave.spawn_mode = 0  # Secuencial
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", 5, 0.8, 0, 0.0))
			groups.append(_create_group("e2", 2, 1.5, 1, 3.0))
			groups.append(_create_group("e1", 10, 0.8, 1, 0.0))
			wave.enemy_groups = groups
		4:  # Oleada 4 - Mezclado
			wave.wave_name = "Oleada 4: Variado"
			wave.delay_before_start = 4.0
			wave.spawn_mode = 1  # Parallel
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", 10, 0.8, 0, 0.0))
			groups.append(_create_group("e2", 3, 1.5, 1, 3.0))
			groups.append(_create_group("e1", 5, 2.0, 0, 8.0))
			wave.enemy_groups = groups
		
		_:  # Oleada genérica
			wave.wave_name = "Oleada %d" % wave_id
			wave.delay_before_start = 3.0
			var base_count = 5 + (wave_id * 2)
			var groups: Array[EnemyGroup] = []
			groups.append(_create_group("e1", base_count, 1.0, 0, 0.0))
			wave.enemy_groups = groups
	
	return wave

## Helper para crear grupos
static func _create_group(type: String, qty: int, interval: float, spawn_idx: int, delay: float) -> EnemyGroup:
	var group = EnemyGroup.new()
	group.enemy_type = type
	group.count = qty
	group.spawn_interval = interval
	group.spawn_point_index = spawn_idx
	group.start_delay = delay
	return group
