extends Node

## Script de prueba para el sistema de frecuencias
## Agrega este script a un nodo en Main para testing rápido

@onready var game_manager = $"../GameManager"

func _ready():
	print("\n🧪 === INICIANDO TESTS DEL SISTEMA ===\n")
	
	# Esperar que todo esté listo
	await get_tree().create_timer(1.0).timeout
	
	test_frequency_data()
	test_effectiveness()
	test_wave_creation()
	test_enemy_group()
	
	print("\n✅ === TESTS COMPLETADOS ===\n")

func test_frequency_data():
	print("📊 Test 1: Datos de Frecuencias")
	
	var blue = Frequency.get_frequency_data(Frequency.FrequencyType.BLUE)
	var yellow = Frequency.get_frequency_data(Frequency.FrequencyType.YELLOW)
	var red = Frequency.get_frequency_data(Frequency.FrequencyType.RED)
	
	assert(blue.name == "Blueband", "❌ Blue name incorrecto")
	assert(yellow.name == "MidPulse", "❌ Yellow name incorrecto")
	assert(red.name == "Redwave", "❌ Red name incorrecto")
	
	print("   ✅ BLUE: ", blue.name, " | Daño: ", blue.damage_mult, "x")
	print("   ✅ YELLOW: ", yellow.name, " | Daño: ", yellow.damage_mult, "x")
	print("   ✅ RED: ", red.name, " | Daño: ", red.damage_mult, "x")

func test_effectiveness():
	print("\n🎯 Test 2: Efectividad de Frecuencias")
	
	# BLUE vs YELLOW = efectivo (1.5x)
	var blue_vs_yellow = Frequency.get_effectiveness(
		Frequency.FrequencyType.BLUE,
		Frequency.FrequencyType.YELLOW
	)
	assert(blue_vs_yellow == 1.5, "❌ BLUE vs YELLOW debería ser 1.5x")
	print("   ✅ BLUE vs YELLOW: ", blue_vs_yellow, "x (Efectivo)")
	
	# YELLOW vs RED = efectivo (1.5x)
	var yellow_vs_red = Frequency.get_effectiveness(
		Frequency.FrequencyType.YELLOW,
		Frequency.FrequencyType.RED
	)
	assert(yellow_vs_red == 1.5, "❌ YELLOW vs RED debería ser 1.5x")
	print("   ✅ YELLOW vs RED: ", yellow_vs_red, "x (Efectivo)")
	
	# RED vs BLUE = efectivo (1.5x)
	var red_vs_blue = Frequency.get_effectiveness(
		Frequency.FrequencyType.RED,
		Frequency.FrequencyType.BLUE
	)
	assert(red_vs_blue == 1.5, "❌ RED vs BLUE debería ser 1.5x")
	print("   ✅ RED vs BLUE: ", red_vs_blue, "x (Efectivo)")
	
	# BLUE vs RED = poco efectivo (0.5x)
	var blue_vs_red = Frequency.get_effectiveness(
		Frequency.FrequencyType.BLUE,
		Frequency.FrequencyType.RED
	)
	assert(blue_vs_red == 0.5, "❌ BLUE vs RED debería ser 0.5x")
	print("   ✅ BLUE vs RED: ", blue_vs_red, "x (Poco efectivo)")
	
	# BLUE vs BLUE = neutral (1.0x)
	var blue_vs_blue = Frequency.get_effectiveness(
		Frequency.FrequencyType.BLUE,
		Frequency.FrequencyType.BLUE
	)
	assert(blue_vs_blue == 1.0, "❌ BLUE vs BLUE debería ser 1.0x")
	print("   ✅ BLUE vs BLUE: ", blue_vs_blue, "x (Neutral)")

func test_wave_creation():
	print("\n🌊 Test 3: Creación de Oleadas")
	
	var wave0 = WaveData.create_wave(0)
	assert(wave0 != null, "❌ No se pudo crear oleada 0")
	assert(wave0.wave_name == "Oleada 0: Test", "❌ Nombre incorrecto")
	assert(wave0.enemy_groups.size() > 0, "❌ Oleada sin grupos")
	
	var total = wave0.get_total_enemy_count()
	var duration = wave0.get_estimated_duration()
	
	print("   ✅ ", wave0.wave_name)
	print("      Grupos: ", wave0.enemy_groups.size())
	print("      Enemigos totales: ", total)
	print("      Duración estimada: ", duration, "s")
	
	# Probar oleada 2
	var wave2 = WaveData.create_wave(2)
	assert(wave2.enemy_groups.size() >= 2, "❌ Oleada 3 debería tener múltiples grupos")
	print("   ✅ ", wave2.wave_name, " | Grupos: ", wave2.enemy_groups.size())

func test_enemy_group():
	print("\n👾 Test 4: EnemyGroup")
	
	var group = EnemyGroup.new()
	group.enemy_type = "e1"
	group.count = 10
	group.spawn_interval = 1.0
	group.spawn_point_index = 0
	group.start_delay = 0.0
	
	assert(group.enemy_type == "e1", "❌ Enemy type incorrecto")
	assert(group.count == 10, "❌ Count incorrecto")
	
	print("   ✅ EnemyGroup creado:")
	print("      Tipo: ", group.enemy_type)
	print("      Cantidad: ", group.count)
	print("      Intervalo: ", group.spawn_interval, "s")
	print("      Spawn point: ", group.spawn_point_index)

## ====================================
## TESTS INTERACTIVOS (Llamar desde consola)
## ====================================

func test_spawn_enemy():
	"""Spawns un enemigo de prueba"""
	print("\n🧪 Test: Spawning enemigo...")
	if game_manager:
		game_manager.spawn_test_enemy()
		print("   ✅ Enemigo spawneado")
	else:
		print("   ❌ GameManager no encontrado")

func test_start_wave():
	"""Inicia la primera oleada"""
	print("\n🧪 Test: Iniciando oleada...")
	if game_manager:
		game_manager.start_next_wave()
		print("   ✅ Oleada iniciada")
	else:
		print("   ❌ GameManager no encontrado")

func test_tower_frequency():
	"""Prueba cambio de frecuencia en torres"""
	print("\n🧪 Test: Cambio de frecuencia...")
	var towers = get_tree().get_nodes_in_group("towers")
	
	if towers.is_empty():
		print("   ⚠️ No hay torres colocadas")
		return
	
	var tower = towers[0]
	print("   Torre encontrada: ", tower.name)
	print("   Frecuencia actual: ", tower.current_frequency)
	
	# Cambiar a RED
	tower.set_frequency(Frequency.FrequencyType.RED)
	print("   ✅ Cambiada a RED")
	print("   Nuevo daño: ", tower.damage)
	print("   Nueva velocidad: ", tower.attack_speed)

func test_damage_calculation():
	"""Prueba cálculo de daño con efectividad"""
	print("\n🧪 Test: Cálculo de daño...")
	
	var base_damage = 100.0
	var attacker_freq = Frequency.FrequencyType.BLUE
	var defender_freq = Frequency.FrequencyType.YELLOW
	
	var effectiveness = Frequency.get_effectiveness(attacker_freq, defender_freq)
	var final_damage = base_damage * effectiveness
	
	print("   Daño base: ", base_damage)
	print("   Atacante: BLUE vs Defensor: YELLOW")
	print("   Efectividad: ", effectiveness, "x")
	print("   ✅ Daño final: ", final_damage)

## ====================================
## INPUT PARA TESTS RÁPIDOS
## ====================================

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				test_spawn_enemy()
			KEY_F2:
				test_start_wave()
			KEY_F3:
				test_tower_frequency()
			KEY_F4:
				test_damage_calculation()
			KEY_F5:
				# Rerun all tests
				test_frequency_data()
				test_effectiveness()
				test_wave_creation()
				test_enemy_group()
