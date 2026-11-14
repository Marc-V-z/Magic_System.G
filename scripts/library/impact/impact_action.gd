class_name ImpactAction
extends Resource
## Base: o que acontece quando um projétil acerta ou chega ao fim.

## part e ctx: a parte da magia e o contexto. impact_area: parâmetros do impacto já
## calculados (vazios se a forma não tem impact_area). impact: o impacto em si.
func execute(_part: SpellPartInstance, _ctx: SpellContext, _impact_area: ResolvedArea, _impact: ProjectileImpact) -> void:
	pass
