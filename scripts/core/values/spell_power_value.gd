class_name SpellPowerValue
extends ValueSource
## O poder da parte da magia que está sendo conjurada, vezes uma escala.
## Serve para áreas que crescem com o poder.
## Cuidado: NÃO use dentro de element.power, pois o poder depende dele (laço infinito).

@export var scale: float = 1.0

func get_value(ctx: SpellContext) -> float:
	if ctx == null or ctx.part == null:
		return 0.0
	return ctx.part.compute_power(ctx) * scale
