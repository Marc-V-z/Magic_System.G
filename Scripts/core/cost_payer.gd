class_name CostPayer
extends RefCounted

# O jogo herda desta classe para dizer como cobrar custos.
func can_pay(_cost: SpellCost) -> bool:
	return true

func pay(_cost: SpellCost) -> void:
	pass