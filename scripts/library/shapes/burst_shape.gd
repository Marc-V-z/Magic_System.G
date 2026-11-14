class_name BurstShape
extends SpellShape
## Rajada ou explosão em uma área. Cobre também bomba (âncora AIM_POINT) e rajada longa
## (distance grande). Instantânea: acerta uma vez. Não instantânea: repete ao longo do tempo.

@export var area: SpellArea
@export var instant: bool = true
## Usados só quando instant é false. No jogo por turnos, "tempo" pode ser turnos.
@export var duration: ValueSource
@export var tick_interval: ValueSource

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	var source := area if area != null else SpellArea.new()
	var resolved := source.resolve(ctx, get_origin(ctx))
	if instant or ctx.sustained == null:
		if not instant:
			push_warning("BurstShape: sem SustainedAreaRunner, executando de forma instantânea.")
		_hit(spell, ctx, resolved)
		return
	var request := SustainedRequest.new()
	request.spell = spell
	request.ctx = ctx
	request.area = resolved
	request.duration = ValueSource.read(duration, ctx)
	request.tick_interval = ValueSource.read(tick_interval, ctx)
	request.on_tick = _hit.bind(spell, ctx, resolved)
	ctx.sustained.start(request)

func _hit(spell: SpellInstance, ctx: SpellContext, resolved: ResolvedArea) -> void:
	if ctx.finder == null:
		return
	for target in ctx.finder.find_targets(resolved, ctx):
		spell.apply_to(ctx, target)
