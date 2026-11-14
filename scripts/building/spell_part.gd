class_name SpellPart
extends Resource
## Uma parte da receita: uma forma, os elementos só desta parte e ajustes de parâmetros.
## Exemplo: o tiro triplo tem 3 partes com a mesma forma de projétil e ângulos diferentes.

@export var shape: SpellShape
## Elementos só desta parte. Os elementos da SpellDefinition também valem para ela.
@export var elements: Array[SpellElement] = []
## Parâmetros desta parte. Sobrescrevem, por nome, os da forma. Opcional.
@export var area: SpellArea
