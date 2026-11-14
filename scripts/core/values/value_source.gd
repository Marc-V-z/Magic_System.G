class_name ValueSource
extends Resource
## Base: de onde vem um número bruto. Subclasses decidem (constante, atributo, conta).

func get_value(_ctx: SpellContext) -> float:
	return 0.0

## Atalho seguro: devolve o valor da fonte, ou default_value se a fonte for nula.
static func read(source: ValueSource, ctx: SpellContext, default_value: float = 0.0) -> float:
	if source == null:
		return default_value
	return source.get_value(ctx)
