class_name SpellArea
extends Resource
## Parâmetros nomeados de uma forma ou de uma parte: números (ValueSource) e rótulos.
## Os nomes são convenção entre você e o seu jogo. O sistema não conhece nenhum deles.

## Números nomeados. Cada um pode vir de constante, atributo, poder da magia ou conta.
@export var numbers: Array[NamedValue] = []
## Rótulos soltos que o jogo entende.
@export var labels: Array[StringName] = []

## Calcula os valores desta conjuração. origin vem da âncora da forma.
func resolve(ctx: SpellContext, origin: Variant) -> ResolvedArea:
	var result := ResolvedArea.new()
	result.origin = origin
	result.direction = ctx.direction
	for entry in numbers:
		if entry != null:
			result.numbers[entry.key] = ValueSource.read(entry.value, ctx)
	result.labels.append_array(labels)
	return result

## Junta duas áreas em uma nova. Números com o mesmo nome: vale o de override.
## Rótulos: união. Aceita null nos dois lados. Não altera as originais.
static func merged(base: SpellArea, override: SpellArea) -> SpellArea:
	var result := SpellArea.new()
	if base != null:
		result.numbers.append_array(base.numbers)
		result.labels.append_array(base.labels)
	if override != null:
		for entry in override.numbers:
			if entry == null:
				continue
			var replaced := false
			for i in result.numbers.size():
				if result.numbers[i] != null and result.numbers[i].key == entry.key:
					result.numbers[i] = entry
					replaced = true
					break
			if not replaced:
				result.numbers.append(entry)
		for label in override.labels:
			if not result.labels.has(label):
				result.labels.append(label)
	return result
