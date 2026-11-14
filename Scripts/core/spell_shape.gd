class_name SpellShape
extends SpellComponent

@export var name_prefix: String = ""      # ex.: "Bola de"
@export var power_multiplier: float = 1.0

# Formas simples devolvem a si mesmas. Grupos escolhem outra forma.
func resolve(_elements: Array[SpellElement]) -> SpellShape:
	return self

# Define COMO a magia chega ao(s) alvo(s).
func cast(_spell: SpellInstance, _ctx: SpellContext) -> void:
	pass