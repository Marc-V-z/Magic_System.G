class_name SpellArea
extends Resource
## Descrição de uma área. Cada número é um ValueSource, então pode vir de atributos,
## da forma, da magia final ou ser uma constante. Fonte vazia vale 0.

## Alcance. 0 = onde foi conjurado.
@export var distance: ValueSource
## Raio de efeito.
@export var radius: ValueSource
## Desvio de direção em graus, somado à direção da mira. Vazio = reto.
@export var angle_offset: ValueSource

## Calcula a área concreta desta conjuração. origin vem da âncora da forma.
func resolve(ctx: SpellContext, origin: Variant) -> ResolvedArea:
	var result := ResolvedArea.new()
	result.origin = origin
	result.direction = ctx.direction
	result.distance = ValueSource.read(distance, ctx)
	result.radius = ValueSource.read(radius, ctx)
	result.angle_offset = ValueSource.read(angle_offset, ctx)
	return result
