extends TestCase
## Testa a extensão opcional shape_variants. Apague junto com a pasta da extensão.

func _ready() -> void:
	print("=== Magic_System.G: testes de shape_variants ===")
	_test_group_picks_variant_by_tag()
	_test_nested_group()
	finish()

func _make_group(fallback: SpellShape, tag: StringName, variant_shape: SpellShape) -> ShapeGroup:
	var condition := ElementTagCondition.new()
	condition.tag = tag
	var variant := ShapeVariant.new()
	variant.condition = condition
	variant.shape = variant_shape
	var group := ShapeGroup.new()
	group.fallback = fallback
	group.variants.append(variant)
	return group

func _test_group_picks_variant_by_tag() -> void:
	section("Grupo escolhe Estaca de ou Bola de conforme a tag")
	var ball := TestFactory.shape("Bola de", {"mana": 5.0})
	var stake := TestFactory.shape("Estaca de", {"mana": 3.0})
	var group := _make_group(ball, &"solid", stake)
	var fire := TestFactory.element("fogo", TestFactory.constant(1.0), {}, &"fire")
	var earth := TestFactory.element("terra", TestFactory.constant(1.0), {}, &"solid")

	var fire_spell := SpellBuilder.new().build(TestFactory.definition(group, fire))
	check(fire_spell.display_name == "Bola de fogo", "fogo vira Bola de fogo")
	check(fire_spell.shape == ball, "forma resolvida é a bola")
	check(is_equal_approx(fire_spell.cost.amounts.get("mana", 0.0), 5.0), "custo é só o da forma escolhida")

	var earth_spell := SpellBuilder.new().build(TestFactory.definition(group, earth))
	check(earth_spell.display_name == "Estaca de terra", "terra vira Estaca de terra")
	check(earth_spell.shape == stake, "forma resolvida é a estaca")
	check(is_equal_approx(earth_spell.cost.amounts.get("mana", 0.0), 3.0), "custo é só o da estaca")

func _test_nested_group() -> void:
	section("Grupo dentro de grupo")
	var ball := TestFactory.shape("Bola de")
	var stake := TestFactory.shape("Estaca de")
	var inner := _make_group(ball, &"solid", stake)
	var outer := _make_group(inner, &"never_used_tag", TestFactory.shape("Nunca de"))
	var earth := TestFactory.element("terra", TestFactory.constant(1.0), {}, &"solid")
	var spell := SpellBuilder.new().build(TestFactory.definition(outer, earth))
	check(spell.display_name == "Estaca de terra", "o grupo externo cai no interno, que escolhe a estaca")
