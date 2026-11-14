class_name SpellCost
extends Resource
## Conjunto de custos genérico. Não sabe o que é mana ou vida.

## Chave: nome do recurso (ex.: "mana"). Valor: quantidade (float).
@export var amounts: Dictionary = {}

## Devolve um NOVO SpellCost com a soma deste com o outro. Não altera nenhum dos dois.
## Aceita null (conta como custo vazio).
func merged_with(other: SpellCost) -> SpellCost:
	var result := SpellCost.new()
	result.amounts = amounts.duplicate()
	if other == null:
		return result
	for key in other.amounts:
		result.amounts[key] = result.amounts.get(key, 0.0) + other.amounts[key]
	return result
