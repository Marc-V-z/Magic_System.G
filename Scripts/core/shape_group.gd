class_name ShapeGroup
extends SpellShape

# Organizador: escolhe qual subforma usar conforme os elementos.
@export var variants: Array[ShapeVariant] = []
@export var fallback: SpellShape

func resolve(elements: Array[SpellElement]) -> SpellShape:
	for variant in variants:
		if variant.condition != null and variant.condition.is_met(elements):
			return variant.shape.resolve(elements)  # permite grupos dentro de grupos
	if fallback != null:
		return fallback.resolve(elements)
	return null