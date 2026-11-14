extends TestCase
## Testa requisitos: tags (equipamentos e estados), atributos e bloqueio da conjuração.

func _ready() -> void:
	print("=== Magic_System.G: testes de requisitos ===")
	_test_tag_requirement()
	_test_stat_requirement()
	_test_requirements_merge_and_block_cast()
	finish()

func _tag_req(tag: StringName, must_have: bool) -> TagRequirement:
	var requirement := TagRequirement.new()
	requirement.tag = tag
	requirement.must_have = must_have
	return requirement

func _stat_req(key: StringName, minimum: float) -> StatAtLeastRequirement:
	var requirement := StatAtLeastRequirement.new()
	requirement.stat_key = key
	requirement.minimum = minimum
	return requirement

func _test_tag_requirement() -> void:
	section("TagRequirement: equipamento e estado")
	var dummy := TestDummy.new()
	var ctx := TestFactory.context(dummy)
	var needs_staff := _tag_req(&"equip:staff", true)
	var not_silenced := _tag_req(&"state:silenced", false)

	ctx.tags = TestTags.new([])
	check(not needs_staff.is_met(ctx), "sem cajado: requisito falha")
	check(not_silenced.is_met(ctx), "sem silêncio: requisito passa")

	ctx.tags = TestTags.new(["equip:staff", "state:silenced"])
	check(needs_staff.is_met(ctx), "com cajado: requisito passa")
	check(not not_silenced.is_met(ctx), "silenciado: requisito falha")
	dummy.free()

func _test_stat_requirement() -> void:
	section("StatAtLeastRequirement")
	var dummy := TestDummy.new()
	dummy.stats = {"level": 5.0}
	var ctx := TestFactory.context(dummy)
	check(_stat_req(&"level", 5.0).is_met(ctx), "nível 5 cumpre mínimo 5")
	check(not _stat_req(&"level", 6.0).is_met(ctx), "nível 5 não cumpre mínimo 6")
	dummy.free()

func _test_requirements_merge_and_block_cast() -> void:
	section("Requisitos de forma e elemento bloqueiam a conjuração")
	var dummy := TestDummy.new()
	dummy.stats = {"level": 5.0}
	dummy.resources = {"mana": 10.0}
	var shape := TestFactory.shape("Bola de", {"mana": 5.0})
	shape.requirements.append(_tag_req(&"equip:staff", true))
	var element := TestFactory.element("fogo", TestFactory.constant(1.0))
	element.requirements.append(_stat_req(&"level", 3.0))
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, element))
	check(spell.requirements.size() == 2, "requisitos de forma e elemento foram somados")

	var ctx := TestFactory.context(dummy)
	ctx.tags = TestTags.new([])
	var caster := SpellCaster.new()
	check(caster.can_cast(spell, ctx) == SpellCaster.Result.REQUIREMENT_NOT_MET, "sem cajado: can_cast recusa")
	check(caster.cast(spell, ctx) == SpellCaster.Result.REQUIREMENT_NOT_MET, "cast recusa")
	check(is_equal_approx(dummy.resources["mana"], 10.0), "nada foi cobrado")
	check(shape.cast_count == 0, "forma não foi disparada")

	ctx.tags = TestTags.new(["equip:staff"])
	check(caster.can_cast(spell, ctx) == SpellCaster.Result.OK, "com cajado: can_cast aceita")
	check(is_equal_approx(dummy.resources["mana"], 10.0), "can_cast não cobra nada")
	check(caster.cast(spell, ctx) == SpellCaster.Result.OK, "cast aceita")
	check(is_equal_approx(dummy.resources["mana"], 5.0), "mana cobrada: 10 - 5 = 5")
	dummy.free()
