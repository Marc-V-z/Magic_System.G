class_name TargetFinder
extends RefCounted
## Contrato: o jogo diz quem está dentro de uma área.
## Ação 2D/3D: consulta de física. Tático: células da grade. Por turnos ou cartas: alvos escolhidos.

func find_targets(_area: ResolvedArea, _ctx: SpellContext) -> Array:
	return []
