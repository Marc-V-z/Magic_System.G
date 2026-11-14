extends TestCase
## Testa parâmetros de área genéricos, BurstShape, ProjectileShape, ações de impacto,
## reconjuração e magias com várias partes (tiro triplo).

func _ready() -> void:
	print("=== Magic_System.G: testes de área, formas e partes ===")
	_test_burst_generic_numbers()
	_test_burst_aim_point_anchor()
	_test_burst_sustained()
	_test_part_area_overrides_shape_area()
	_test_projectile_default_actions()
	_test_projectile_impact_area()
	_test_projectile_pierce_and_destroy()
	_test_projectile_recast()
	_test_recast_depth_guard()
	_test_triple_shot()
	finish()

func _fire(power: float = 10.0) -> SpellElement:
	return TestFactory.element("fogo", TestFactory.constant(power))

func _impact(point: Vector2, targets: Array) -> ProjectileImpact:
	var result := ProjectileImpact.new()
	result.point = point
	result.targets = targets
	return result

func _apply(use_impact_area: bool) -> ApplyEffectsAction:
	var action := ApplyEffectsAction.new()
	action.use_impact_area = use_impact_area
	return action

func _free_all(nodes: Array) -> void:
	for node in nodes:
		node.free()

func _test_burst_generic_numbers() -> void:
	section("Rajada instantânea: números nomeados vindos de atributos, sem nomes fixos")
	var caster := TestDummy.new()
	caster.stats = {"area_size": 3.0}
	var a := TestDummy.new()
	var b := TestDummy.new()
	var finder := TestFinder.new()
	finder.targets = [a, b]
	var shape := BurstShape.new()
	shape.name_prefix = "Explosão de"
	shape.area = TestFactory.area({"reach": 0.0, "size": TestFactory.stat(&"area_size", 2.0)}, [&"enemies"])
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var ctx := TestFactory.context(caster)
	ctx.finder = finder
	ctx.origin = Vector2(1, 2)
	ctx.direction = Vector2.RIGHT
	var result := SpellCaster.new().cast(spell, ctx)
	check(result == SpellCaster.Result.OK, "cast devolveu OK")
	check(is_equal_approx(a.hp, 90.0) and is_equal_approx(b.hp, 90.0), "os alvos devolvidos pelo finder levaram 10")
	check(is_equal_approx(caster.hp, 100.0), "conjurador não foi atingido")
	check(is_equal_approx(finder.last_area.get_number(&"size"), 6.0), "size = 3 * 2, vindo do atributo")
	check(is_equal_approx(finder.last_area.get_number(&"reach", 99.0), 0.0), "reach = 0 repassado sem interpretação")
	check(is_equal_approx(finder.last_area.get_number(&"nao_existe", 7.0), 7.0), "número ausente devolve o padrão")
	check(finder.last_area.has_label(&"enemies"), "rótulo repassado ao jogo")
	check(finder.last_area.origin == Vector2(1, 2), "origem = posição do conjurador")
	_free_all([caster, a, b])

func _test_burst_aim_point_anchor() -> void:
	section("Âncora no ponto mirado")
	var caster := TestDummy.new()
	var finder := TestFinder.new()
	var shape := BurstShape.new()
	shape.anchor = SpellShape.Anchor.AIM_POINT
	shape.area = TestFactory.area({"size": 2.0})
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var ctx := TestFactory.context(caster)
	ctx.finder = finder
	ctx.origin = Vector2(1, 2)
	ctx.aim_point = Vector2(9, 9)
	SpellCaster.new().cast(spell, ctx)
	check(finder.last_area.origin == Vector2(9, 9), "origem = ponto mirado")
	_free_all([caster])

func _test_burst_sustained() -> void:
	section("Rajada não instantânea usa o SustainedAreaRunner")
	var caster := TestDummy.new()
	var a := TestDummy.new()
	var finder := TestFinder.new()
	finder.targets = [a]
	var runner := TestSustainedRunner.new()
	var shape := BurstShape.new()
	shape.instant = false
	shape.area = TestFactory.area({"size": 2.0})
	shape.duration = TestFactory.constant(2.0)
	shape.tick_interval = TestFactory.constant(0.5)
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var ctx := TestFactory.context(caster)
	ctx.finder = finder
	ctx.sustained = runner
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(runner.last_request.duration, 2.0), "duração repassada ao runner")
	check(is_equal_approx(runner.last_request.tick_interval, 0.5), "intervalo repassado ao runner")
	check(is_equal_approx(a.hp, 70.0), "3 ticks de 10: 100 - 30 = 70")
	_free_all([caster, a])

func _test_part_area_overrides_shape_area() -> void:
	section("Parâmetros da parte sobrescrevem os da forma, por nome")
	var caster := TestDummy.new()
	var finder := TestFinder.new()
	var shape := BurstShape.new()
	shape.area = TestFactory.area({"reach": 5.0, "angle": 0.0}, [&"enemies"])
	var part := TestFactory.part(shape, [_fire()], TestFactory.area({"angle": 30.0}, [&"back_row"]))
	var definition := SpellDefinition.new()
	definition.parts.append(part)
	var spell := SpellBuilder.new().build(definition)
	check(spell.parts[0].area.numbers.size() == 2, "sem números duplicados: reach e angle")
	var ctx := TestFactory.context(caster)
	ctx.finder = finder
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(finder.last_area.get_number(&"reach"), 5.0), "reach herdado da forma")
	check(is_equal_approx(finder.last_area.get_number(&"angle"), 30.0), "angle sobrescrito pela parte")
	check(finder.last_area.has_label(&"enemies") and finder.last_area.has_label(&"back_row"), "rótulos somados")
	check(is_equal_approx(shape.area.numbers[1].value.get_value(null), 0.0), "a forma original não foi alterada")
	_free_all([caster])

func _test_projectile_default_actions() -> void:
	section("Projétil: ações padrão (aplicar efeitos e destruir)")
	var caster := TestDummy.new()
	caster.stats = {"range": 7.0}
	var a := TestDummy.new()
	var shape := ProjectileShape.new()
	shape.projectile_id = &"fireball"
	shape.area = TestFactory.area({"range": TestFactory.stat(&"range")})
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var launcher := TestLauncher.new()
	var impact := _impact(Vector2(5, 0), [a])
	launcher.impacts = [impact]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(a.hp, 90.0), "alvo atingido levou 10")
	check(impact.destroyed, "projétil foi destruído")
	check(is_equal_approx(launcher.last_request.area.get_number(&"range"), 7.0), "range veio do atributo e foi ao jogo")
	check(launcher.last_request.projectile_id == &"fireball", "projectile_id repassado ao jogo")
	check(launcher.last_request.collide_along_path, "colisão no trajeto ligada por padrão")
	_free_all([caster, a])

func _test_projectile_impact_area() -> void:
	section("Projétil: impact_area manda o finder buscar alvos no ponto de impacto")
	var caster := TestDummy.new()
	var hit_directly := TestDummy.new()
	var in_area := TestDummy.new()
	var finder := TestFinder.new()
	finder.targets = [in_area]
	var shape := ProjectileShape.new()
	shape.impact_area = TestFactory.area({"size": 2.0}, [&"enemies"])
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var launcher := TestLauncher.new()
	launcher.impacts = [_impact(Vector2(4, 4), [hit_directly])]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	ctx.finder = finder
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(in_area.hp, 90.0), "quem o finder devolveu levou dano")
	check(is_equal_approx(hit_directly.hp, 100.0), "com impact_area, vale a área e não os alvos diretos")
	check(finder.last_area.origin == Vector2(4, 4), "área centrada no ponto de impacto")
	check(is_equal_approx(finder.last_area.get_number(&"size"), 2.0), "parâmetros do impacto repassados")
	check(finder.last_area.has_label(&"enemies"), "rótulos do impacto repassados")
	_free_all([caster, hit_directly, in_area])

func _test_projectile_pierce_and_destroy() -> void:
	section("Projétil: atravessar versus destruir")
	var caster := TestDummy.new()
	var a := TestDummy.new()
	var b := TestDummy.new()

	var pierce := ProjectileShape.new()
	pierce.impact_actions.append(_apply(false))
	var launcher := TestLauncher.new()
	var first := _impact(Vector2(1, 0), [a])
	var second := _impact(Vector2(2, 0), [b])
	launcher.impacts = [first, second]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	SpellCaster.new().cast(SpellBuilder.new().build(TestFactory.definition(pierce, _fire())), ctx)
	check(is_equal_approx(a.hp, 90.0) and is_equal_approx(b.hp, 90.0), "sem DestroyAction: atravessa e acerta os dois")
	check(not first.destroyed and not second.destroyed, "nenhum impacto destruiu o projétil")

	var a2 := TestDummy.new()
	var b2 := TestDummy.new()
	var stop := ProjectileShape.new()
	stop.impact_actions.append(_apply(false))
	stop.impact_actions.append(DestroyAction.new())
	var launcher2 := TestLauncher.new()
	var first2 := _impact(Vector2(1, 0), [a2])
	var second2 := _impact(Vector2(2, 0), [b2])
	launcher2.impacts = [first2, second2]
	var ctx2 := TestFactory.context(caster)
	ctx2.launcher = launcher2
	SpellCaster.new().cast(SpellBuilder.new().build(TestFactory.definition(stop, _fire())), ctx2)
	check(is_equal_approx(a2.hp, 90.0) and is_equal_approx(b2.hp, 100.0), "com DestroyAction: só o primeiro é atingido")
	check(first2.destroyed, "primeiro impacto destruiu o projétil")
	_free_all([caster, a, b, a2, b2])

func _test_projectile_recast() -> void:
	section("Projétil: reconjurar ao acertar")
	var caster := TestDummy.new()
	var recast := RecastAction.new()
	recast.definition = TestFactory.definition(SelfShape.new(), _fire(4.0))
	var shape := ProjectileShape.new()
	shape.impact_actions.append(recast)
	var launcher := TestLauncher.new()
	var impact := _impact(Vector2(3, 3), [])
	launcher.impacts = [impact]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	SpellCaster.new().cast(SpellBuilder.new().build(TestFactory.definition(shape, _fire())), ctx)
	check(is_equal_approx(caster.hp, 96.0), "a magia reconjurada (SelfShape, 4) atingiu o conjurador")
	check(not impact.destroyed, "sem DestroyAction, o projétil continua")
	_free_all([caster])

func _test_recast_depth_guard() -> void:
	section("Reconjuração encadeada respeita max_depth")
	var caster := TestDummy.new()
	var shape := ProjectileShape.new()
	var definition := TestFactory.definition(shape, _fire())
	var recast := RecastAction.new()
	recast.definition = definition
	recast.max_depth = 3
	shape.impact_actions.append(recast)
	var launcher := TestLauncher.new()
	launcher.impacts = [_impact(Vector2(1, 1), [])]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	SpellCaster.new().cast(SpellBuilder.new().build(definition), ctx)
	check(launcher.launch_count == 4, "1 original + 3 reconjurações, depois para")
	_free_all([caster])

func _test_triple_shot() -> void:
	section("Tiro triplo: 3 partes, mesma forma, ângulos e elementos diferentes")
	var caster := TestDummy.new()
	caster.resources = {"mana": 20.0}
	var a := TestDummy.new()
	var shot := ProjectileShape.new()
	shot.name_prefix = "Tiro de"
	shot.projectile_id = &"tiro"
	shot.cost = TestFactory.cost({"mana": 3.0})
	shot.area = TestFactory.area({"range": 8.0, "angle": 0.0})
	var definition := SpellDefinition.new()
	var fire := TestFactory.element("fogo", TestFactory.constant(10.0))
	var ice := TestFactory.element("gelo", TestFactory.constant(5.0))
	var bolt := TestFactory.element("raio", TestFactory.constant(7.0))
	definition.parts.append(TestFactory.part(shot, [fire], TestFactory.area({"angle": 0.0})))
	definition.parts.append(TestFactory.part(shot, [ice], TestFactory.area({"angle": 30.0})))
	definition.parts.append(TestFactory.part(shot, [bolt], TestFactory.area({"angle": -30.0})))
	var spell := SpellBuilder.new().build(definition)
	check(spell.display_name == "Tiro de fogo e Tiro de gelo e Tiro de raio", "nome automático junta as 3 partes")
	check(is_equal_approx(spell.cost.amounts.get("mana", 0.0), 9.0), "custo = 3 partes * 3 de mana")

	var launcher := TestLauncher.new()
	launcher.impacts = [_impact(Vector2(1, 1), [a])]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	var result := SpellCaster.new().cast(spell, ctx)
	check(result == SpellCaster.Result.OK, "cast devolveu OK")
	check(is_equal_approx(caster.resources["mana"], 11.0), "custo cobrado uma vez só: 20 - 9 = 11")
	check(launcher.requests.size() == 3, "o jogo recebeu 3 pedidos de projétil")
	check(is_equal_approx(launcher.requests[0].area.get_number(&"angle"), 0.0), "projétil 1: angle 0")
	check(is_equal_approx(launcher.requests[1].area.get_number(&"angle"), 30.0), "projétil 2: angle 30")
	check(is_equal_approx(launcher.requests[2].area.get_number(&"angle"), -30.0), "projétil 3: angle -30")
	check(is_equal_approx(launcher.requests[2].area.get_number(&"range"), 8.0), "range herdado da forma nos 3")
	check(launcher.requests[1].part.elements[0].display_name == "gelo", "projétil 2 carrega o elemento gelo")
	check(is_equal_approx(a.hp, 78.0), "dano total = 10 + 5 + 7 = 22")
	_free_all([caster, a])
