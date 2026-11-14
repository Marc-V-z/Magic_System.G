class_name SpellDefinition
extends Resource
## Receita editável de uma magia. O SpellBuilder transforma isto em SpellInstance.
## Uma magia tem uma ou mais partes, conjuradas em ordem.

## Vazio = nome automático.
@export var custom_name: String = ""
@export var parts: Array[SpellPart] = []
## Elementos que valem para TODAS as partes. O custo deles conta uma vez só.
@export var elements: Array[SpellElement] = []
## Custo próprio da magia, somado ao resto. Opcional.
@export var cost: SpellCost
## Requisitos próprios da magia, somados aos demais. Opcional.
@export var requirements: Array[SpellRequirement] = []
