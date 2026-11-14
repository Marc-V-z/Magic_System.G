class_name TestRecordingShape
extends SpellShape
## Forma de teste: conta quantas vezes foi conjurada e aplica a magia no conjurador.

var cast_count: int = 0

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	cast_count += 1
	spell.apply_to(ctx, ctx.caster)
