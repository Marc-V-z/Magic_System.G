class_name TestDummy
extends Node
## Personagem falso: tem atributos, recursos e vida.

var hp: float = 100.0
var stats: Dictionary = {}
var resources: Dictionary = {}

func take_damage(amount: float) -> void:
	hp -= amount
