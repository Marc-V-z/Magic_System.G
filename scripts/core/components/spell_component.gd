class_name SpellComponent
extends Resource
## Base comum de forma e elemento: custo, tags e requisitos.

@export var cost: SpellCost
@export var tags: Array[StringName] = []
@export var requirements: Array[SpellRequirement] = []
