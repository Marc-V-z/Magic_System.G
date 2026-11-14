class_name SpellShape
extends SpellComponent
## COMO a magia é entregue (projétil, rajada, em si mesmo...).

## Onde a magia nasce: no conjurador (padrão) ou no ponto mirado.
enum Anchor { CASTER, AIM_POINT }

## Prefixo do nome automático (ex.: "Bola de").
@export var name_prefix: String = ""
## Multiplica o poder calculado a partir dos elementos.
@export var power_multiplier: float = 1.0
@export var anchor: Anchor = Anchor.CASTER
## Efeitos da própria forma, aplicados junto com os dos elementos.
@export var effects: Array[SpellEffect] = []

## Gancho genérico: uma forma pode decidir em qual forma concreta se transforma.
## Formas simples devolvem a si mesmas. O SpellBuilder sempre chama este método.
func resolve(_elements: Array[SpellElement]) -> SpellShape:
	return self

## Entrega a magia. Subclasses escolhem alvos e chamam spell.apply_to(ctx, alvo).
func cast(_spell: SpellInstance, _ctx: SpellContext) -> void:
	pass

## Ponto de origem conforme a âncora. Sem ponto mirado, cai na origem do conjurador.
func get_origin(ctx: SpellContext) -> Variant:
	if anchor == Anchor.AIM_POINT and ctx.aim_point != null:
		return ctx.aim_point
	return ctx.origin
