class_name TestCase
extends Node
## Base mínima para os testes descartáveis.

var _passed: int = 0
var _failed: int = 0

func section(title: String) -> void:
	print("")
	print(title)

func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  [ok] ", label)
	else:
		_failed += 1
		print("  [FALHOU] ", label)

## Imprime o resultado e fecha a cena de teste.
func finish() -> void:
	print("")
	print("Resultado: %d ok, %d falhas" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)
