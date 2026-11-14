class_name SelfShape
extends SpellShape
## Aplica a magia no próprio conjurador (curas, buffs, absorção simples).

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	spell.apply_to(ctx, ctx.caster)
