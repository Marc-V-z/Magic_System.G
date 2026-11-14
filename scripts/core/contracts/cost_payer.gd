class_name CostPayer
extends RefCounted
## Contrato: o jogo herda desta classe para dizer como verificar e cobrar custos.

## Devolve true se o conjurador consegue pagar o custo inteiro.
func can_pay(_cost: SpellCost) -> bool:
	return true

## Cobra o custo. O SpellCaster só chama depois de can_pay devolver true.
func pay(_cost: SpellCost) -> void:
	pass
