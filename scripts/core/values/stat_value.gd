class_name StatValue
extends ValueSource
## Um atributo do conjurador (via StatProvider), vezes uma escala.

@export var stat_key: StringName
@export var scale: float = 1.0
## Usado quando não há StatProvider no contexto ou o jogo não tem o atributo.
@export var fallback: float = 0.0

func get_value(ctx: SpellContext) -> float:
	if ctx == null or ctx.stats == null:
		return fallback
	return ctx.stats.get_stat(stat_key, fallback) * scale
