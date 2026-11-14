class_name SpellElement
extends SpellComponent

@export var display_name: String = ""
@export var power: ValueSource            # número bruto (constante ou atributo)
@export var effects: Array[SpellEffect] = []