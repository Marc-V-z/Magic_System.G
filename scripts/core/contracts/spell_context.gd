class_name SpellContext
extends RefCounted
## Dados de uma conjuração em andamento. Quem conjura preenche o que o jogo tiver.

## Quem está conjurando. Normalmente um Node do jogo.
var caster: Node
## Opcional. Fornece atributos (ex.: poder mágico) para os ValueSource.
var stats: StatProvider
## Opcional. Verifica e cobra os custos da magia.
var payer: CostPayer
## Posição de origem. Vector2 ou Vector3, conforme o jogo.
var origin: Variant
## Direção da mira. Vector2 ou Vector3, conforme o jogo.
var direction: Variant
