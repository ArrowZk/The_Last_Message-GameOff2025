extends Resource
class_name Frequency

## Recurso que define una frecuencia de radio

enum FrequencyType {
	BLUE,      # Blueband - Rápida y precisa
	YELLOW,    # MidPulse - Equilibrada
	RED        # Redwave - Potente y lenta
}

@export var type: FrequencyType
@export var display_name: String
@export var color: Color
@export var description: String

## Stats modificadores que aplica esta frecuencia
@export_group("Stats Modifiers")
@export var damage_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var projectile_speed_multiplier: float = 1.0

## Método estático para obtener frecuencia por tipo
static func get_frequency_data(freq_type: FrequencyType) -> Dictionary:
	match freq_type:
		FrequencyType.BLUE:
			return {
				"type": FrequencyType.BLUE,
				"name": "Blueband",
				"color": Color(0.2, 0.5, 1.0),  # Azul
				"description": "Frecuencia estable y precisa",
				"damage_mult": 0.8,
				"speed_mult": 1.5,
				"range_mult": 1.0,
				"projectile_speed_mult": 1.3
			}
		FrequencyType.YELLOW:
			return {
				"type": FrequencyType.YELLOW,
				"name": "MidPulse",
				"color": Color(1.0, 0.9, 0.2),  # Amarillo
				"description": "Frecuencia equilibrada",
				"damage_mult": 1.0,
				"speed_mult": 1.0,
				"range_mult": 1.0,
				"projectile_speed_mult": 1.0
			}
		FrequencyType.RED:
			return {
				"type": FrequencyType.RED,
				"name": "Redwave",
				"color": Color(1.0, 0.2, 0.2),  # Rojo
				"description": "Frecuencia potente y agresiva",
				"damage_mult": 1.5,
				"speed_mult": 0.7,
				"range_mult": 0.9,
				"projectile_speed_mult": 0.8
			}
	
	return {}

## Sistema de efectividad (triángulo de afinidades)
static func get_effectiveness(attacker_freq: FrequencyType, defender_freq: FrequencyType) -> float:
	"""
	Retorna el multiplicador de efectividad
	> 1.0 = Efectivo
	= 1.0 = Neutral
	< 1.0 = Poco efectivo
	"""
	# Triángulo de afinidades:
	# BLUE > YELLOW > RED > BLUE
	
	match attacker_freq:
		FrequencyType.BLUE:
			match defender_freq:
				FrequencyType.BLUE: return 1.0    # Neutral
				FrequencyType.YELLOW: return 1.5  # Muy efectivo
				FrequencyType.RED: return 0.5     # Poco efectivo
		
		FrequencyType.YELLOW:
			match defender_freq:
				FrequencyType.BLUE: return 0.5    # Poco efectivo
				FrequencyType.YELLOW: return 1.0  # Neutral
				FrequencyType.RED: return 1.5     # Muy efectivo
		
		FrequencyType.RED:
			match defender_freq:
				FrequencyType.BLUE: return 1.5    # Muy efectivo
				FrequencyType.YELLOW: return 0.5  # Poco efectivo
				FrequencyType.RED: return 1.0     # Neutral
	
	return 1.0
