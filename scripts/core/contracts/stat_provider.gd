class_name StatProvider
extends RefCounted
## Contrato: o jogo herda desta classe para expor seus atributos ao sistema.

## Devolve o valor do atributo pedido, ou default_value se o jogo não o tiver.
func get_stat(_key: StringName, default_value: float = 0.0) -> float:
	return default_value
