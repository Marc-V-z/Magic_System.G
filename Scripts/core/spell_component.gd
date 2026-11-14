class_name SpellComponent
extends Resource

# Base comum de forma e elemento: ambos podem ter custo e tags.
@export var cost: SpellCost
@export var tags: Array[StringName] = []