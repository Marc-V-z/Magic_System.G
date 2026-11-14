class_name SpellBuilder
extends RefCounted

var namer := SpellNamer.new()

func build(definition: SpellDefinition) -> SpellInstance:
	var shape := definition.shape.resolve(definition.elements)
	if shape == null:
		push_error("SpellBuilder: nenhuma forma resolvida para a magia.")
		return null

	var cost := SpellCost.new().merged_with(definition.cost).merged_with(shape.cost)
	for element in definition.elements:
		cost = cost.merged_with(element.cost)

	var spell := SpellInstance.new()
	spell.shape = shape
	spell.elements = definition.elements
	spell.cost = cost
	spell.display_name = namer.build_name(definition, shape, definition.elements)
	return spell