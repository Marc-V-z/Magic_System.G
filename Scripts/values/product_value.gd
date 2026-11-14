class_name ProductValue
extends ValueSource

# Permite o elemento agir só como multiplicador de um atributo.
@export var a: ValueSource
@export var b: ValueSource

func get_value(ctx: SpellContext) -> float:
	if a == null or b == null:
		return 0.0
	return a.get_value(ctx) * b.get_value(ctx)