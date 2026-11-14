class_name SpellElement
extends SpellComponent
## O QUE a magia faz: número bruto, efeitos, tags e custo.

## Usado no nome automático da magia (ex.: "fogo").
@export var display_name: String = ""
## Número bruto do elemento (constante, atributo, produto...). Opcional.
@export var power: ValueSource
@export var effects: Array[SpellEffect] = []
