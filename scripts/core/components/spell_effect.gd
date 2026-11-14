class_name SpellEffect
extends Resource
## Base: algo que acontece com um alvo (dano, cura, status...). Subclasses implementam apply.

## target: quem recebe (qualquer objeto do jogo). power: poder já calculado. ctx: contexto.
func apply(_target: Object, _power: float, _ctx: SpellContext) -> void:
	pass
