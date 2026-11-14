# Magic_System.G

Sistema de magia dinâmica para Godot 4 (GDScript), feito com composição de Resources e princípios SOLID.

Uma magia é montada em tempo de execução a partir de **forma** (COMO a magia é entregue: projétil, rajada, em si mesmo...) e **elemento** (O QUE ela faz: efeitos, tags, números, custos). Custo, requisitos, poder, área e nome são calculados automaticamente.

O sistema é **lógica pura**. Ele decide o que a magia é e o que ela faz, e pede ao seu jogo (por contratos pequenos) para realizar o que depende do mundo: achar alvos, mover projéteis, ler atributos, cobrar recursos. Por isso o mesmo código serve para RPG por turnos, RPG tático, action RPG 2D e 3D e jogos de cartas.

> **Premissas deste manual**
> - Godot 4.x e GDScript.
> - GDScript não tem interfaces, então os "contratos" são classes base com métodos vazios que você sobrescreve.
> - Alvos e conjuradores são `Object` (Node, Resource, objeto de dados...). Efeitos usam "duck typing": o `DamageEffect` chama `take_damage(valor)` se o alvo tiver esse método.
> - Custos (`SpellCost`) são números fixos por chave. Área, alcance, raio, duração e poder são dinâmicos (`ValueSource`). Custos dinâmicos ficam como evolução futura.
> - Chaves de custo, atributo e tag são textos simples (`"mana"`, `"magic_power"`, `"equip:staff"`). Use sempre o mesmo texto em todos os lugares.
> - Nada é obrigatório: você implementa só os contratos das peças que usar, e pode apagar as pastas que não quiser (seção 6).
> - Os exemplos de projétil e de busca de alvos em 2D são ilustrativos, para você adaptar ao seu jogo.

## Sumário

1. [Conceitos](#1-conceitos)
2. [Instalação](#2-instalação)
3. [Estrutura de pastas](#3-estrutura-de-pastas)
4. [A especificação no código](#4-a-especificação-no-código)
5. [Referência dos arquivos](#5-referência-dos-arquivos)
6. [Regras de dependência e o que pode ser apagado](#6-regras-de-dependência-e-o-que-pode-ser-apagado)
7. [Como usar](#7-como-usar)
8. [Custos e requisitos](#8-custos-e-requisitos)
9. [Áreas](#9-áreas)
10. [Projétil e rajada](#10-projétil-e-rajada)
11. [Usando em cada tipo de jogo](#11-usando-em-cada-tipo-de-jogo)
12. [Fluxos](#12-fluxos)
13. [Como estender](#13-como-estender)
14. [Extensão opcional: variações de forma](#14-extensão-opcional-variações-de-forma)
15. [Testes](#15-testes)
16. [Cuidados e erros comuns](#16-cuidados-e-erros-comuns)
17. [SOLID no projeto](#17-solid-no-projeto)

---

## 1. Conceitos

| Termo | O que é |
|---|---|
| **Forma** (`SpellShape`) | Define COMO a magia chega aos alvos. Tem custo, tags, requisitos, efeitos próprios, multiplicador de poder, âncora (onde nasce) e prefixo de nome (`"Bola de"`). |
| **Elemento** (`SpellElement`) | Define O QUE a magia faz: número bruto, efeitos, tags, custo, requisitos e nome (`"fogo"`). |
| **Custo** (`SpellCost`) | Dicionário genérico de recursos e quantidades (`mana`, `hp`, `item:pocao`...). Custos de magia, forma e elementos são somados. |
| **Requisito** (`SpellRequirement`) | Condição para conjurar (equipamento, estado, nível...). Requisitos de magia, forma e elementos são somados. |
| **ValueSource** | De onde vem um número: constante, atributo do conjurador, poder da magia, ou uma conta entre valores. |
| **Área** (`SpellArea`) | Distância, raio e desvio de ângulo, cada um um `ValueSource`. Vira uma `ResolvedArea` na hora de conjurar. |
| **Efeito** (`SpellEffect`) | Algo que acontece com um alvo (dano, cura, status...). |
| **Ação de impacto** (`ImpactAction`) | O que um projétil faz ao acertar: aplicar efeitos, reconjurar, destruir. |
| **Definição** (`SpellDefinition`) | A receita editável de uma magia. |
| **Instância** (`SpellInstance`) | A magia pronta, com nome, forma resolvida, custo e requisitos totais. |
| **Construtor** (`SpellBuilder`) | Transforma uma definição em uma instância. |
| **Conjurador** (`SpellCaster`) | Verifica requisitos e custo, cobra e dispara a forma. |
| **Contexto** (`SpellContext`) | Os dados de uma conjuração: quem conjura, atributos, tags, origem, direção, ponto mirado e as pontes com o jogo. |
| **Contratos** | `StatProvider`, `TagProvider`, `CostPayer`, `TargetFinder`, `ProjectileLauncher`, `SustainedAreaRunner`: as pontes que o SEU jogo implementa. |

---

## 2. Instalação

Passo 1. Pelo gerenciador de arquivos do seu sistema, copie a pasta `Magic_System.G` inteira para dentro da pasta do seu projeto Godot, no mesmo nível do arquivo `project.godot`. O Godot pode ficar aberto.

Passo 2. Se você já tinha uma versão anterior destas classes em outra pasta do projeto, apague essa pasta antiga pelo painel FileSystem (clique direito, Delete) ANTES de voltar ao editor. Duas pastas com a mesma `class_name` causam o erro de classe global repetida.

Passo 3. Volte ao Godot e espere a barra de progresso de importação terminar. O painel FileSystem passa a mostrar `res://Magic_System.G/`.

Passo 4. Abra o painel Output (parte de baixo da janela) e confirme que não há erros vermelhos. Os scripts usam `class_name`, então todas as classes ficam disponíveis globalmente, sem `preload`.

Passo 5. Implemente no SEU jogo os contratos que você for usar (seção 7, passo 1). Esses arquivos ficam fora desta pasta, porque dependem do seu jogo.

> Os testes apontam para `res://Magic_System.G/Tests/...`. Se você renomear ou mover a pasta, só as cenas `.tscn` de teste precisam ser reanexadas (seção 15).

---

## 3. Estrutura de pastas

```
Magic_System.G/
├── README.md
├── scripts/                          Código real do sistema
│   ├── core/                         Peças fundamentais de uma magia
│   │   ├── components/               Forma, elemento, efeito, instância
│   │   ├── area/                     Área descrita e área calculada
│   │   ├── requirements/             Base de requisitos
│   │   ├── cost/                     Custos
│   │   ├── values/                   Números (ValueSource)
│   │   └── contracts/                Pontes com o jogo
│   │       └── requests/             Pedidos e resultados trocados com o jogo
│   ├── building/                     Construção: receita, construtor, nomeador
│   ├── casting/                      Execução: verificar, cobrar, disparar
│   ├── library/                      Peças prontas de uso (substituíveis)
│   │   ├── shapes/                   Self, Burst (rajada), Projectile (projétil)
│   │   ├── impact/                   Ações de impacto do projétil
│   │   ├── requirements/             Requisitos prontos
│   │   └── effects/                  Efeitos prontos
│   └── extensions/                   Recursos OPCIONAIS, removíveis
│       └── shape_variants/           Grupos de formas (Estaca de / Bola de)
└── Tests/                            Código descartável, só para testar na prática
    ├── support/                      Dublês e atalhos de teste
    ├── extensions/                   Testes das extensões opcionais
    └── test_*.gd / .tscn             Testes do núcleo, requisitos e áreas
```

Em uma frase por pasta:

- **core**: o que uma magia É. Não conhece construtores, execução, biblioteca nem extensões.
- **building**: como uma magia é MONTADA a partir de uma receita.
- **casting**: como uma magia pronta é DISPARADA.
- **library**: formas, ações, requisitos e efeitos concretos prontos. Servem de uso e de exemplo, e podem ser trocados ou apagados.
- **extensions**: funcionalidades extras. Apagar uma pasta daqui não quebra nada no resto.
- **Tests**: nada em `scripts` depende desta pasta. Pode ser apagada inteira.

---

## 4. A especificação no código

| Na especificação | Onde está |
|---|---|
| **Nome da magia** | `SpellDefinition.custom_name`. Se vazio, `SpellNamer` junta `SpellShape.name_prefix` + `SpellElement.display_name`. |
| **Custo** (mágico, hp, item...) | `SpellCost` na magia, na forma e no elemento, somados pelo `SpellBuilder`. As chaves são livres: `mana`, `hp`, `item:pocao`. O `CostPayer` do jogo decide o que cada chave significa. |
| **Requisitos** (equipamentos, estados...) | `SpellRequirement` na magia, na forma e no elemento. Prontos: `TagRequirement` (equipamento ou estado, via `TagProvider`) e `StatAtLeastRequirement` (atributo mínimo). |
| **Composição** | `SpellDefinition`: `shape` + `elements`. |
| **Forma**: tipo | Subclasses de `SpellShape`: `ProjectileShape`, `BurstShape`, `SelfShape`. |
| **Forma**: onde é conjurado | `SpellShape.anchor`: `CASTER` (no usuário, padrão) ou `AIM_POINT` (no ponto mirado). |
| **Forma**: efeito | `SpellShape.effects`, somados aos efeitos dos elementos. |
| **Área**: distância (0 = onde conjurado) | `SpellArea.distance` (um `ValueSource`). |
| **Área**: raio de efeito | `SpellArea.radius` (um `ValueSource`). |
| **Área**: direção (lado ou ângulo) | Direção base em `SpellContext.direction` (ex.: ângulo do mouse) mais `SpellArea.angle_offset`. |
| **Projétil**: colisão do início ao fim | `ProjectileShape.collide_along_path`. |
| **Projétil**: efeito ao acertar | `ProjectileShape.impact_actions`: `ApplyEffectsAction`, `RecastAction`, `DestroyAction`. |
| **Projétil**: área | `ProjectileShape.area`. |
| **Rajada**: instantânea ou não | `BurstShape.instant` (mais `duration` e `tick_interval` quando não instantânea). |
| **Rajada**: área | `BurstShape.area`. |
| **Nada travado** | Todo número de área, duração, poder e atributo é `ValueSource`: constante, atributo do conjurador, poder da magia (`SpellPowerValue`) ou conta (`ProductValue`). |

---

## 5. Referência dos arquivos

### scripts/core/components

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_component.gd` | `SpellComponent` | Base de forma e elemento: `cost`, `tags`, `requirements`. |
| `spell_shape.gd` | `SpellShape` | Base de formas: `name_prefix`, `power_multiplier`, `anchor`, `effects`, `resolve(elements)`, `cast(spell, ctx)`, `get_origin(ctx)`. |
| `spell_element.gd` | `SpellElement` | Elemento: `display_name`, `power` (um `ValueSource`), `effects`. |
| `spell_effect.gd` | `SpellEffect` | Base de efeitos: `apply(target, power, ctx)`. |
| `spell_instance.gd` | `SpellInstance` | Magia pronta. Calcula poder, aplica efeitos, acha requisito não cumprido. |

### scripts/core/area

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_area.gd` | `SpellArea` | Descrição da área: `distance`, `radius`, `angle_offset`. `resolve(ctx, origin)` devolve uma `ResolvedArea`. |
| `resolved_area.gd` | `ResolvedArea` | Área calculada: `origin`, `direction`, `distance`, `radius`, `angle_offset`. `moved_to(ponto)` copia centrando em outro ponto. |

### scripts/core/requirements

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_requirement.gd` | `SpellRequirement` | Base: `is_met(ctx)` e `failure_message` para mostrar ao jogador. |

### scripts/core/cost

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_cost.gd` | `SpellCost` | Dicionário `amounts` e `merged_with(outro)`, que soma sem alterar os originais. |

### scripts/core/values

| Arquivo | Classe | Resumo |
|---|---|---|
| `value_source.gd` | `ValueSource` | Base: `get_value(ctx)`. Tem também o atalho estático `ValueSource.read(fonte, ctx, padrão)`, seguro para fonte nula. |
| `constant_value.gd` | `ConstantValue` | Número fixo. |
| `stat_value.gd` | `StatValue` | Atributo do conjurador (via `StatProvider`) vezes uma escala, com `fallback`. |
| `product_value.gd` | `ProductValue` | Multiplica dois `ValueSource`. |
| `spell_power_value.gd` | `SpellPowerValue` | Poder final da magia em execução vezes uma escala (ex.: raio que cresce com o poder). Não usar dentro de `element.power`. |

### scripts/core/contracts

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_context.gd` | `SpellContext` | Dados da conjuração e as pontes com o jogo. `derive(ponto)` cria um contexto filho para reconjurar. |
| `stat_provider.gd` | `StatProvider` | Contrato: `get_stat(chave, padrão)`. |
| `tag_provider.gd` | `TagProvider` | Contrato: `has_tag(tag)`. Equipamentos e estados viram tags. |
| `cost_payer.gd` | `CostPayer` | Contrato: `can_pay(custo)` e `pay(custo)`. |
| `target_finder.gd` | `TargetFinder` | Contrato: `find_targets(area, ctx)` devolve quem está na área. |
| `projectile_launcher.gd` | `ProjectileLauncher` | Contrato: `launch(request)` realiza o projétil e avisa cada impacto. |
| `sustained_area_runner.gd` | `SustainedAreaRunner` | Contrato: `start(request)` repete a área ao longo do tempo. |
| `requests/projectile_request.gd` | `ProjectileRequest` | Pedido ao launcher: magia, contexto, área, `projectile_id`, `collide_along_path`, `on_impact`. |
| `requests/projectile_impact.gd` | `ProjectileImpact` | Um impacto: `point`, `targets`, `is_end`, `destroyed`. |
| `requests/sustained_request.gd` | `SustainedRequest` | Pedido ao runner: magia, contexto, área, `duration`, `tick_interval`, `on_tick`. |

### scripts/building

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_definition.gd` | `SpellDefinition` | Receita: `custom_name`, `shape`, `elements`, `cost`, `requirements`. |
| `spell_builder.gd` | `SpellBuilder` | `build(definition)` resolve a forma, soma custos e requisitos, gera o nome e devolve um `SpellInstance`. Aceita um `SpellNamer` próprio. |
| `spell_namer.gd` | `SpellNamer` | Nome: `custom_name` se existir, senão `prefixo da forma + nomes dos elementos`. |

### scripts/casting

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_caster.gd` | `SpellCaster` | `can_cast` (só verifica), `cast` (verifica, cobra e dispara), `fire` (dispara sem verificar nem cobrar). Devolve `SpellCaster.Result`. |

### scripts/library

| Arquivo | Classe | Resumo |
|---|---|---|
| `shapes/self_shape.gd` | `SelfShape` | Aplica a magia no próprio conjurador. |
| `shapes/burst_shape.gd` | `BurstShape` | Rajada ou explosão em uma área, instantânea ou ao longo do tempo. |
| `shapes/projectile_shape.gd` | `ProjectileShape` | Projétil realizado pelo `ProjectileLauncher` do jogo. |
| `impact/impact_action.gd` | `ImpactAction` | Base das ações de impacto. |
| `impact/apply_effects_action.gd` | `ApplyEffectsAction` | Aplica os efeitos nos alvos diretos ou na área do impacto. |
| `impact/recast_action.gd` | `RecastAction` | Conjura outra magia no ponto de impacto, de graça, com limite de profundidade. |
| `impact/destroy_action.gd` | `DestroyAction` | Marca o projétil como destruído. |
| `requirements/tag_requirement.gd` | `TagRequirement` | Exige ter (ou não ter) uma tag. |
| `requirements/stat_at_least_requirement.gd` | `StatAtLeastRequirement` | Exige um atributo mínimo. |
| `effects/damage_effect.gd` | `DamageEffect` | Chama `take_damage(poder * multiplicador)` no alvo. |

### scripts/extensions/shape_variants (OPCIONAL)

| Arquivo | Classe | Resumo |
|---|---|---|
| `shape_group.gd` | `ShapeGroup` | Forma que escolhe outra forma conforme condições. Pode conter outros grupos. |
| `shape_variant.gd` | `ShapeVariant` | Par condição + forma. |
| `spell_condition.gd` | `SpellCondition` | Base de condições: `is_met(elements)`. |
| `element_tag_condition.gd` | `ElementTagCondition` | Verdadeira se algum elemento tiver a tag. |

### Tests

| Arquivo | Resumo |
|---|---|
| `support/test_case.gd` | Base dos testes: `section`, `check`, `finish`. |
| `support/test_factory.gd` | Atalhos para montar custos, formas, elementos, definições e contexto. |
| `support/test_dummy.gd` | Personagem falso com `hp`, `stats`, `resources`, `take_damage`. |
| `support/test_stats.gd`, `test_payer.gd`, `test_tags.gd` | Implementações de teste de `StatProvider`, `CostPayer`, `TagProvider`. |
| `support/test_finder.gd`, `test_launcher.gd`, `test_sustained_runner.gd` | Implementações de teste de `TargetFinder`, `ProjectileLauncher`, `SustainedAreaRunner`. |
| `support/test_recording_shape.gd` | Forma de teste que conta conjurações. |
| `test_core_spell.gd` e `.tscn` | Custo somado, nomes, poder, conjuração, falta de recursos, `SelfShape`. |
| `test_requirements.gd` e `.tscn` | Requisitos de tag e atributo, soma de requisitos e bloqueio da conjuração. |
| `test_area_shapes.gd` e `.tscn` | Áreas vindas de atributos, âncora, rajada instantânea e sustentada, projétil, ações de impacto, reconjuração. |
| `extensions/test_shape_variants.gd` e `.tscn` | Grupo de formas. Apague junto com a extensão. |

---

## 6. Regras de dependência e o que pode ser apagado

A seta significa "conhece":

```
core        ──► ninguém (só ele mesmo)
building    ──► core
casting     ──► core
library     ──► core, building, casting   (o RecastAction usa o construtor e o conjurador)
extensions  ──► core
Tests       ──► tudo   (e NADA conhece Tests)
```

O que você pode apagar sem quebrar o resto, desde que nenhum `.tres` seu use uma classe apagada:

| Pasta ou arquivo | Consequência de apagar |
|---|---|
| `Tests/` | Nada. |
| `extensions/shape_variants/` | Some a variação de forma. O núcleo só mantém o método genérico `SpellShape.resolve`, que devolve a própria forma. |
| `library/impact/` | Some o efeito ao acertar. Apague junto o uso em `ProjectileShape` (ela usa `ApplyEffectsAction` e `DestroyAction` como padrão). |
| `library/shapes/burst_shape.gd` ou `projectile_shape.gd` | Some aquela forma. Nada mais depende delas, só o `RecastAction` precisa de uma forma para reconjurar. |
| `library/requirements/` | Somem os requisitos prontos. O núcleo continua aceitando requisitos próprios seus. |
| `core/area/` | NÃO apague se for usar `BurstShape` ou `ProjectileShape`. Para jogos sem área (cartas simples), pode apagar junto com essas duas formas. |

---

## 7. Como usar

### Passo 1. Escolher e implementar só os contratos que você vai usar

| Contrato | Quem usa | Se não implementar |
|---|---|---|
| `StatProvider` | `StatValue`, `StatAtLeastRequirement` | `StatValue` devolve o `fallback`, o requisito falha. |
| `TagProvider` | `TagRequirement` | "Ter tag" falha, "não ter tag" passa. |
| `CostPayer` | `SpellCaster` | Nada é cobrado, nenhum custo é verificado. |
| `TargetFinder` | `BurstShape`, `ApplyEffectsAction` com raio | Rajadas não acertam ninguém. |
| `ProjectileLauncher` | `ProjectileShape` | O projétil não acontece (aviso no Output). |
| `SustainedAreaRunner` | `BurstShape` com `instant` desligado | Cai para uma execução instantânea (aviso no Output). |

Crie os arquivos na pasta do SEU jogo (por exemplo `res://game/magic/`), nunca dentro de `Magic_System.G`.

`player_stats.gd`:

```gdscript
class_name PlayerStats
extends StatProvider

var player: Node

func _init(p: Node) -> void:
	player = p

func get_stat(key: StringName, default_value: float = 0.0) -> float:
	return player.stats.get(String(key), default_value)
```

`player_payer.gd`:

```gdscript
class_name PlayerPayer
extends CostPayer

var player: Node

func _init(p: Node) -> void:
	player = p

func can_pay(cost: SpellCost) -> bool:
	for key in cost.amounts:
		if player.resources.get(key, 0.0) < cost.amounts[key]:
			return false
	return true

func pay(cost: SpellCost) -> void:
	for key in cost.amounts:
		player.resources[key] -= cost.amounts[key]
```

`player_tags.gd` (equipamentos e estados como tags):

```gdscript
class_name PlayerTags
extends TagProvider

var player: Node

func _init(p: Node) -> void:
	player = p

func has_tag(tag: StringName) -> bool:
	return player.tags.has(String(tag))
```

Aqui `player.stats`, `player.resources` e `player.tags` são dados do SEU personagem. Troque pelo que o seu jogo tiver. Os contratos de área, projétil e tempo estão na seção 11.

### Passo 2. Criar as peças no editor

No painel FileSystem, clique com o botão direito na pasta onde quer guardar, escolha Create New, depois Resource. Na janela, digite o nome da classe (por exemplo `SpellElement`) e confirme. Salve com um nome claro (`fogo.tres`). Selecione o arquivo e preencha no Inspector.

**Elemento `fogo.tres`** (`SpellElement`): em `Display Name` escreva `fogo`. Em `Tags` adicione `fire`. Em `Power` escolha `StatValue` e em `Stat Key` escreva `magic_power`. Em `Effects` clique em Add Element e escolha `DamageEffect`. Em `Cost` crie um `SpellCost` e, em `Amounts`, adicione a chave `mana` com valor `2` e a chave `hp` com valor `2`.

**Forma `bola.tres`** (`ProjectileShape`): em `Name Prefix` escreva `Bola de`. Em `Projectile Id` escreva `fireball`. Deixe `Collide Along Path` ligado. Em `Area` crie um `SpellArea`; dentro dele, em `Distance` escolha `ConstantValue` com valor `400` e deixe `Radius` vazio. Deixe `Impact Actions` vazio (o padrão é aplicar os efeitos e destruir). Em `Cost` crie um `SpellCost` com `mana` = `5`. Em `Requirements`, se quiser exigir um cajado, adicione um `TagRequirement` com `Tag` = `equip:staff`.

**Forma `explosao.tres`** (`BurstShape`): em `Name Prefix` escreva `Explosão de`. Em `Anchor` escolha `AIM_POINT`. Deixe `Instant` ligado. Em `Area`, deixe `Distance` vazio (0 = onde foi conjurado) e em `Radius` escolha `StatValue` com `Stat Key` = `area_size`.

**Receita `bola_de_fogo.tres`** (`SpellDefinition`): em `Shape` arraste `bola.tres` e em `Elements` adicione `fogo.tres`. Deixe `Custom Name` vazio para o nome automático. O resultado é "Bola de fogo", custo mana 7 e hp 2.

### Passo 3. Montar a magia

```gdscript
var spell := SpellBuilder.new().build(bola_de_fogo)
print(spell.display_name)   # "Bola de fogo"
print(spell.cost.amounts)   # {"mana": 7, "hp": 2}
```

**Entrada:** `SpellDefinition`. **Saída:** `SpellInstance`, ou `null` se a definição não tiver forma ou nenhuma forma for resolvida (um erro aparece no Output). Monte uma vez e reaproveite.

### Passo 4. Preencher o contexto

No script do conjurador (por exemplo, o jogador):

```gdscript
var ctx := SpellContext.new()
ctx.caster = self
ctx.stats = PlayerStats.new(self)
ctx.tags = PlayerTags.new(self)
ctx.payer = PlayerPayer.new(self)
ctx.finder = my_target_finder
ctx.launcher = my_projectile_launcher
ctx.origin = global_position
ctx.direction = (get_global_mouse_position() - global_position).normalized()
ctx.aim_point = get_global_mouse_position()
```

Preencha só o que o seu jogo e as suas magias usam.

### Passo 5. Conjurar

```gdscript
var caster := SpellCaster.new()

if caster.can_cast(spell, ctx) == SpellCaster.Result.OK:   # só verifica, não cobra
	pass

var result := caster.cast(spell, ctx)
match result:
	SpellCaster.Result.OK:
		pass
	SpellCaster.Result.REQUIREMENT_NOT_MET:
		print(spell.find_unmet_requirement(ctx).failure_message)
	SpellCaster.Result.CANNOT_PAY:
		print("Recursos insuficientes")
```

**Entrada:** `SpellInstance` e `SpellContext`. **Saída:** `SpellCaster.Result`: `OK`, `NO_SHAPE`, `REQUIREMENT_NOT_MET` ou `CANNOT_PAY`. Em qualquer resultado diferente de `OK`, nada é cobrado e nada é disparado.

### Resumo de entradas e saídas

| Chamada | Entrada | Saída |
|---|---|---|
| `SpellBuilder.new(namer?)` | `SpellNamer` opcional | construtor |
| `SpellBuilder.build(def)` | `SpellDefinition` | `SpellInstance` ou `null` |
| `SpellCaster.can_cast(spell, ctx)` | `SpellInstance`, `SpellContext` | `Result` (nada muda) |
| `SpellCaster.cast(spell, ctx)` | `SpellInstance`, `SpellContext` | `Result` |
| `SpellCaster.fire(spell, ctx)` | `SpellInstance`, `SpellContext` | nada (dispara sem verificar nem cobrar) |
| `SpellInstance.compute_power(ctx)` | `SpellContext` | `float` |
| `SpellInstance.apply_to(ctx, alvo)` | `SpellContext`, `Object` | nada (efeitos agem no alvo) |
| `SpellInstance.find_unmet_requirement(ctx)` | `SpellContext` | `SpellRequirement` ou `null` |
| `SpellCost.merged_with(outro)` | `SpellCost` ou `null` | novo `SpellCost` |
| `ValueSource.get_value(ctx)` | `SpellContext` | `float` |
| `ValueSource.read(fonte, ctx, padrão)` | fonte ou `null` | `float` |
| `SpellArea.resolve(ctx, origem)` | `SpellContext`, `Variant` | `ResolvedArea` |
| `SpellShape.resolve(elements)` | `Array[SpellElement]` | `SpellShape` (ou `null` em grupos sem saída) |
| `SpellShape.cast(spell, ctx)` | `SpellInstance`, `SpellContext` | nada |
| `SpellEffect.apply(alvo, poder, ctx)` | `Object`, `float`, `SpellContext` | nada |
| `SpellRequirement.is_met(ctx)` | `SpellContext` | `bool` |
| `StatProvider.get_stat(chave, padrão)` | `StringName`, `float` | `float` |
| `TagProvider.has_tag(tag)` | `StringName` | `bool` |
| `CostPayer.can_pay(custo)` / `pay(custo)` | `SpellCost` | `bool` / nada |
| `TargetFinder.find_targets(area, ctx)` | `ResolvedArea`, `SpellContext` | `Array` de alvos |
| `ProjectileLauncher.launch(request)` | `ProjectileRequest` | nada (chama `request.on_impact`) |
| `SustainedAreaRunner.start(request)` | `SustainedRequest` | nada (chama `request.on_tick`) |

---

## 8. Custos e requisitos

**Custos.** Magia, forma e elementos podem ter custo. O `SpellBuilder` soma chave por chave: forma `mana 5` + elemento `mana 2, hp 2` = `mana 7, hp 2`. Itens também são custos: use uma chave como `item:pocao` com valor `1` e deixe o seu `CostPayer` consumir o item do inventário. O sistema nunca sabe o que "mana", "hp" ou "item:pocao" significam.

**Requisitos.** Magia, forma e elementos também podem ter requisitos, somados da mesma forma. Todos precisam estar cumpridos. Equipamentos e estados entram como tags: o seu `TagProvider` responde `true` para `equip:staff` quando o cajado está equipado, e para `state:silenced` quando o personagem está silenciado. Exemplos:

| Quero exigir | Requisito |
|---|---|
| Cajado equipado | `TagRequirement`, `tag` = `equip:staff`, `must_have` ligado |
| Não estar silenciado | `TagRequirement`, `tag` = `state:silenced`, `must_have` desligado |
| Nível 5 ou mais | `StatAtLeastRequirement`, `stat_key` = `level`, `minimum` = `5` |

Cada requisito tem `failure_message`, útil para mostrar ao jogador por que a magia não saiu. A ordem de verificação do `SpellCaster` é: forma existe, requisitos, custo. Só depois cobra e dispara.

---

## 9. Áreas

`SpellArea` descreve a área com três números opcionais, todos `ValueSource`:

| Campo | Significado |
|---|---|
| `distance` | Alcance. `0` (ou vazio) = onde foi conjurado. |
| `radius` | Raio de efeito. |
| `angle_offset` | Desvio em graus somado à direção da mira. Vazio = reto. |

A direção base vem de `SpellContext.direction` (por exemplo, o ângulo do mouse). O ponto de partida vem da âncora da forma: `CASTER` usa `ctx.origin` e `AIM_POINT` usa `ctx.aim_point`.

**Nada é travado.** Como cada número é um `ValueSource`, ele pode vir de:

| De onde | Como |
|---|---|
| Número fixo | `ConstantValue` |
| Atributo do conjurador | `StatValue` (ex.: `area_size`, `range`) |
| Atributo vezes constante | `ProductValue` |
| Poder final da magia | `SpellPowerValue` (ex.: raio = poder vezes `0.1`) |
| Algo seu | Uma subclasse sua de `ValueSource` |

Na conjuração, `SpellArea.resolve(ctx, origem)` calcula tudo e devolve uma `ResolvedArea` com números concretos. É essa `ResolvedArea` que o seu `TargetFinder` e o seu `ProjectileLauncher` recebem. **Quem interpreta a área é o jogo**: em 2D é um círculo ou retângulo de física, em 3D é uma esfera, em grade são células, em jogo por turnos ou de cartas ela pode ser ignorada.

---

## 10. Projétil e rajada

### ProjectileShape

| Campo | Significado |
|---|---|
| `projectile_id` | Identificador que o seu jogo usa para escolher a cena ou animação. |
| `collide_along_path` | Ligado: colide em todo o trajeto. Desligado: só vale o impacto no fim. |
| `area` | `distance` = alcance do trajeto, `radius` = raio de efeito no impacto, `angle_offset` = desvio. |
| `impact_actions` | Lista, em ordem, do que fazer a cada impacto. Vazio = aplicar efeitos e destruir. |
| `anchor`, `effects`, `cost`, `requirements`, `power_multiplier` | Herdados de `SpellShape`. |

**Ações de impacto:**

| Ação | O que faz |
|---|---|
| `ApplyEffectsAction` | Aplica os efeitos da magia. Com `affect_area` ligado e `radius` maior que 0, usa o `TargetFinder` numa área centrada no ponto de impacto. Senão, usa os alvos diretos do impacto. |
| `RecastAction` | Conjura outra `SpellDefinition` a partir do ponto de impacto, sem custo e sem requisitos. `max_depth` (padrão 3) impede laço infinito. |
| `DestroyAction` | Marca o projétil como destruído, e o launcher para de movê-lo. |

Sem `DestroyAction` na lista, o projétil continua depois do impacto (atravessa).

### BurstShape

| Campo | Significado |
|---|---|
| `area` | Distância, raio e desvio da rajada. |
| `instant` | Ligado: acerta uma vez. Desligado: repete ao longo do tempo pelo `SustainedAreaRunner`. |
| `duration`, `tick_interval` | Usados só quando `instant` está desligado (um `ValueSource` cada). |

A área é calculada uma vez, na conjuração. Uma rajada sustentada não acompanha o conjurador se ele se mover.

### Receitas prontas

| Quero | Monte assim |
|---|---|
| Bola de fogo | `ProjectileShape`, colisão ligada, `impact_actions` vazio |
| Flecha que atravessa | `ProjectileShape`, `impact_actions` = [`ApplyEffectsAction` com `affect_area` desligado] |
| Míssil que só explode no fim | `ProjectileShape`, `collide_along_path` desligado, `radius` maior que 0 |
| Bola que explode e solta estilhaços | `impact_actions` = [`ApplyEffectsAction`, `RecastAction` (definição dos estilhaços), `DestroyAction`] |
| Explosão em volta do conjurador | `BurstShape`, âncora `CASTER`, `distance` 0, `radius` maior que 0 |
| Bomba no ponto mirado | `BurstShape`, âncora `AIM_POINT` |
| Rajada instantânea (feixe) | `BurstShape`, `distance` maior que 0, `radius` = largura |
| Rajada contínua | `BurstShape`, `instant` desligado, `duration` e `tick_interval` |
| Buff ou cura em si | `SelfShape` com elementos de cura |
| Absorção | Elemento com um efeito seu que causa dano no alvo e cura `ctx.caster` (seção 13) |

---

## 11. Usando em cada tipo de jogo

O sistema decide O QUE acontece. O jogo decide ONDE e COMO. O que muda de um tipo de jogo para outro é só a implementação dos contratos:

| Tipo de jogo | `TargetFinder` | `ProjectileLauncher` | `SustainedAreaRunner` | Contexto |
|---|---|---|---|---|
| **RPG por turnos** | Devolve os alvos escolhidos na UI, ou grupos inteiros ("todos os inimigos") | Toca a animação e chama `on_impact` uma vez, com `is_end` verdadeiro | Aplica um tick por turno durante `duration` turnos | `aim_point` = alvo escolhido. `origin` e `direction` não são necessários |
| **RPG tático (grade)** | Converte a área em células: `distance` e `radius` em casas, `direction` em direção da grade | Percorre as células da linha e chama `on_impact` na primeira célula ocupada (ou no fim, se `collide_along_path` for falso) | Aplica ticks por turno | `origin` = célula do conjurador (`Vector2i`), `aim_point` = célula mirada |
| **Action RPG 2D** | Consulta de física (formas 2D) | Instancia uma cena por `projectile_id` e a move | Usa um `Timer` | `origin`, `direction` (mouse) e `aim_point` em `Vector2` |
| **Action RPG 3D** | Consulta de física (formas 3D) | Igual ao 2D, com cenas 3D | Usa um `Timer` | Valores em `Vector3` |
| **Jogo de cartas** | Devolve os alvos escolhidos | Instantâneo (ou ignorado se não houver projéteis) | Aplica ticks por turno | Cada carta aponta para uma `SpellDefinition`. `can_cast` destaca as cartas jogáveis |

Em jogos de cartas e por turnos, `ProjectileShape` e `BurstShape` com raio 0 e um `TargetFinder` que devolve "os alvos escolhidos" já cobrem "dano em um alvo" e "dano em todos". Se o seu jogo nunca usa projéteis ou áreas, você pode ficar só com `SelfShape` ou criar formas próprias (seção 13).

### Exemplo: `TargetFinder` para action 2D (ilustrativo)

```gdscript
class_name Physics2DTargetFinder
extends TargetFinder

var space: PhysicsDirectSpaceState2D
var mask: int = 1

func _init(world_space: PhysicsDirectSpaceState2D, collision_mask: int = 1) -> void:
	space = world_space
	mask = collision_mask

func find_targets(area: ResolvedArea, _ctx: SpellContext) -> Array:
	var origin: Vector2 = area.origin
	var direction: Vector2 = area.direction
	direction = direction.rotated(deg_to_rad(area.angle_offset))
	var circle := CircleShape2D.new()
	circle.radius = area.radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = mask
	query.transform = Transform2D(0.0, origin + direction * area.distance)
	var targets: Array = []
	for hit in space.intersect_shape(query):
		targets.append(hit["collider"])
	return targets
```

O espaço de física se obtém com `get_world_2d().direct_space_state` dentro de um Node. Para um feixe estreito e longo, troque o círculo por um retângulo.

### Exemplo: `ProjectileLauncher` para action 2D (ilustrativo)

```gdscript
class_name Scene2DProjectileLauncher
extends ProjectileLauncher

var scenes: Dictionary   # projectile_id (texto) -> PackedScene
var parent: Node

func _init(scene_map: Dictionary, parent_node: Node) -> void:
	scenes = scene_map
	parent = parent_node

func launch(request: ProjectileRequest) -> void:
	var scene: PackedScene = scenes.get(String(request.projectile_id))
	if scene == null:
		return
	var projectile := scene.instantiate()
	parent.add_child(projectile)
	projectile.setup(request)
```

E o script da raiz da cena do projétil (um `Area2D`), que segue as regras do contrato:

```gdscript
extends Area2D

const SPEED := 400.0

var _request: ProjectileRequest
var _velocity := Vector2.ZERO
var _remaining: float = 0.0

func setup(request: ProjectileRequest) -> void:
	_request = request
	var origin: Vector2 = request.area.origin
	var direction: Vector2 = request.area.direction
	direction = direction.rotated(deg_to_rad(request.area.angle_offset))
	global_position = origin
	_velocity = direction * SPEED
	_remaining = request.area.distance
	if request.collide_along_path:
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_remaining -= SPEED * delta
	if _remaining <= 0.0:
		_finish()

func _on_body_entered(body: Node) -> void:
	if body == _request.ctx.caster:
		return
	var impact := ProjectileImpact.new()
	impact.point = global_position
	impact.targets = [body]
	_request.on_impact.call(impact)
	if impact.destroyed:
		queue_free()

func _finish() -> void:
	var impact := ProjectileImpact.new()
	impact.point = global_position
	impact.is_end = true
	_request.on_impact.call(impact)
	queue_free()
```

Neste exemplo, `distance` 0 faz o projétil terminar na hora, no ponto de origem.

### Exemplo: `ProjectileLauncher` instantâneo (por turnos e cartas)

```gdscript
class_name InstantProjectileLauncher
extends ProjectileLauncher

var selected_targets: Array = []   # preenchido pela UI de batalha

func launch(request: ProjectileRequest) -> void:
	var impact := ProjectileImpact.new()
	impact.point = request.ctx.aim_point
	impact.targets = selected_targets
	impact.is_end = true
	request.on_impact.call(impact)
```

---

## 12. Fluxos

### Montagem (build)

```
SpellDefinition  (forma + elementos + nome, custo e requisitos opcionais)
      │
      ▼
SpellBuilder.build(definition)
      │  1. shape = definition.shape.resolve(definition.elements)
      │  2. custo = definition.cost + shape.cost + soma dos elements[i].cost
      │  3. requisitos = definition + shape + elements (todos juntos)
      │  4. nome = SpellNamer.build_name(definition, shape, elements)
      ▼
SpellInstance  (display_name, shape, elements, cost, requirements)
```

### Conjuração (cast)

```
SpellCaster.cast(spell, ctx)
      │
      ├─ sem forma?                          → devolve NO_SHAPE
      ├─ algum requisito não cumprido?       → devolve REQUIREMENT_NOT_MET
      ├─ payer existe e não consegue pagar?  → devolve CANNOT_PAY
      │        (nos três casos nada é cobrado nem disparado)
      ▼
payer.pay(spell.cost)   (se houver payer)
      │
      ▼
fire(spell, ctx):  ctx.spell = spell  →  spell.shape.cast(spell, ctx)
      │
      ▼
a forma acha ou cria os alvos e chama spell.apply_to(ctx, alvo)
      │
      ▼
para cada efeito dos elementos e da forma: effect.apply(alvo, poder, ctx)
      │
      ▼
devolve OK
```

### Custos (exemplo numérico)

```
Forma "Bola de"     : mana 5
Elemento "fogo"     : mana 2, hp 2
Definição da magia  : (sem custo)
                      ───────────────
Custo final         : mana 7, hp 2
```

### Poder

```
Elemento fogo       : power = StatValue("magic_power")
Atributo do jogo    : magic_power = 10        (vem do StatProvider)
Soma dos elementos  : 10
Forma               : power_multiplier = 1.5
Poder final         : 10 * 1.5 = 15
DamageEffect        : multiplier = 1.0  →  alvo.take_damage(15)
```

### Área

```
SpellArea (distance, radius, angle_offset: cada um um ValueSource)
      │  resolve(ctx, forma.get_origin(ctx))
      │    origem   = ctx.origin  (âncora CASTER)  ou  ctx.aim_point  (âncora AIM_POINT)
      │    direção  = ctx.direction
      │    números  = cada ValueSource lido com o contexto atual
      ▼
ResolvedArea (origin, direction, distance, radius, angle_offset)
      │
      ▼
TargetFinder.find_targets(area, ctx)  ou  ProjectileLauncher  (o jogo interpreta)
```

### Rajada (BurstShape)

```
BurstShape.cast(spell, ctx)
      │  resolve a área
      ├─ instant ligado (ou sem SustainedAreaRunner)
      │       └─ finder.find_targets(área)  →  spell.apply_to(ctx, cada alvo)
      └─ instant desligado
              └─ SustainedAreaRunner.start(request)
                      └─ a cada tick: finder.find_targets(área)  →  apply_to em cada alvo
```

### Projétil (ProjectileShape)

```
ProjectileShape.cast(spell, ctx)
      │  resolve a área, monta o ProjectileRequest
      ▼
ProjectileLauncher.launch(request)          (o jogo move o projétil)
      │
      ├─ a cada impacto (ou só no fim, se collide_along_path for falso):
      │      cria ProjectileImpact (point, targets, is_end)
      │      request.on_impact.call(impact)
      │            └─ executa as impact_actions em ordem
      │                  (ou ApplyEffectsAction + DestroyAction, se a lista estiver vazia)
      │      impact.destroyed?  → sim: o jogo para o projétil / não: segue
      ▼
fim do trajeto: impacto com is_end verdadeiro
```

### Reconjuração (RecastAction)

```
RecastAction.execute(...)
      │  ctx.depth >= max_depth?  → sim: não faz nada
      ▼
SpellBuilder.build(definition)  →  SpellCaster.fire(nova magia, ctx.derive(ponto de impacto))
      │      (derive: mesmo conjurador, atributos, tags, finder, launcher;
      │       origem e ponto mirado = impacto; depth + 1; SEM payer, então não cobra)
      ▼
a nova magia segue o fluxo normal de forma e efeitos
```

### Nome

```
custom_name preenchido?
   ├─ sim: usa custom_name                      →  "Meteoro"
   └─ não: name_prefix da forma resolvida
           + nomes dos elementos ligados por " e "
                                                →  "Bola de fogo"
                                                →  "Bola de fogo e sangue"
```

### Variação de forma (extensão opcional)

```
Definição usa um ShapeGroup como forma
      │
      ▼
SpellBuilder chama group.resolve(elements)
      │
      ├─ percorre as variantes em ordem
      │     └─ primeira condição verdadeira: devolve variante.shape.resolve(elements)
      └─ nenhuma verdadeira: devolve fallback.resolve(elements)

Elemento com tag "solid"  →  forma "Estaca de"  →  "Estaca de terra"
Qualquer outro elemento   →  forma "Bola de"    →  "Bola de fogo"
```

Só custo, requisitos, multiplicador e prefixo da forma ESCOLHIDA contam. O grupo em si é ignorado nesses campos.

---

## 13. Como estender

Em todos os casos abaixo você CRIA um arquivo novo e não edita nenhum existente.

**Nova forma** (ex.: cone, corrente, alvo único): crie um script que herda de `SpellShape`, sobrescreva `cast(spell, ctx)`, ache os alvos do seu jeito (de preferência pelo `ctx.finder`) e chame `spell.apply_to(ctx, alvo)` para cada um. Guarde em `scripts/library/shapes/`.

**Novo efeito** (cura, veneno, empurrão...): herde de `SpellEffect` e sobrescreva `apply(target, power, ctx)`. Exemplo de absorção, que causa dano no alvo e cura o conjurador:

```gdscript
class_name DrainEffect
extends SpellEffect

@export var heal_ratio: float = 0.5

func apply(target: Object, power: float, ctx: SpellContext) -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(power)
	if ctx.caster != null and ctx.caster.has_method("heal"):
		ctx.caster.heal(power * heal_ratio)
```

**Nova ação de impacto** (ex.: quicar, dividir, grudar): herde de `ImpactAction` e sobrescreva `execute(spell, ctx, area, impact)`. Guarde em `scripts/library/impact/`.

**Novo requisito** (ex.: hora do dia, recurso em recarga): herde de `SpellRequirement` e sobrescreva `is_met(ctx)`. Guarde em `scripts/library/requirements/`.

**Nova fonte de número** (soma, mínimo, nível do conjurador): herde de `ValueSource` e sobrescreva `get_value(ctx)`.

**Nova regra de nome**: herde de `SpellNamer`, sobrescreva `build_name(...)` e passe ao construtor: `SpellBuilder.new(MeuNamer.new())`.

**Novo contrato do mundo** (ex.: sons, câmera, log de combate): crie uma classe base como as de `core/contracts/`, adicione um campo no `SpellContext` e use-a nas suas formas e efeitos.

---

## 14. Extensão opcional: variações de forma

Serve para a mesma "forma de projétil" virar "Estaca de..." ou "Bola de..." conforme o elemento.

**Como montar no editor.** Crie `bola.tres` e `estaca.tres` (cada um um `ProjectileShape`, com seus prefixos). Crie `projetil.tres` do tipo `ShapeGroup`. No Inspector, em `Variants`, clique em Add Element e escolha `ShapeVariant`; em `Condition` escolha `ElementTagCondition` e escreva `solid` no campo `Tag`; em `Shape` arraste `estaca.tres`. Em `Fallback` do grupo arraste `bola.tres`. Na `SpellDefinition`, use `projetil.tres` como `Shape`. Marque a tag `solid` nos elementos sólidos (`terra.tres`, por exemplo).

**Como remover por completo.**

Passo 1. Abra os seus `.tres` e troque qualquer `ShapeGroup` por uma forma direta (`bola.tres`, por exemplo). Se algum recurso ainda apontar para `ShapeGroup`, `ShapeVariant` ou `ElementTagCondition`, o Godot mostrará um aviso de script ausente.

Passo 2. No painel FileSystem, apague a pasta `scripts/extensions/shape_variants/`.

Passo 3. Apague a pasta `Tests/extensions/`, porque o teste dela só funciona com a extensão.

Passo 4. Pronto. O núcleo, o construtor, o conjurador, a biblioteca e os outros testes continuam funcionando sem nenhuma edição.

---

## 15. Testes

Os testes ficam em `Tests/` e são descartáveis. São cenas que rodam sozinhas, imprimem o resultado no painel Output e fecham.

**Rodar um teste.** No FileSystem, dê duplo clique em uma das cenas abaixo para abri-la e aperte F6 (Run Current Scene). No painel Output, cada verificação aparece como `[ok]` ou `[FALHOU]`, e no fim há a linha `Resultado: N ok, M falhas`.

| Cena | O que testa |
|---|---|
| `Tests/test_core_spell.tscn` | Custo somado, nomes, poder, conjuração, falta de recursos, `SelfShape` |
| `Tests/test_requirements.tscn` | Requisitos de tag e de atributo, soma de requisitos, bloqueio da conjuração |
| `Tests/test_area_shapes.tscn` | Áreas vindas de atributos, âncora, rajada instantânea e sustentada, projétil, ações de impacto, reconjuração e limite de profundidade |
| `Tests/extensions/test_shape_variants.tscn` | Grupo de formas (extensão opcional) |

**Se a cena reclamar de script ausente** (você moveu ou renomeou a pasta): abra a cena, clique no nó raiz, no Inspector em Script escolha Load e selecione o `.gd` de mesmo nome, depois salve.

**Criar um teste novo.** Crie um script que herda de `TestCase` (`extends TestCase`), escreva as verificações com `check(condicao, "descrição")` dentro de `_ready()` e termine com `finish()`. Crie uma cena com um `Node` na raiz, anexe o script e rode com F6. Use `TestFactory` para montar peças e os dublês de `Tests/support` (`TestFinder`, `TestLauncher`, `TestSustainedRunner`, `TestTags`) no lugar do seu jogo.

---

## 16. Cuidados e erros comuns

- **Chaves iguais em todos os lugares.** Se `"mana"` está no `SpellCost` e o seu dicionário usa `"Mana"`, a verificação falha. Se o seu dicionário usa `StringName`, converta nas pontes.
- **`class_name` duplicado.** Se aparecer erro de classe global repetida, há uma cópia antiga em outra pasta. Apague a antiga.
- **Arrays tipados.** Em `Elements`, `Effects`, `Requirements`, `Variants` e `Impact Actions`, use Add Element no Inspector e escolha o tipo na lista. Pelo código, use `.append(...)`.
- **Contexto incompleto é proposital.** Sem `stats`, os `StatValue` devolvem o `fallback`. Sem `payer`, não há cobrança. Sem `finder`, rajadas não acertam ninguém. Sem `launcher`, o projétil não acontece e um aviso aparece no Output.
- **Requisitos sem provedor.** Sem `TagProvider`, `TagRequirement` com "ter" falha. Sem `StatProvider`, `StatAtLeastRequirement` falha.
- **Poder e área.** `SpellPowerValue` serve para áreas e durações. Nunca use dentro de `element.power`, porque o poder depende dele (laço infinito).
- **Reconjuração é gratuita.** `RecastAction` usa um contexto filho sem `payer`. Se quiser cobrar, crie a sua própria ação.
- **Área sustentada é fixa.** Em `BurstShape` não instantânea, a área é calculada uma vez e não acompanha o conjurador.
- **`distance` 0 em projétil.** O sistema não impõe regra: quem decide é o seu `ProjectileLauncher`. No exemplo da seção 11, o projétil termina na hora.
- **`ShapeGroup` não tem custo, requisitos nem prefixo próprios.** Esses campos existem por herança e são ignorados. Coloque-os nas formas que o grupo escolhe.
- **Grupo sem saída.** Se nenhuma condição for verdadeira e não houver `fallback`, `resolve` devolve `null` e o `SpellBuilder` devolve `null` com um erro no Output.

---

## 17. SOLID no projeto

| Princípio | Onde aparece |
|---|---|
| **S** (responsabilidade única) | `SpellCost` só soma custos. `SpellNamer` só nomeia. `SpellBuilder` só monta. `SpellCaster` só verifica, cobra e dispara. `SpellArea` só descreve a área. Formas só entregam, elementos só definem o efeito. |
| **O** (aberto/fechado) | Formas, efeitos, ações de impacto, requisitos, fontes de valor e condições novos são arquivos novos. Nada existente é editado. |
| **L** (substituição de Liskov) | Qualquer `SpellShape` serve onde uma forma é esperada, inclusive o `ShapeGroup`. Qualquer `ValueSource`, `SpellRequirement` ou `ImpactAction` serve onde o tipo base é esperado. |
| **I** (segregação de interfaces) | Seis contratos pequenos e separados (`StatProvider`, `TagProvider`, `CostPayer`, `TargetFinder`, `ProjectileLauncher`, `SustainedAreaRunner`). O jogo implementa só os que usa. |
| **D** (inversão de dependência) | O núcleo depende de abstrações, nunca de classes do seu jogo, nem de física, nem de cenas. O `SpellBuilder` recebe o `SpellNamer` por parâmetro. Tudo que depende do mundo entra pelos contratos. |
