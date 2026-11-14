class_name SpellContext
extends RefCounted
## Dados de uma conjuração em andamento. Quem conjura preenche o que o jogo tiver.
## Todos os campos são opcionais, e cada peça do sistema só usa o que precisa.

## Quem está conjurando (Node, Resource, objeto de dados...).
var caster: Object
## Atributos do conjurador (para ValueSource e requisitos).
var stats: StatProvider
## Tags do conjurador (equipamentos, estados) para requisitos.
var tags: TagProvider
## Verifica e cobra custos.
var payer: CostPayer
## Encontra alvos a partir de uma área.
var finder: TargetFinder
## Realiza projéteis.
var launcher: ProjectileLauncher
## Repete áreas ao longo do tempo.
var sustained: SustainedAreaRunner
## Posição de origem. Vector2, Vector3, célula de grade, slot de carta...
var origin: Variant
## Direção da mira, se o seu jogo tiver essa ideia.
var direction: Variant
## Ponto ou alvo mirado, usado por formas com âncora AIM_POINT.
var aim_point: Variant
## Magia em execução. Preenchida pelo SpellCaster.
var spell: SpellInstance
## Parte em execução. Preenchida pelo SpellCaster antes de disparar cada forma.
var part: SpellPartInstance
## Quantas reconjurações encadeadas já aconteceram (proteção contra laço infinito).
var depth: int = 0

## Cria um contexto filho para reconjurar a partir de outro ponto.
## Não copia o payer: reconjurações não cobram custo.
func derive(new_origin: Variant, new_direction: Variant = null) -> SpellContext:
	var child := SpellContext.new()
	child.caster = caster
	child.stats = stats
	child.tags = tags
	child.finder = finder
	child.launcher = launcher
	child.sustained = sustained
	child.origin = new_origin
	child.aim_point = new_origin
	child.direction = direction if new_direction == null else new_direction
	child.depth = depth + 1
	return child
