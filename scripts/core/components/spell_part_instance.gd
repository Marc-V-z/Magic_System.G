class_name SpellPartInstance
extends RefCounted
## Uma parte pronta da magia: uma forma já resolvida, os elementos que valem para ela
## (os compartilhados mais os próprios) e os parâmetros já combinados.
## Criada pelo SpellBuilder.

var shape: SpellShape
var elements: Array[SpellElement]
## Nunca é nula: já é a união dos parâmetros da forma com os da parte.
var area: SpellArea

## Soma o poder de todos os elementos da parte e multiplica pelo multiplicador da forma.
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
