class_name ResolvedArea
extends RefCounted
## Área já calculada para uma conjuração. O jogo interpreta (2D, 3D, grade, lista de alvos...).

## Ponto de partida (Vector2, Vector3, célula de grade, o que o jogo usar).
var origin: Variant
## Direção base da mira.
var direction: Variant
## Alcance. 0 significa "onde foi conjurado".
var distance: float = 0.0
## Raio de efeito.
var radius: float = 0.0
## Desvio em graus somado à direção base (0 = reto).
var angle_offset: float = 0.0

## Devolve uma cópia centrada em outro ponto, com distância 0 (usada nos impactos).
func moved_to(point: Variant) -> ResolvedArea:
	var copy := ResolvedArea.new()
	copy.origin = point
	copy.direction = direction
	copy.distance = 0.0
	copy.radius = radius
	copy.angle_offset = angle_offset
	return copy
