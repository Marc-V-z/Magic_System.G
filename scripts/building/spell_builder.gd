class_name SpellBuilder
extends RefCounted
## Monta um SpellInstance a partir de um SpellDefinition.

var namer: SpellNamer

func _init(custom_namer: SpellNamer = null) -> void:
	namer = custom_namer if custom_namer != null else SpellNamer.new()

## Devolve o SpellInstance, ou null se a definição for inválida
## (sem partes, parte sem forma, ou forma que não se resolve).
func build(definition: SpellDefinition) -> SpellInstance:
	if definition == null or definition.parts.is_empty():
		push_error("SpellBuilder: a definição precisa de pelo menos uma parte.")
		return null

	var cost := SpellCost.new().merged_with(definition.cost)
	var requirements: Array[SpellRequirement] = []
	requirements.append_array(definition.requirements)
	for shared in definition.elements:
		cost = cost.merged_with(shared.cost)
		requirements.append_array(shared.requirements)

	var built_parts: Array[SpellPartInstance] = []
	for part in definition.parts:
		if part == null or part.shape == null:
			push_error("SpellBuilder: toda parte precisa de uma forma.")
			return null

		var part_elements: Array[SpellElement] = []
		part_elements.append_array(definition.elements)
		part_elements.append_array(part.elements)

		var shape := part.shape.resolve(part_elements)
		if shape == null:
			push_error("SpellBuilder: nenhuma forma foi resolvida para uma das partes.")
			return null

		cost = cost.merged_with(shape.cost)
		requirements.append_array(shape.requirements)
		for own in part.elements:
			cost = cost.merged_with(own.cost)
			requirements.append_array(own.requirements)

		var built := SpellPartInstance.new()
		built.shape = shape
		built.elements = part_elements
		built.area = SpellArea.merged(shape.area, part.area)
		built_parts.append(built)

	var spell := SpellInstance.new()
	spell.parts = built_parts
	spell.cost = cost
	spell.requirements = requirements
	spell.display_name = namer.build_name(definition, built_parts)
	return spell
