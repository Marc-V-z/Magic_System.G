class_name SpellNamer
extends RefCounted
## Decide o nome da magia. Substitua por outra classe se quiser outra regra de nomes.

func build_name(definition: SpellDefinition, parts: Array[SpellPartInstance]) -> String:
	if definition.custom_name != "":
		return definition.custom_name
	var order: Array[String] = []
	var counts := {}
	for part in parts:
		var part_name := _part_name(part)
		if not counts.has(part_name):
			order.append(part_name)
			counts[part_name] = 0
		counts[part_name] += 1
	var labeled := PackedStringArray()
	for part_name in order:
		if counts[part_name] == 1:
			labeled.append(part_name)
		else:
			labeled.append("%s (x%d)" % [part_name, counts[part_name]])
	return " e ".join(labeled)

func _part_name(part: SpellPartInstance) -> String:
	var element_names := PackedStringArray()
	for element in part.elements:
		element_names.append(element.display_name)
	return ("%s %s" % [part.shape.name_prefix, " e ".join(element_names)]).strip_edges()
