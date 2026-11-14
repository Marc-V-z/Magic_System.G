class_name SpellInstance
extends RefCounted

var display_name: String
var shape: SpellShape
var elements: Array[SpellElement]
var cost: SpellCost

func compute_power(ctx: SpellContext) -> float:
	var total := 0.0
	for element in elements:
		if element.power != null:
			total += element.power.get_value(ctx)
	return total * shape.power_multiplier

func apply_to(ctx: SpellContext, target: Node) -> void:
	var power := compute_power(ctx)
	for element in elements:
		for effect in element.effects:
			effect.apply(target, power, ctx)