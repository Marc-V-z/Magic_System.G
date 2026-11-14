class_name SpellDefinition
extends Resource

@export var custom_name: String = ""      # vazio = nome automático
@export var shape: SpellShape             # pode ser um ShapeGroup
@export var elements: Array[SpellElement] = []
@export var cost: SpellCost               # custo próprio da magia (opcional)