class_name ProjectileRequest
extends RefCounted
## Pedido de projétil enviado ao ProjectileLauncher.

var spell: SpellInstance
var ctx: SpellContext
var area: ResolvedArea
## Identificador para o jogo escolher a cena ou animação (ex.: &"fireball").
var projectile_id: StringName
## true: colide em todo o trajeto. false: só vale o impacto no fim.
var collide_along_path: bool = true
## Callable(impact: ProjectileImpact). O launcher chama a cada impacto.
var on_impact: Callable
