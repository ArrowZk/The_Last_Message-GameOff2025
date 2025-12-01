extends Control

## ==================================================
## MENÚ DE OPCIONES - Volumen y Resolución
## ==================================================

@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterVolume/Slider
@onready var resolution_option: OptionButton = $Panel/VBoxContainer/Resolution/OptionButton
@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/Fullscreen/CheckBox
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

## Resoluciones disponibles
var resolutions := {
	0: Vector2i(1920, 1080),
	1: Vector2i(1600, 900),
	2: Vector2i(1366, 768),
	3: Vector2i(1280, 720),
	4: Vector2i(1024, 768)
}

func _ready():
	# Cargar configuración guardada
	load_settings()
	
	# Conectar señales
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	
	# Configurar opciones de resolución
	#setup_resolution_options()

func setup_resolution_options():
	"""Configura el menú desplegable de resoluciones"""
	resolution_option.clear()
	resolution_option.add_item("1920x1080 (Full HD)", 0)
	resolution_option.add_item("1600x900", 1)
	resolution_option.add_item("1366x768", 2)
	resolution_option.add_item("1280x720 (HD)", 3)
	resolution_option.add_item("1024x768", 4)

## ==================================================
## CALLBACKS DE CONTROLES
## ==================================================

func _on_resolution_selected(index: int):
	"""Cambia la resolución de la ventana"""
	if resolutions.has(index):
		var size = resolutions[index]
		DisplayServer.window_set_size(size)
		# Centrar ventana
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - size) / 2
		DisplayServer.window_set_position(window_pos)
		save_settings()

func _on_fullscreen_toggled(button_pressed: bool):
	"""Activa/desactiva pantalla completa"""
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_back_pressed():
	"""Regresa al menú anterior"""
	save_settings()
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")

## ==================================================
## GUARDAR Y CARGAR CONFIGURACIÓN
## ==================================================

func save_settings():
	"""Guarda la configuración en archivo"""
	var config = ConfigFile.new()
	
	# Audio
	config.set_value("audio", "master", master_slider.value)
	
	# Video
	config.set_value("video", "resolution", resolution_option.selected)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	
	config.save("user://settings.cfg")

func load_settings():
	"""Carga la configuración guardada"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# Valores por defecto
		master_slider.value = 80
		resolution_option.selected = 3  # 1280x720
		fullscreen_check.button_pressed = false
		return
	
	# Cargar audio
	master_slider.value = config.get_value("audio", "master", 80)
	
	# Aplicar volúmenes
	_on_slider_value_changed(master_slider.value)
	
	# Cargar video
	var res_index = config.get_value("video", "resolution", 3)
	resolution_option.selected = res_index
	_on_resolution_selected(res_index)
	
	var is_fullscreen = config.get_value("video", "fullscreen", false)
	fullscreen_check.button_pressed = is_fullscreen
	_on_fullscreen_toggled(is_fullscreen)


func _on_slider_value_changed(value: float) -> void:
	"""Cambia el volumen maestro"""
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	save_settings()


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1366,768))
		3:
			DisplayServer.window_set_size(Vector2i(1280,720))
		4:
			DisplayServer.window_set_size(Vector2i(1024,768))
	# Centrar ventana
	var size2 = resolutions[index]
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - size2) / 2
	DisplayServer.window_set_position(window_pos)
	save_settings()
