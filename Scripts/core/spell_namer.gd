class_name SpellNamer
extends RefCounted

func build_name(definition: SpellDefinition, shape: SpellShape, elements: Array[SpellElement]) -> String:
	if definition.custom_name != "":
		return definition.custom_name
	var names := PackedStringArray()
	for element in elements:
		names.append(element.display_name)
	return "%s %s" % [shape.name_prefix, " e ".join(names)]