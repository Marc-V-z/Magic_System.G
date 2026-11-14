class_name SpellEffect
extends Resource
## Base: algo que acontece com um alvo (dano, cura, status...). Subclasses implementam apply.

## target: quem recebe. power: poder já calculado da magia. ctx: contexto da conjuração.
func apply(_target: Node, _power: float, _ctx: SpellContext) -> void:
	pass
