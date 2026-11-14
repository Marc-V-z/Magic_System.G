class_name SpellCost
extends Resource

# Chave: nome do recurso (ex.: &"mana"). Valor: quantidade.
@export var amounts: Dictionary = {}

func merged_with(other: SpellCost) -> SpellCost:
	var result := SpellCost.new()
	result.amounts = amounts.duplicate()
	if other == null:
		return result
	for key in other.amounts:
		result.amounts[key] = result.amounts.get(key, 0.0) + other.amounts[key]
	return result