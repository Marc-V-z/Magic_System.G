class_name TestPayer
extends CostPayer
## CostPayer de teste, cobra do dicionário resources do TestDummy.

var player: TestDummy

func _init(p: TestDummy) -> void:
	player = p

func can_pay(cost: SpellCost) -> bool:
	for key in cost.amounts:
		if player.resources.get(key, 0.0) < cost.amounts[key]:
			return false
	return true

func pay(cost: SpellCost) -> void:
	for key in cost.amounts:
		player.resources[key] = player.resources.get(key, 0.0) - cost.amounts[key]
