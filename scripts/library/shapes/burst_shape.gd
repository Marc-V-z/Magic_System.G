class_name BurstShape
extends SpellShape
## Rajada ou explosão. Os parâmetros (SpellShape.area, ajustáveis por parte) vão ao
## TargetFinder do jogo, que decide quem é atingido. Instantânea: acerta uma vez.
## Não instantânea: repete ao longo do tempo pelo SustainedAreaRunner do jogo.

@export var instant: bool = true
## Usados só quando instant é false. As unidades (segundos, turnos...) são do jogo.
@export var duration: ValueSource
@export var tick_interval: ValueSource

func cast(part: SpellPartInstance, ctx: SpellContext) -> void:
	var resolved := part.area.resolve(ctx, get_origin(ctx))
	if instant or ctx.sustained == null:
		if not instant:
			push_warning("BurstShape: sem SustainedAreaRunner, executando de forma instantânea.")
		_hit(part, ctx, resolved)
		return
	var request := SustainedRequest.new()
	request.part = part
	request.ctx = ctx
	request.area = resolved
	request.duration = ValueSource.read(duration, ctx)
	request.tick_interval = ValueSource.read(tick_interval, ctx)
	request.on_tick = _hit.bind(part, ctx, resolved)
	ctx.sustained.start(request)

func _hit(part: SpellPartInstance, ctx: SpellContext, resolved: ResolvedArea) -> void:
	if ctx.finder == null:
		return
	for target in ctx.finder.find_targets(resolved, ctx):
		part.apply_to(ctx, target)
