class_name TestTags
extends TagProvider
## TagProvider de teste, com uma lista fixa de tags.

var tags: Array[StringName] = []

func _init(list: Array = []) -> void:
	for item in list:
		tags.append(StringName(item))

func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
