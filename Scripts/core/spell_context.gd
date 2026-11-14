class_name SpellContext
extends RefCounted

var caster: Node
var stats: StatProvider
var payer: CostPayer
var origin: Variant      # Vector2 ou Vector3, conforme o jogo
var direction: Variant   # idem