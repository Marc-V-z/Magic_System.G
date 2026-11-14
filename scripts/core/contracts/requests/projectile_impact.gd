class_name ProjectileImpact
extends RefCounted
## Um impacto de projétil, preenchido pelo launcher.

## Onde aconteceu.
var point: Variant
## Alvos atingidos diretamente (pode ser vazio, por exemplo no fim do trajeto).
var targets: Array = []
## true se este impacto é o fim do trajeto.
var is_end: bool = false
## As ações de impacto marcam true para destruir o projétil.
var destroyed: bool = false
