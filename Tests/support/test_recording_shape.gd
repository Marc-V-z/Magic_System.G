class_name TestRecordingShape
extends SpellShape
## Forma de teste: conta quantas vezes foi conjurada e aplica a parte no conjurador.

var cast_count: int = 0

func cast(part: SpellPartInstance, ctx: SpellContext) -> void:
	cast_count += 1
	part.apply_to(ctx, ctx.caster)
