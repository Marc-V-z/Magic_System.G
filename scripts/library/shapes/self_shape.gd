class_name SelfShape
extends SpellShape
## Aplica a parte no próprio conjurador (curas, buffs, marcas).

func cast(part: SpellPartInstance, ctx: SpellContext) -> void:
	part.apply_to(ctx, ctx.caster)
