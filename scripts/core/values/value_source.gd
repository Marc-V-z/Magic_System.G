class_name ValueSource
extends Resource
## Base: de onde vem um número bruto. Subclasses decidem (constante, atributo, conta).

func get_value(_ctx: SpellContext) -> float:
	return 0.0
