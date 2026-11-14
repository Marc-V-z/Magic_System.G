class_name ProjectileShape
extends SpellShape
## Projétil. Os parâmetros do trajeto (SpellShape.area, ajustáveis por parte) e do impacto
## (impact_area) vão ao jogo, que decide o que significam. O ProjectileLauncher do jogo
## realiza o projétil e avisa cada impacto.

## Identificador para o jogo escolher cena ou animação.
@export var projectile_id: StringName
## true: colide em todo o trajeto. false: só vale o impacto no fim.
@export var collide_along_path: bool = true
## Parâmetros do efeito no impacto (ex.: um raio). Vazio = só os alvos atingidos diretamente.
@export var impact_area: SpellArea
## O que fazer a cada impacto, em ordem. Vazio = aplicar efeitos e destruir.
@export var impact_actions: Array[ImpactAction] = []

func cast(part: SpellPartInstance, ctx: SpellContext) -> void:
	if ctx.launcher == null:
		push_warning("ProjectileShape: o contexto não tem ProjectileLauncher.")
		return
	var path := part.area.resolve(ctx, get_origin(ctx))
	var at_impact := ResolvedArea.new()
	if impact_area != null:
		at_impact = impact_area.resolve(ctx, null)
	var request := ProjectileRequest.new()
	request.part = part
	request.ctx = ctx
	request.area = path
	request.projectile_id = projectile_id
	request.collide_along_path = collide_along_path
	request.on_impact = _handle_impact.bind(part, ctx, at_impact)
	ctx.launcher.launch(request)

func _handle_impact(impact: ProjectileImpact, part: SpellPartInstance, ctx: SpellContext, at_impact: ResolvedArea) -> void:
	var actions: Array[ImpactAction] = impact_actions
	if actions.is_empty():
		actions = _default_actions()
	for action in actions:
		action.execute(part, ctx, at_impact, impact)

func _default_actions() -> Array[ImpactAction]:
	var defaults: Array[ImpactAction] = [ApplyEffectsAction.new(), DestroyAction.new()]
	return defaults
