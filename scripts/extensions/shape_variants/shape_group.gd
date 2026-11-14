class_name ShapeGroup
extends SpellShape
## Organizador: escolhe qual subforma usar conforme os elementos (ex.: Estaca de ou Bola de).
## Os campos herdados (name_prefix, cost, power_multiplier) são ignorados neste tipo.

@export var variants: Array[ShapeVariant] = []
@export var fallback: SpellShape

func resolve(elements: Array[SpellElement]) -> SpellShape:
	for variant in variants:
		if variant != null and variant.condition != null and variant.shape != null:
			if variant.condition.is_met(elements):
				return variant.shape.resolve(elements)  # permite grupos dentro de grupos
	if fallback != null:
		return fallback.resolve(elements)
	return null
