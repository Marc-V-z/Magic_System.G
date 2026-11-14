class_name TagProvider
extends RefCounted
## Contrato: o jogo diz se o conjurador tem uma tag (ex.: "equip:staff", "state:silenced").
## É assim que requisitos de equipamentos e estados funcionam sem o sistema conhecer o jogo.

func has_tag(_tag: StringName) -> bool:
	return false
