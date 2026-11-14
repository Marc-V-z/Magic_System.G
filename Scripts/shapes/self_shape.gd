class_name SelfShape
extends SpellShape

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	spell.apply_to(ctx, ctx.caster)