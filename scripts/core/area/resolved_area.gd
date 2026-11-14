class_name ResolvedArea
extends RefCounted
## Parâmetros de área já calculados para uma conjuração.
## O sistema NÃO sabe o que eles significam: quem interpreta é o jogo.
## Exemplo: o número "reach" = 3 pode ser 3 casas, 3 vezes X pixels, ou "3 slots atrás".

## Ponto de partida (Vector2, Vector3, célula de grade, slot de carta, o que o jogo usar).
var origin: Variant
## Direção base da mira (opcional, qualquer tipo).
var direction: Variant
## Números nomeados já calculados. Chave: StringName. Valor: float.
var numbers: Dictionary = {}
## Rótulos soltos que o jogo entende (ex.: &"enemies", &"back_row").
var labels: Array[StringName] = []

## Devolve o número com esse nome, ou default_value se ele não existir.
func get_number(key: StringName, default_value: float = 0.0) -> float:
	return float(numbers.get(key, default_value))

func has_number(key: StringName) -> bool:
	return numbers.has(key)

func has_label(label: StringName) -> bool:
	return labels.has(label)

## true se não há nenhum número nem rótulo.
func is_empty() -> bool:
	return numbers.is_empty() and labels.is_empty()

## Devolve uma cópia com outro ponto de partida (usada nos impactos).
func moved_to(point: Variant) -> ResolvedArea:
	var copy := ResolvedArea.new()
	copy.origin = point
	copy.direction = direction
	copy.numbers = numbers.duplicate()
	copy.labels.append_array(labels)
	return copy
