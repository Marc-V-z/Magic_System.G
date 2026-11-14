class_name RecastAction
extends ImpactAction
## Conjura outra magia a partir do ponto de impacto, sem custo e sem requisitos.

@export var definition: SpellDefinition
## Limite de reconjurações encadeadas, para evitar laço infinito.
@export var max_depth: int = 3

func execute(_part: SpellPartInstance, ctx: SpellContext, _impact_area: ResolvedArea, impact: ProjectileImpact) -> void:
	if definition == null or ctx.depth >= max_depth:
		return
	var recast := SpellBuilder.new().build(definition)
	if recast == null:
		return
	SpellCaster.new().fire(recast, ctx.derive(impact.point))
