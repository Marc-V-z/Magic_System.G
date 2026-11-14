class_name ApplyEffectsAction
extends ImpactAction
## Aplica os efeitos da parte. Com use_impact_area ligado e a forma tendo impact_area,
## pergunta ao TargetFinder quem é atingido por essa área centrada no ponto de impacto.
## Senão, usa os alvos atingidos diretamente.

@export var use_impact_area: bool = true

func execute(part: SpellPartInstance, ctx: SpellContext, impact_area: ResolvedArea, impact: ProjectileImpact) -> void:
	var targets: Array = impact.targets
	if use_impact_area and ctx.finder != null and not impact_area.is_empty():
		targets = ctx.finder.find_targets(impact_area.moved_to(impact.point), ctx)
	for target in targets:
		part.apply_to(ctx, target)
