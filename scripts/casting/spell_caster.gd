class_name SpellCaster
extends RefCounted
## Verifica requisitos e custo, cobra e dispara a forma da magia.

enum Result { OK, NO_SHAPE, REQUIREMENT_NOT_MET, CANNOT_PAY }

## Diz se a magia poderia ser conjurada agora, sem cobrar nada nem disparar nada.
## Útil para destacar cartas ou habilitar botões.
func can_cast(spell: SpellInstance, ctx: SpellContext) -> Result:
	if spell == null or spell.shape == null:
		return Result.NO_SHAPE
	if spell.find_unmet_requirement(ctx) != null:
		return Result.REQUIREMENT_NOT_MET
	if ctx.payer != null and not ctx.payer.can_pay(spell.cost):
		return Result.CANNOT_PAY
	return Result.OK

## Conjuração completa: verifica, cobra e dispara.
func cast(spell: SpellInstance, ctx: SpellContext) -> Result:
	var result := can_cast(spell, ctx)
	if result != Result.OK:
		return result
	if ctx.payer != null:
		ctx.payer.pay(spell.cost)
	fire(spell, ctx)
	return Result.OK

## Dispara a forma sem verificar nem cobrar nada (usado em reconjurações gratuitas).
func fire(spell: SpellInstance, ctx: SpellContext) -> void:
	ctx.spell = spell
	spell.shape.cast(spell, ctx)
