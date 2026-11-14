class_name ApplyEffectsAction
extends ImpactAction
## Aplica os efeitos da magia. Com affect_area, usa o raio da área centrada no impacto
## (via TargetFinder). Sem raio ou sem TargetFinder, usa os alvos diretos do impacto.

@export var affect_area: bool = true

func execute(spell: SpellInstance, ctx: SpellContext, area: ResolvedArea, impact: ProjectileImpact) -> void:
	var targets: Array = impact.targets
	if affect_area and ctx.finder != null and area.radius > 0.0:
		targets = ctx.finder.find_targets(area.moved_to(impact.point), ctx)
	for target in targets:
		spell.apply_to(ctx, target)
