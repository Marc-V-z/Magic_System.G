class_name StatValue
extends ValueSource

@export var stat_key: StringName
@export var scale: float = 1.0
@export var fallback: float = 0.0

func get_value(ctx: SpellContext) -> float:
	if ctx == null or ctx.stats == null:
		return fallback
	return ctx.stats.get_stat(stat_key, fallback) * scale