class_name SpellCondition
extends Resource
## Base de condições que olham os elementos de uma magia.

func is_met(_elements: Array[SpellElement]) -> bool:
	return true
