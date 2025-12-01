extends Node

var selected_level: int = 0
var unlocked_levels: int = 1
var max_levels_avaliable = 3

func _ready():
	load_progress()

func load_progress():
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		unlocked_levels = file.get_32()
		file.close()

func save_progress():
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_32(unlocked_levels)
	file.close()

func unlock_next_level():
	unlocked_levels += 1
	save_progress()
