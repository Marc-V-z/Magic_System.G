class_name TestFinder
extends TargetFinder
## TargetFinder de teste: devolve uma lista fixa e guarda a última área pedida.

var targets: Array = []
var last_area: ResolvedArea
var calls: int = 0

func find_targets(area: ResolvedArea, _ctx: SpellContext) -> Array:
	last_area = area
	calls += 1
	return targets
