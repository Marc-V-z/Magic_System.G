class_name ProjectileShape
extends SpellShape
## Projétil. O sistema calcula a área e pede ao ProjectileLauncher do jogo para realizá-lo.
## Área: distance = alcance do trajeto, radius = raio de efeito no impacto, angle_offset = desvio.

## Identificador para o jogo escolher cena ou animação.
@export var projectile_id: StringName
## true: colide em todo o trajeto. false: só vale o impacto no fim.
@export var collide_along_path: bool = true
@export var area: SpellArea
## O que fazer a cada impacto, em ordem. Vazio = aplicar efeitos e destruir.
@export var impact_actions: Array[ImpactAction] = []

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	if ctx.launcher == null:
		push_warning("ProjectileShape: o contexto não tem ProjectileLauncher.")
		return
	var resolved := _resolve_area(ctx)
	var request := ProjectileRequest.new()
	request.spell = spell
	request.ctx = ctx
	request.area = resolved
	request.projectile_id = projectile_id
	request.collide_along_path = collide_along_path
	request.on_impact = _handle_impact.bind(spell, ctx, resolved)
	ctx.launcher.launch(request)

func _resolve_area(ctx: SpellContext) -> ResolvedArea:
	var source := area if area != null else SpellArea.new()
	return source.resolve(ctx, get_origin(ctx))

func _handle_impact(impact: ProjectileImpact, spell: SpellInstance, ctx: SpellContext, resolved: ResolvedArea) -> void:
	var actions: Array[ImpactAction] = impact_actions
	if actions.is_empty():
		actions = _default_actions()
	for action in actions:
		action.execute(spell, ctx, resolved, impact)

func _default_actions() -> Array[ImpactAction]:
	var defaults: Array[ImpactAction] = [ApplyEffectsAction.new(), DestroyAction.new()]
	return defaults
