class_name SpellRequirement
extends Resource
## Base: uma condição para a magia poder ser conjurada (equipamento, estado, nível...).

## Texto opcional para mostrar ao jogador quando a condição falha.
@export var failure_message: String = ""

func is_met(_ctx: SpellContext) -> bool:
	return true
