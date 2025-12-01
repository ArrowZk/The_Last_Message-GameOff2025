extends Node

@onready var level_container : Node2D = $"../Level"

var current_level : Node2D
var spawn_points: Array[Marker2D] = []
var nav_agent : NavigationAgent2D
var current_level_index: int = 1
func _ready() -> void:
	current_level_index = GLOBAL.selected_level + 1
	load_level(current_level_index)

func load_level(level_id: int):
	if current_level:
		current_level.queue_free()
	var level_path = "res://scenes/levels/level%d.tscn" % level_id
	var packed = load(level_path)
	current_level = packed.instantiate()
	level_container.add_child(current_level)
	# Configurar límites de cámara según nivel
	var camera = get_node_or_null("/root/Main/GameCamera")
	if camera:
		match level_id:
			0:  # Nivel de prueba
				camera.set_level_limits(-500, 1500, -500, 1000)
			1:  # Nivel 1
				camera.set_level_limits(-200, 1200, -200, 800)
			2:  # Nivel 2
				camera.set_level_limits(-200, 1200, -200, 800)
			_:  # Por defecto
				camera.set_level_limits(-1000, 1000, -1000, 1000)
	
	_load_spawn_points()
	_load_navigation_agent()

func _load_spawn_points():
	spawn_points.clear()
	var sp_root = current_level.get_node("SpawnPoints")

	for child in sp_root.get_children():
		if child is Marker2D:
			spawn_points.append(child)

	print("Spawn points cargados:", spawn_points)

func _load_navigation_agent() -> void:
	nav_agent = current_level.get_node("NavigationAgent2D")
	
func set_target(pos: Vector2, origin: Vector2):
	nav_agent.target_position = pos
	print(nav_agent.target_position)
