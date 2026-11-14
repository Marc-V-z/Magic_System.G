class_name SpellCaster
extends RefCounted
## Cobra o custo (se houver payer) e dispara a forma da magia.

## Devolve true se conjurou, false se o conjurador não conseguiu pagar o custo.
func cast(spell: SpellInstance, ctx: SpellContext) -> bool:
	if ctx.payer != null:
		if not ctx.payer.can_pay(spell.cost):
			return false
		ctx.payer.pay(spell.cost)
	spell.shape.cast(spell, ctx)
	return true
