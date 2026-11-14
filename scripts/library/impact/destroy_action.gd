class_name DestroyAction
extends ImpactAction
## Marca o projétil como destruído. O launcher para de movê-lo.

func execute(_spell: SpellInstance, _ctx: SpellContext, _area: ResolvedArea, impact: ProjectileImpact) -> void:
	impact.destroyed = true
