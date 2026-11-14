class_name TestStats
extends StatProvider
## StatProvider de teste, lê de um dicionário com chaves String.

var values: Dictionary

func _init(v: Dictionary = {}) -> void:
	values = v

func get_stat(key: StringName, default_value: float = 0.0) -> float:
	return values.get(String(key), default_value)
