class_name SpellInstance
extends RefCounted
## Magia pronta para ser conjurada. Criada pelo SpellBuilder.

var display_name: String
var shape: SpellShape
var elements: Array[SpellElement]
var cost: SpellCost

## Soma o poder de todos os elementos e multiplica pelo multiplicador da forma.
func compute_power(ctx: SpellContext) -> float:
	var total := 0.0
	for element in elements:
		if element.power != null:
			total += element.power.get_value(ctx)
	return total * shape.power_multiplier

## Aplica todos os efeitos de todos os elementos em um alvo.
func apply_to(ctx: SpellContext, target: Node) -> void:
	var power := compute_power(ctx)
	for element in elements:
		for effect in element.effects:
			effect.apply(target, power, ctx)
