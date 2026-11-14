class_name TargetFinder
extends RefCounted
## Contrato: o jogo diz quem é atingido por uma área.
## A ResolvedArea traz origem, direção, números nomeados e rótulos. O jogo decide o que
## cada nome significa (casas, pixels, slots de carta, "todos os inimigos"...).

func find_targets(_area: ResolvedArea, _ctx: SpellContext) -> Array:
	return []
