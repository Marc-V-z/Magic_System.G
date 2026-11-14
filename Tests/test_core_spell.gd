extends TestCase
## Testa o núcleo: custos, nomes, partes, poder, conjuração. Não usa extensões opcionais.

func _ready() -> void:
	print("=== Magic_System.G: testes do núcleo ===")
	_test_cost_is_summed()
	_test_names()
	_test_multi_part_names()
	_test_shared_elements()
	_test_cast_pays_cost_and_applies_effect()
	_test_cast_fails_without_resources()
	_test_self_shape_hits_caster()
	finish()

func _test_cost_is_summed() -> void:
	section("Custo somado de magia, forma e elemento")
	var shape := TestFactory.shape("Bola de", {"mana": 5.0})
	var element := TestFactory.element("fogo", TestFactory.constant(10.0), {"mana": 2.0, "hp": 2.0})
	var definition := TestFactory.definition(shape, element)
	definition.cost = TestFactory.cost({"gold": 3.0})
	var spell := SpellBuilder.new().build(definition)
	check(is_equal_approx(spell.cost.amounts.get("mana", 0.0), 7.0), "mana = 5 + 2")
	check(is_equal_approx(spell.cost.amounts.get("hp", 0.0), 2.0), "hp = 2")
	check(is_equal_approx(spell.cost.amounts.get("gold", 0.0), 3.0), "gold = 3 (custo da própria magia)")

func _test_names() -> void:
	section("Nome automático e nome próprio")
	var definition := TestFactory.definition(
		TestFactory.shape("Bola de"),
		TestFactory.element("fogo", TestFactory.constant(1.0)))
	var spell := SpellBuilder.new().build(definition)
	check(spell.display_name == "Bola de fogo", "automático: Bola de fogo")
	definition.custom_name = "Meteoro"
	spell = SpellBuilder.new().build(definition)
	check(spell.display_name == "Meteoro", "nome próprio vence o automático")

func _test_multi_part_names() -> void:
	section("Nome automático com várias partes")
	var definition := SpellDefinition.new()
	for element_name in ["fogo", "fogo", "água"]:
		var element := TestFactory.element(element_name, TestFactory.constant(1.0))
		definition.parts.append(TestFactory.part(TestFactory.shape("Bola de"), [element]))
	var spell := SpellBuilder.new().build(definition)
	check(spell.parts.size() == 3, "a magia tem 3 partes")
	check(spell.display_name == "Bola de fogo (x2) e Bola de água", "partes iguais são agrupadas no nome")
	definition.custom_name = "Tiro triplo"
	spell = SpellBuilder.new().build(definition)
	check(spell.display_name == "Tiro triplo", "nome próprio vence")

func _test_shared_elements() -> void:
	section("Elemento compartilhado: vale para todas as partes, custo uma vez")
	var ember := TestFactory.element("brasa", TestFactory.constant(1.0), {"mana": 1.0})
	var definition := SpellDefinition.new()
	definition.elements.append(ember)
	definition.parts.append(TestFactory.part(TestFactory.shape("Onda de", {"mana": 2.0})))
	var own := TestFactory.element("gelo", TestFactory.constant(2.0))
	definition.parts.append(TestFactory.part(TestFactory.shape("Raio de", {"mana": 4.0}), [own]))
	var spell := SpellBuilder.new().build(definition)
	check(is_equal_approx(spell.cost.amounts.get("mana", 0.0), 7.0), "mana = 2 + 4 + 1 (brasa conta uma vez)")
	check(spell.parts[0].elements.size() == 1, "parte 1 tem só o elemento compartilhado")
	check(spell.parts[1].elements.size() == 2, "parte 2 tem o compartilhado e o próprio")
	check(spell.display_name == "Onda de brasa e Raio de brasa e gelo", "nome usa os elementos de cada parte")

func _test_cast_pays_cost_and_applies_effect() -> void:
	section("Conjuração paga o custo uma vez e aplica o efeito")
	var dummy := TestDummy.new()
	dummy.stats = {"magic_power": 10.0}
	dummy.resources = {"mana": 10.0, "hp": 10.0}
	var shape := TestFactory.shape("Bola de", {"mana": 5.0}, 1.5)
	var element := TestFactory.element("fogo", TestFactory.stat(&"magic_power"), {"mana": 2.0, "hp": 2.0})
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, element))
	var ctx := TestFactory.context(dummy)
	var result := SpellCaster.new().cast(spell, ctx)
	check(result == SpellCaster.Result.OK, "cast devolveu OK")
	check(is_equal_approx(spell.parts[0].compute_power(ctx), 15.0), "poder = 10 * 1.5 = 15")
	check(is_equal_approx(dummy.hp, 85.0), "dano aplicado: 100 - 15 = 85")
	check(is_equal_approx(dummy.resources["mana"], 3.0), "mana 10 - 7 = 3")
	check(is_equal_approx(dummy.resources["hp"], 8.0), "recurso hp 10 - 2 = 8")
	check(shape.cast_count == 1, "forma foi disparada uma vez")
	dummy.free()

func _test_cast_fails_without_resources() -> void:
	section("Sem recursos, nada acontece")
	var dummy := TestDummy.new()
	dummy.stats = {"magic_power": 10.0}
	dummy.resources = {"mana": 1.0}
	var shape := TestFactory.shape("Bola de", {"mana": 5.0})
	var element := TestFactory.element("fogo", TestFactory.stat(&"magic_power"))
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, element))
	var result := SpellCaster.new().cast(spell, TestFactory.context(dummy))
	check(result == SpellCaster.Result.CANNOT_PAY, "cast devolveu CANNOT_PAY")
	check(shape.cast_count == 0, "forma não foi disparada")
	check(is_equal_approx(dummy.resources["mana"], 1.0), "mana intacta")
	check(is_equal_approx(dummy.hp, 100.0), "alvo intacto")
	dummy.free()

func _test_self_shape_hits_caster() -> void:
	section("SelfShape aplica no próprio conjurador")
	var dummy := TestDummy.new()
	var shape := SelfShape.new()
	shape.name_prefix = "Marca de"
	var element := TestFactory.element("fogo", TestFactory.constant(4.0))
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, element))
	var ctx := TestFactory.context(dummy)
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(dummy.hp, 96.0), "conjurador recebeu 4 de dano")
	dummy.free()
