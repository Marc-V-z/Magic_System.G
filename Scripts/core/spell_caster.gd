class_name SpellCaster
extends RefCounted

func cast(spell: SpellInstance, ctx: SpellContext) -> bool:
	if ctx.payer != null:
		if not ctx.payer.can_pay(spell.cost):
			return false
		ctx.payer.pay(spell.cost)
	spell.shape.cast(spell, ctx)
	return true