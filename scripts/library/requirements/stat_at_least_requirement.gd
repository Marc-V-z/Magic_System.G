class_name StatAtLeastRequirement
extends SpellRequirement
## Exige que um atributo do conjurador seja pelo menos o valor indicado.
## Sem StatProvider no contexto, falha.

@export var stat_key: StringName
@export var minimum: float = 0.0

func is_met(ctx: SpellContext) -> bool:
	if ctx == null or ctx.stats == null:
		return false
	return ctx.stats.get_stat(stat_key, 0.0) >= minimum
