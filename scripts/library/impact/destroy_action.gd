class_name DestroyAction
extends ImpactAction
## Marca o projétil como destruído. O launcher para de movê-lo.

func execute(_part: SpellPartInstance, _ctx: SpellContext, _impact_area: ResolvedArea, impact: ProjectileImpact) -> void:
	impact.destroyed = true
