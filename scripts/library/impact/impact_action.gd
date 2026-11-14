class_name ImpactAction
extends Resource
## Base: o que acontece quando um projétil acerta ou chega ao fim.

## spell e ctx: a magia e o contexto. area: área calculada na conjuração. impact: o impacto.
func execute(_spell: SpellInstance, _ctx: SpellContext, _area: ResolvedArea, _impact: ProjectileImpact) -> void:
	pass
