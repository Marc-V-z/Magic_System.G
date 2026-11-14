class_name SustainedRequest
extends RefCounted
## Pedido de área sustentada enviado ao SustainedAreaRunner.

var part: SpellPartInstance
var ctx: SpellContext
## Calculada uma vez na conjuração. Não acompanha o conjurador se ele se mover.
var area: ResolvedArea
var duration: float = 0.0
var tick_interval: float = 0.0
## Callable sem argumentos. O runner chama a cada tick.
var on_tick: Callable
