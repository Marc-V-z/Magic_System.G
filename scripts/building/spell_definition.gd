class_name SpellDefinition
extends Resource
## Receita editável de uma magia. O SpellBuilder transforma isto em SpellInstance.

## Vazio = nome automático (forma + elementos).
@export var custom_name: String = ""
@export var shape: SpellShape
@export var elements: Array[SpellElement] = []
## Custo próprio da magia, somado ao da forma e ao dos elementos. Opcional.
@export var cost: SpellCost
