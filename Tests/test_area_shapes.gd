extends TestCase
## Testa SpellArea, BurstShape, ProjectileShape, ações de impacto e reconjuração.

func _ready() -> void:
	print("=== Magic_System.G: testes de área, rajada e projétil ===")
	_test_burst_instant()
	_test_burst_aim_point_anchor()
	_test_burst_sustained()
	_test_projectile_default_actions()
	_test_projectile_area_at_impact()
	_test_projectile_pierce_and_destroy()
	_test_projectile_recast()
	_test_recast_depth_guard()
	finish()

func _area(distance: ValueSource, radius: ValueSource) -> SpellArea:
	var result := SpellArea.new()
	result.distance = distance
	result.radius = radius
	return result

func _fire(power: float = 10.0) -> SpellElement:
	return TestFactory.element("fogo", TestFactory.constant(power))

func _impact(point: Vector2, targets: Array) -> ProjectileImpact:
	var result := ProjectileImpact.new()
	result.point = point
	result.targets = targets
	return result

func _apply(affect_area: bool) -> ApplyEffectsAction:
	var action := ApplyEffectsAction.new()
	action.affect_area = affect_area
	return action

func _free_all(nodes: Array) -> void:
	for node in nodes:
		node.free()

func _test_burst_instant() -> void:
	section("Rajada instantânea com área vinda de atributos")
	var caster := TestDummy.new()
	caster.stats = {"area_size": 3.0}
	var a := TestDummy.new()
	var b := TestDummy.new()
	var finder := TestFinder.new()
	finder.targets = [a, b]
	var shape := BurstShape.new()
	shape.name_prefix = "Explosão de"
	shape.area = _area(null, TestFactory.stat(&"area_size", 2.0))
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var ctx := TestFactory.context(caster)
	ctx.finder = finder
	ctx.origin = Vector2(1, 2)
	ctx.direction = Vector2.RIGHT
	var result := SpellCaster.new().cast(spell, ctx)
	check(result == SpellCaster.Result.OK, "cast devolveu OK")
	check(is_equal_approx(a.hp, 90.0) and is_equal_approx(b.hp, 90.0), "os dois alvos da área levaram 10")
	check(is_equal_approx(caster.hp, 100.0), "conjurador não foi atingido")
	check(is_equal_approx(finder.last_area.radius, 6.0), "raio = 3 * 2, vindo do atributo")
	check(is_equal_approx(finder.last_area.distance, 0.0), "distância 0 = onde foi conjurado")
	check(finder.last_area.origin == Vector2(1, 2), "origem = posição do conjurador")
	_free_all([caster, a, b])

func _test_burst_aim_point_anchor() -> void:
	section("Âncora no ponto mirado")
	var caster := TestDummy.new()
	var finder := TestFinder.new()
	var shape := BurstShape.new()
	shape.anchor = SpellShape.Anchor.AIM_POINT
	shape.area = _area(null, TestFactory.constant(2.0))
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
	shape.area = _area(null, TestFactory.constant(2.0))
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

func _test_projectile_default_actions() -> void:
	section("Projétil: ações padrão (aplicar efeitos e destruir)")
	var caster := TestDummy.new()
	caster.stats = {"range": 7.0}
	var a := TestDummy.new()
	var shape := ProjectileShape.new()
	shape.projectile_id = &"fireball"
	shape.area = _area(TestFactory.stat(&"range"), null)
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var launcher := TestLauncher.new()
	var impact := _impact(Vector2(5, 0), [a])
	launcher.impacts = [impact]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(a.hp, 90.0), "alvo atingido levou 10")
	check(impact.destroyed, "projétil foi destruído")
	check(is_equal_approx(launcher.last_request.area.distance, 7.0), "alcance veio do atributo")
	check(launcher.last_request.projectile_id == &"fireball", "projectile_id repassado ao jogo")
	check(launcher.last_request.collide_along_path, "colisão no trajeto ligada por padrão")
	_free_all([caster, a])

func _test_projectile_area_at_impact() -> void:
	section("Projétil: raio de efeito centrado no impacto")
	var caster := TestDummy.new()
	var hit_directly := TestDummy.new()
	var in_radius := TestDummy.new()
	var finder := TestFinder.new()
	finder.targets = [in_radius]
	var shape := ProjectileShape.new()
	shape.area = _area(TestFactory.constant(10.0), TestFactory.constant(2.0))
	var spell := SpellBuilder.new().build(TestFactory.definition(shape, _fire()))
	var launcher := TestLauncher.new()
	launcher.impacts = [_impact(Vector2(4, 4), [hit_directly])]
	var ctx := TestFactory.context(caster)
	ctx.launcher = launcher
	ctx.finder = finder
	SpellCaster.new().cast(spell, ctx)
	check(is_equal_approx(in_radius.hp, 90.0), "quem estava no raio levou dano")
	check(is_equal_approx(hit_directly.hp, 100.0), "com raio, vale a área e não os alvos diretos")
	check(finder.last_area.origin == Vector2(4, 4), "área centrada no ponto de impacto")
	check(is_equal_approx(finder.last_area.distance, 0.0), "distância 0 no impacto")
	check(is_equal_approx(finder.last_area.radius, 2.0), "raio 2 mantido")
	_free_all([caster, hit_directly, in_radius])

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
	var recast_definition := TestFactory.definition(SelfShape.new(), _fire(4.0))
	var recast := RecastAction.new()
	recast.definition = recast_definition
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
