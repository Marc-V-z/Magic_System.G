class_name SpellBuilder
extends RefCounted
## Monta um SpellInstance a partir de um SpellDefinition.

var namer: SpellNamer

func _init(custom_namer: SpellNamer = null) -> void:
	namer = custom_namer if custom_namer != null else SpellNamer.new()

## Devolve o SpellInstance, ou null se a definição for inválida ou nenhuma forma for resolvida.
func build(definition: SpellDefinition) -> SpellInstance:
	if definition == null or definition.shape == null:
		push_error("SpellBuilder: a definição precisa de uma forma.")
		return null

	var shape := definition.shape.resolve(definition.elements)
	if shape == null:
		push_error("SpellBuilder: nenhuma forma foi resolvida para esta magia.")
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
