class_name StatProvider
extends RefCounted

# O jogo herda desta classe para expor seus atributos.
func get_stat(_key: StringName, default_value: float = 0.0) -> float:
	return default_value