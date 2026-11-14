class_name TestFactory
extends RefCounted
## Atalhos para montar peças nos testes.

static func cost(amounts: Dictionary) -> SpellCost:
	var result := SpellCost.new()
	result.amounts = amounts
	return result

static func constant(value: float) -> ConstantValue:
	var result := ConstantValue.new()
	result.value = value
	return result

static func stat(key: StringName, scale: float = 1.0) -> StatValue:
	var result := StatValue.new()
	result.stat_key = key
	result.scale = scale
	return result

static func shape(prefix: String, costs: Dictionary = {}, multiplier: float = 1.0) -> TestRecordingShape:
	var result := TestRecordingShape.new()
	result.name_prefix = prefix
	result.power_multiplier = multiplier
	result.cost = cost(costs)
	return result

static func element(element_name: String, power: ValueSource, costs: Dictionary = {}, tag: StringName = &"") -> SpellElement:
	var result := SpellElement.new()
	result.display_name = element_name
	result.power = power
	result.cost = cost(costs)
	result.effects.append(DamageEffect.new())
	if tag != &"":
		result.tags.append(tag)
	return result

static func definition(spell_shape: SpellShape, spell_element: SpellElement) -> SpellDefinition:
	var result := SpellDefinition.new()
	result.shape = spell_shape
	result.elements.append(spell_element)
	return result

static func context(dummy: TestDummy) -> SpellContext:
	var result := SpellContext.new()
	result.caster = dummy
	result.stats = TestStats.new(dummy.stats)
	result.payer = TestPayer.new(dummy)
	return result
