class_name SpellPowerValue
extends ValueSource
## O poder final da magia em execução, vezes uma escala. Serve para áreas que crescem
## com o poder (ex.: raio = poder * 0.1).
## Cuidado: NÃO use dentro de element.power, pois o poder depende dele (laço infinito).

@export var scale: float = 1.0

func get_value(ctx: SpellContext) -> float:
	if ctx == null or ctx.spell == null:
		return 0.0
	return ctx.spell.compute_power(ctx) * scale
