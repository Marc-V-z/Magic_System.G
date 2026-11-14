class_name TagRequirement
extends SpellRequirement
## Exige que o conjurador tenha (ou não tenha) uma tag. Serve para equipamentos e estados.
## Sem TagProvider no contexto não dá para saber: "ter" falha e "não ter" passa.

@export var tag: StringName
@export var must_have: bool = true

func is_met(ctx: SpellContext) -> bool:
	var has_it := ctx != null and ctx.tags != null and ctx.tags.has_tag(tag)
	return has_it == must_have
