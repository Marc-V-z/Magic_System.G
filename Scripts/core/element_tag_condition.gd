class_name ElementTagCondition
extends SpellCondition

@export var tag: StringName

func is_met(elements: Array[SpellElement]) -> bool:
	for element in elements:
		if element.tags.has(tag):
			return true
	return false