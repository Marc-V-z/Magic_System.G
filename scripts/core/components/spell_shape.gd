class_name SpellShape
extends SpellComponent
## COMO a magia é entregue (projétil, explosão, em si mesmo...).

## Prefixo do nome automático (ex.: "Bola de").
@export var name_prefix: String = ""
## Multiplica o poder calculado a partir dos elementos.
@export var power_multiplier: float = 1.0

## Gancho genérico: uma forma pode decidir em qual forma concreta se transforma.
## Formas simples devolvem a si mesmas. O SpellBuilder sempre chama este método.
func resolve(_elements: Array[SpellElement]) -> SpellShape:
	return self

## Entrega a magia. Subclasses escolhem alvos e chamam spell.apply_to(ctx, alvo).
func cast(_spell: SpellInstance, _ctx: SpellContext) -> void:
	pass
