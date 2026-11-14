class_name SpellInstance
extends RefCounted
## Magia pronta para ser conjurada. Criada pelo SpellBuilder.

var display_name: String
## As partes, conjuradas em ordem.
var parts: Array[SpellPartInstance]
## Custo total (magia + elementos compartilhados + forma e elementos de cada parte).
var cost: SpellCost
var requirements: Array[SpellRequirement]

## Devolve o primeiro requisito não cumprido, ou null se todos estiverem cumpridos.
func find_unmet_requirement(ctx: SpellContext) -> SpellRequirement:
	for requirement in requirements:
		if requirement != null and not requirement.is_met(ctx):
			return requirement
	return null
