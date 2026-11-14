class_name DamageEffect
extends SpellEffect
## Causa dano chamando target.take_damage(valor), se o alvo tiver esse método.

@export var multiplier: float = 1.0

func apply(target: Node, power: float, _ctx: SpellContext) -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(power * multiplier)
