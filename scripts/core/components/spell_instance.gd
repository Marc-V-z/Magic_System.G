class_name SpellInstance
extends RefCounted
## Magia pronta para ser conjurada. Criada pelo SpellBuilder.

var display_name: String
var shape: SpellShape
var elements: Array[SpellElement]
var cost: SpellCost
var requirements: Array[SpellRequirement]

## Soma o poder de todos os elementos e multiplica pelo multiplicador da forma.
func compute_power(ctx: SpellContext) -> float:
	var total := 0.0
	for element in elements:
		total += ValueSource.read(element.power, ctx)
	return total * shape.power_multiplier

## Aplica os efeitos dos elementos e da forma em um alvo.
func apply_to(ctx: SpellContext, target: Object) -> void:
	var power := compute_power(ctx)
	for element in elements:
		for effect in element.effects:
			effect.apply(target, power, ctx)
	for effect in shape.effects:
		effect.apply(target, power, ctx)

## Devolve o primeiro requisito não cumprido, ou null se todos estiverem cumpridos.
func find_unmet_requirement(ctx: SpellContext) -> SpellRequirement:
	for requirement in requirements:
		if requirement != null and not requirement.is_met(ctx):
			return requirement
	return null
