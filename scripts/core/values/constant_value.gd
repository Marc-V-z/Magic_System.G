class_name ConstantValue
extends ValueSource
## Um número fixo, definido no Inspector.

@export var value: float = 0.0

func get_value(_ctx: SpellContext) -> float:
	return value
