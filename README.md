# Magic_System.G

Sistema de magia dinâmica para Godot 4 (GDScript), feito com composição de Resources e princípios SOLID.

Uma magia é montada em tempo de execução a partir de **formas** (COMO a magia é entregue: bola, explosão, rajada, absorção...) e **elementos** (O QUE a magia faz: efeitos, tags, números, custos). Custo, poder e nome são calculados automaticamente.

O sistema não assume nada sobre o seu jogo: não sabe se existe mana, vida ou atributos, nem se o jogo é 2D ou 3D. Tudo isso entra por contratos pequenos que o seu jogo implementa.

> **Premissas deste manual**
> - Godot 4.x e GDScript.
> - GDScript não tem interfaces, então os "contratos" são classes base com métodos vazios que você sobrescreve.
> - Alvos recebem dano por "duck typing": o `DamageEffect` chama `take_damage(valor)` se o alvo tiver esse método.
> - Os exemplos de projétil estão em 2D. Em 3D a ideia é a mesma, trocando `Vector2` por `Vector3`.
> - Chaves de custo e de atributo são textos simples (`"mana"`, `"hp"`, `"magic_power"`). Use sempre o mesmo texto em todos os lugares.

## Sumário

1. [Conceitos](#1-conceitos)
2. [Instalação](#2-instalação)
3. [Estrutura de pastas](#3-estrutura-de-pastas)
4. [Referência dos arquivos](#4-referência-dos-arquivos)
5. [Regras de dependência](#5-regras-de-dependência)
6. [Como usar](#6-como-usar)
7. [Fluxos](#7-fluxos)
8. [Como estender](#8-como-estender)
9. [Extensão opcional: variações de forma](#9-extensão-opcional-variações-de-forma)
10. [Testes](#10-testes)
11. [Cuidados e erros comuns](#11-cuidados-e-erros-comuns)
12. [SOLID no projeto](#12-solid-no-projeto)

---

## 1. Conceitos

| Termo | O que é |
|---|---|
| **Forma** (`SpellShape`) | Define COMO a magia chega aos alvos (projétil, explosão, em si mesmo). Pode ter custo, tags, multiplicador de poder e prefixo de nome (`"Bola de"`). |
| **Elemento** (`SpellElement`) | Define O QUE a magia faz: número bruto, efeitos, tags, custo e nome (`"fogo"`). |
| **Custo** (`SpellCost`) | Dicionário genérico de recursos e quantidades. Custos de magia, forma e elementos são somados. |
| **ValueSource** | De onde vem um número bruto: constante, atributo do conjurador ou uma conta entre valores. |
| **Efeito** (`SpellEffect`) | Algo que acontece com um alvo (dano, cura, status). |
| **Definição** (`SpellDefinition`) | A receita editável de uma magia (forma + elementos + nome opcional + custo opcional). |
| **Instância** (`SpellInstance`) | A magia pronta, com nome, forma resolvida e custo total. |
| **Construtor** (`SpellBuilder`) | Transforma uma definição em uma instância. |
| **Conjurador** (`SpellCaster`) | Cobra o custo e dispara a forma. |
| **Contexto** (`SpellContext`) | Os dados de uma conjuração: quem conjura, atributos, pagador, origem e direção. |
| **Contratos** | `StatProvider` e `CostPayer`: as duas pontes que o SEU jogo implementa. |

---

## 2. Instalação

Passo 1. Feche nada: o Godot pode ficar aberto. Pelo gerenciador de arquivos do seu sistema, copie a pasta `Magic_System.G` inteira para dentro da pasta do seu projeto Godot, no mesmo nível do arquivo `project.godot`.

Passo 2. Volte ao Godot e espere a barra de progresso de importação terminar. O painel FileSystem passa a mostrar `res://Magic_System.G/`.

Passo 3. Abra o painel Output (parte de baixo da janela) e confirme que não há erros vermelhos. Os scripts usam `class_name`, então todas as classes ficam disponíveis globalmente, sem `preload`.

Passo 4. Se você já tinha uma versão anterior das mesmas classes em outra pasta, apague a pasta antiga pelo painel FileSystem (clique direito, Delete). Duas pastas com a mesma `class_name` causam erro de "class hides a global script class".

Passo 5. Implemente os dois contratos no SEU jogo (seção 6, passo 1). Esses arquivos ficam fora desta pasta, porque dependem do seu jogo.

> A pasta se chama `Magic_System.G` e os testes apontam para `res://Magic_System.G/Tests/...`. Se você renomear ou mover a pasta, só as duas cenas `.tscn` de teste precisam ser reanexadas (seção 10).

---

## 3. Estrutura de pastas

```
Magic_System.G/
├── README.md
├── scripts/                       Código real do sistema
│   ├── core/                      Peças fundamentais de uma magia
│   │   ├── components/            Forma, elemento, efeito, instância
│   │   ├── cost/                  Custos
│   │   ├── values/                Números brutos (ValueSource)
│   │   └── contracts/             Pontes com o jogo (contexto, atributos, pagador)
│   ├── building/                  Construção: receita, construtor e nomeador
│   ├── casting/                   Execução: cobrar custo e disparar
│   ├── library/                   Peças prontas de uso (substituíveis)
│   │   ├── shapes/
│   │   └── effects/
│   └── extensions/                Recursos OPCIONAIS, removíveis
│       └── shape_variants/        Grupos de formas (Estaca de / Bola de)
└── Tests/                         Código descartável, só para testar na prática
    ├── support/                   Dublês e atalhos de teste
    ├── extensions/                Testes das extensões opcionais
    ├── test_core_spell.gd / .tscn
    └── ...
```

Em uma frase por pasta:

- **core**: o que uma magia É. Não conhece construtores, nem execução, nem extensões.
- **building**: como uma magia é MONTADA a partir de uma receita.
- **casting**: como uma magia pronta é DISPARADA.
- **library**: formas e efeitos concretos prontos. Servem de exemplo e podem ser trocados ou apagados à vontade.
- **extensions**: funcionalidades extras. Apagar uma pasta daqui não quebra nada no resto.
- **Tests**: nada em `scripts` depende desta pasta. Pode ser apagada inteira.

---

## 4. Referência dos arquivos

### scripts/core/components

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_component.gd` | `SpellComponent` | Base de forma e elemento. Tem `cost` e `tags`. |
| `spell_shape.gd` | `SpellShape` | Base de formas. Tem `name_prefix`, `power_multiplier`, `resolve(elements)` (gancho que devolve a si mesma) e `cast(spell, ctx)` (vazio, subclasses implementam). |
| `spell_element.gd` | `SpellElement` | Elemento. Tem `display_name`, `power` (um `ValueSource`) e `effects`. |
| `spell_effect.gd` | `SpellEffect` | Base de efeitos. Método `apply(target, power, ctx)`. |
| `spell_instance.gd` | `SpellInstance` | Magia pronta. Guarda `display_name`, `shape`, `elements`, `cost`. Calcula poder e aplica efeitos. |

### scripts/core/cost

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_cost.gd` | `SpellCost` | Dicionário `amounts` e o método `merged_with(outro)` que soma custos sem alterar os originais. |

### scripts/core/values

| Arquivo | Classe | Resumo |
|---|---|---|
| `value_source.gd` | `ValueSource` | Base. `get_value(ctx)` devolve um `float`. |
| `constant_value.gd` | `ConstantValue` | Número fixo. |
| `stat_value.gd` | `StatValue` | Atributo do conjurador (via `StatProvider`) vezes uma escala, com valor reserva (`fallback`). |
| `product_value.gd` | `ProductValue` | Multiplica dois `ValueSource`. Útil para elemento que só multiplica um atributo. |

### scripts/core/contracts

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_context.gd` | `SpellContext` | Dados da conjuração: `caster`, `stats`, `payer`, `origin`, `direction`. |
| `stat_provider.gd` | `StatProvider` | Contrato: `get_stat(chave, padrão)`. O jogo herda. |
| `cost_payer.gd` | `CostPayer` | Contrato: `can_pay(custo)` e `pay(custo)`. O jogo herda. |

### scripts/building

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_definition.gd` | `SpellDefinition` | Receita editável: `custom_name`, `shape`, `elements`, `cost`. |
| `spell_builder.gd` | `SpellBuilder` | `build(definition)` resolve a forma, soma os custos, gera o nome e devolve um `SpellInstance`. Aceita um `SpellNamer` próprio no construtor. |
| `spell_namer.gd` | `SpellNamer` | Regra de nome: usa `custom_name` se existir, senão `prefixo da forma + nomes dos elementos`. |

### scripts/casting

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_caster.gd` | `SpellCaster` | `cast(spell, ctx)` verifica e cobra o custo (se houver pagador) e dispara a forma. |

### scripts/library

| Arquivo | Classe | Resumo |
|---|---|---|
| `shapes/self_shape.gd` | `SelfShape` | Aplica a magia no próprio conjurador. |
| `shapes/projectile_shape.gd` | `ProjectileShape` | Instancia uma cena de projétil e chama `launch(spell, ctx)` nela. |
| `effects/damage_effect.gd` | `DamageEffect` | Chama `take_damage(poder * multiplicador)` no alvo, se o método existir. |

### scripts/extensions/shape_variants (OPCIONAL)

| Arquivo | Classe | Resumo |
|---|---|---|
| `shape_group.gd` | `ShapeGroup` | Uma forma que escolhe outra forma conforme condições. Pode conter outros grupos. |
| `shape_variant.gd` | `ShapeVariant` | Par condição + forma usado pelo grupo. |
| `spell_condition.gd` | `SpellCondition` | Base de condições. `is_met(elements)`. |
| `element_tag_condition.gd` | `ElementTagCondition` | Verdadeira se algum elemento tiver a tag indicada. |

### Tests

| Arquivo | Resumo |
|---|---|
| `support/test_case.gd` | Base dos testes: `section`, `check`, `finish`. |
| `support/test_factory.gd` | Atalhos para montar custos, formas, elementos, definições e contexto. |
| `support/test_dummy.gd` | Personagem falso com `hp`, `stats`, `resources` e `take_damage`. |
| `support/test_stats.gd` | `StatProvider` de teste (lê de um dicionário). |
| `support/test_payer.gd` | `CostPayer` de teste (cobra do `resources` do dummy). |
| `support/test_recording_shape.gd` | Forma de teste que conta quantas vezes foi conjurada. |
| `test_core_spell.gd` e `.tscn` | Testa custo somado, nomes, poder, conjuração, falta de recursos e `SelfShape`. |
| `extensions/test_shape_variants.gd` e `.tscn` | Testa o grupo de formas. Apague junto com a extensão. |

---

## 5. Regras de dependência

A seta significa "conhece":

```
extensions ──► core          (extensões usam as peças fundamentais)
library    ──► core
building   ──► core
casting    ──► core
Tests      ──► tudo         (e NADA conhece Tests)
core       ──► ninguém      (exceto ele mesmo)
```

Duas consequências práticas:

- Você pode apagar `library`, `extensions` ou `Tests` sem quebrar o resto, desde que nenhum `.tres` seu use uma classe apagada.
- O único traço de "variações de forma" dentro do núcleo é o método genérico `SpellShape.resolve(elements)`, que só devolve a própria forma. Ele não menciona grupos e continua útil mesmo sem a extensão.

---

## 6. Como usar

### Passo 1. Implementar os contratos no seu jogo

Crie estes arquivos na pasta do SEU jogo (por exemplo `res://game/magic/`), nunca dentro de `Magic_System.G`.

`player_stats.gd` ensina o sistema a ler atributos:

```gdscript
class_name PlayerStats
extends StatProvider

var player: Node

func _init(p: Node) -> void:
	player = p

func get_stat(key: StringName, default_value: float = 0.0) -> float:
	return player.stats.get(String(key), default_value)
```

`player_payer.gd` ensina o sistema a cobrar custos:

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

Aqui `player.stats` e `player.resources` são dicionários do SEU personagem. Troque pelo que o seu jogo tiver. Os dois contratos são opcionais: sem `StatProvider` os `StatValue` usam o `fallback`, sem `CostPayer` a magia não cobra nada.

**Entradas e saídas:** `get_stat(chave, padrão) → float`, `can_pay(custo) → bool`, `pay(custo) → nada`.

### Passo 2. Criar as peças (no editor)

No painel FileSystem, clique direito na pasta onde quer guardar, escolha Create New, depois Resource. Na janela, digite o nome da classe (por exemplo `SpellElement`) e confirme. Salve com um nome claro (`fogo.tres`). Depois selecione o arquivo e preencha no Inspector.

Elemento `fogo.tres` (`SpellElement`):
- `Display Name`: `fogo`
- `Tags`: adicione `fire`
- `Power`: escolha `StatValue`, depois `Stat Key` = `magic_power`
- `Effects`: Add Element, escolha `DamageEffect`
- `Cost`: crie um `SpellCost`, em `Amounts` adicione a chave `mana` com valor `2` e a chave `hp` com valor `2`

Forma `bola.tres` (`ProjectileShape`):
- `Name Prefix`: `Bola de`
- `Power Multiplier`: `1.0`
- `Projectile Scene`: arraste a cena do seu projétil
- `Cost`: um `SpellCost` com `mana` = `5`

Receita `bola_de_fogo.tres` (`SpellDefinition`):
- `Custom Name`: deixe vazio para nome automático
- `Shape`: arraste `bola.tres`
- `Elements`: Add Element e arraste `fogo.tres`
- `Cost`: opcional

### Passo 2 (alternativa). Criar as peças por código

```gdscript
var shape := SelfShape.new()
shape.name_prefix = "Marca de"

var power := StatValue.new()
power.stat_key = &"magic_power"

var fire := SpellElement.new()
fire.display_name = "fogo"
fire.power = power
fire.effects.append(DamageEffect.new())

var definition := SpellDefinition.new()
definition.shape = shape
definition.elements.append(fire)
```

### Passo 3. Montar a magia

```gdscript
var spell := SpellBuilder.new().build(definition)
print(spell.display_name)   # "Marca de fogo"
print(spell.cost.amounts)   # custos somados
```

**Entrada:** `SpellDefinition`. **Saída:** `SpellInstance`, ou `null` se a definição não tiver forma ou nenhuma forma for resolvida (um erro aparece no Output).

Monte uma vez e reaproveite o `SpellInstance` quantas vezes quiser. Só monte de novo se a definição mudar.

### Passo 4. Preencher o contexto

No script do conjurador (por exemplo, o jogador):

```gdscript
var ctx := SpellContext.new()
ctx.caster = self
ctx.stats = PlayerStats.new(self)
ctx.payer = PlayerPayer.new(self)
ctx.origin = global_position
ctx.direction = aim_direction
```

**Entradas:** o que o seu jogo tiver. Campos não usados podem ficar vazios.

### Passo 5. Conjurar

```gdscript
var done := SpellCaster.new().cast(spell, ctx)
```

**Entrada:** `SpellInstance` e `SpellContext`. **Saída:** `true` se conjurou, `false` se o pagador recusou (nesse caso nada acontece: nenhum custo cobrado, nenhuma forma disparada).

### Passo 6. Fazer o projétil terminar o trabalho (só para `ProjectileShape`)

A cena do projétil precisa de um método `launch(spell, ctx)` e chamar `spell.apply_to(ctx, alvo)` ao acertar. Exemplo em 2D, no script da raiz (um `Area2D`):

```gdscript
extends Area2D

var _spell: SpellInstance
var _ctx: SpellContext
var _velocity := Vector2.ZERO

func launch(spell: SpellInstance, ctx: SpellContext) -> void:
	_spell = spell
	_ctx = ctx
	global_position = ctx.origin
	_velocity = ctx.direction * 400.0
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_body_entered(body: Node) -> void:
	if body == _ctx.caster:
		return
	_spell.apply_to(_ctx, body)
	queue_free()
```

### Resumo de entradas e saídas

| Chamada | Entrada | Saída |
|---|---|---|
| `SpellBuilder.new(namer?)` | `SpellNamer` opcional | construtor |
| `SpellBuilder.build(def)` | `SpellDefinition` | `SpellInstance` ou `null` |
| `SpellCaster.cast(spell, ctx)` | `SpellInstance`, `SpellContext` | `bool` |
| `SpellInstance.compute_power(ctx)` | `SpellContext` | `float` |
| `SpellInstance.apply_to(ctx, alvo)` | `SpellContext`, `Node` | nada (efeitos agem no alvo) |
| `SpellCost.merged_with(outro)` | `SpellCost` ou `null` | novo `SpellCost` |
| `ValueSource.get_value(ctx)` | `SpellContext` | `float` |
| `SpellShape.resolve(elements)` | `Array[SpellElement]` | `SpellShape` (ou `null` em grupos sem saída) |
| `SpellShape.cast(spell, ctx)` | `SpellInstance`, `SpellContext` | nada |
| `SpellEffect.apply(alvo, poder, ctx)` | `Node`, `float`, `SpellContext` | nada |
| `SpellNamer.build_name(def, shape, elements)` | definição, forma resolvida, elementos | `String` |
| `StatProvider.get_stat(chave, padrão)` | `StringName`, `float` | `float` |
| `CostPayer.can_pay(custo)` | `SpellCost` | `bool` |
| `CostPayer.pay(custo)` | `SpellCost` | nada |

---

## 7. Fluxos

### Fluxo de montagem (build)

```
SpellDefinition  (forma + elementos + nome opcional + custo opcional)
      │
      ▼
SpellBuilder.build(definition)
      │  1. shape = definition.shape.resolve(definition.elements)
      │  2. custo = definition.cost + shape.cost + soma dos elements[i].cost
      │  3. nome  = SpellNamer.build_name(definition, shape, elements)
      ▼
SpellInstance  (display_name, shape, elements, cost)
```

### Fluxo de conjuração (cast)

```
SpellCaster.cast(spell, ctx)
      │
      ├─ ctx.payer existe?
      │     ├─ não: segue sem cobrar
      │     └─ sim: payer.can_pay(spell.cost)?
      │              ├─ não: devolve false e para (nada acontece)
      │              └─ sim: payer.pay(spell.cost)
      ▼
spell.shape.cast(spell, ctx)          (a forma escolhe os alvos)
      │
      ▼
spell.apply_to(ctx, alvo)             (para cada alvo)
      │
      ▼
effect.apply(alvo, poder, ctx)        (para cada efeito de cada elemento)
      │
      ▼
devolve true
```

### Fluxo de custos (exemplo numérico)

```
Forma "Bola de"     : mana 5
Elemento "fogo"     : mana 2, hp 2
Definição da magia  : (sem custo)
                      ───────────────
Custo final         : mana 7, hp 2
```

`SpellCost.merged_with` soma chave por chave. Chaves que só existem de um lado são mantidas.

### Fluxo de poder

```
Elemento fogo     : power = StatValue("magic_power", escala 1)
Atributo do jogo  : magic_power = 10        (vem do StatProvider)
Soma dos elementos: 10
Forma             : power_multiplier = 1.5
Poder final       : 10 * 1.5 = 15
DamageEffect      : multiplier = 1.0  →  target.take_damage(15)
```

Se o seu jogo não tiver atributos, use `ConstantValue` no elemento. Se o elemento deve só multiplicar um atributo, use `ProductValue` (atributo vezes constante).

### Fluxo de nome

```
custom_name preenchido?
   ├─ sim: usa custom_name                    →  "Meteoro"
   └─ não: name_prefix da forma resolvida
           + nomes dos elementos ligados por " e "
                                              →  "Bola de fogo"
                                              →  "Bola de fogo e sangue"
```

### Fluxo com variação de forma (extensão opcional)

```
Definição usa um ShapeGroup como forma
      │
      ▼
SpellBuilder chama group.resolve(elements)
      │
      ├─ varia a lista de variantes, em ordem
      │     └─ primeira condição verdadeira: devolve variante.shape.resolve(elements)
      └─ nenhuma verdadeira: devolve fallback.resolve(elements)

Elemento com tag "solid"  →  forma "Estaca de"  →  "Estaca de terra"
Qualquer outro elemento   →  forma "Bola de"    →  "Bola de fogo"
```

Só o custo, o multiplicador e o prefixo da forma ESCOLHIDA contam. O grupo em si é ignorado nesses campos.

---

## 8. Como estender

Em todos os casos abaixo você CRIA um arquivo novo e não edita nenhum existente.

**Nova forma** (ex.: explosão): crie um script que herda de `SpellShape`, sobrescreva `cast(spell, ctx)`, descubra os alvos do seu jeito e chame `spell.apply_to(ctx, alvo)` para cada um. Guarde em `scripts/library/shapes/`.

**Novo efeito** (ex.: cura, veneno, empurrão): herde de `SpellEffect` e sobrescreva `apply(target, power, ctx)`. Guarde em `scripts/library/effects/`.

**Nova fonte de número** (ex.: soma, mínimo, nível do conjurador): herde de `ValueSource` e sobrescreva `get_value(ctx)`. Guarde em `scripts/core/values/` (ou em `library` se for específica do seu jogo).

**Nova regra de nome**: herde de `SpellNamer`, sobrescreva `build_name(...)` e passe ao construtor: `SpellBuilder.new(MeuNamer.new())`.

**Nova condição de grupo**: herde de `SpellCondition` e sobrescreva `is_met(elements)`. Só faz sentido se você mantiver a extensão de variações.

---

## 9. Extensão opcional: variações de forma

Serve para a mesma "forma de projétil" virar "Estaca de..." ou "Bola de..." conforme o elemento.

**Como montar no editor.** Crie `bola.tres` e `estaca.tres` (cada um um `ProjectileShape`, com seus prefixos). Crie `projetil.tres` do tipo `ShapeGroup`. No Inspector, em `Variants`, Add Element, escolha `ShapeVariant`; em `Condition` escolha `ElementTagCondition` e escreva `solid` no campo `Tag`; em `Shape` arraste `estaca.tres`. Em `Fallback` do grupo arraste `bola.tres`. Na `SpellDefinition`, use `projetil.tres` como `Shape`. Marque a tag `solid` nos elementos sólidos (`terra.tres`, por exemplo).

**Como remover por completo.**

Passo 1. Abra seus `.tres` e troque qualquer `ShapeGroup` por uma forma direta (`bola.tres`, por exemplo). Se algum recurso ainda apontar para `ShapeGroup`, `ShapeVariant` ou `ElementTagCondition`, o Godot mostrará um aviso de script ausente.

Passo 2. No painel FileSystem, apague a pasta `scripts/extensions/shape_variants/`.

Passo 3. Apague a pasta `Tests/extensions/` (o teste dela só funciona com a extensão).

Passo 4. Pronto. O núcleo, o construtor, o conjurador, a biblioteca e o teste do núcleo continuam funcionando. Nada precisa ser editado.

---

## 10. Testes

Os testes ficam em `Tests/` e são descartáveis. São cenas que rodam sozinhas, imprimem o resultado no painel Output e fecham.

**Rodar o teste do núcleo.** No FileSystem, abra `res://Magic_System.G/Tests/test_core_spell.tscn` com duplo clique. Com a cena aberta, aperte F6 (Run Current Scene). Olhe o painel Output: cada verificação aparece como `[ok]` ou `[FALHOU]`, e no fim há a linha `Resultado: N ok, M falhas`.

**Rodar o teste da extensão.** Mesmo processo com `Tests/extensions/test_shape_variants.tscn`.

**Se a cena reclamar de script ausente** (você moveu ou renomeou a pasta): abra a cena, clique no nó raiz, no Inspector em Script escolha Load e selecione o `.gd` de mesmo nome, depois salve.

**Para criar um teste novo.** Crie um script que herda de `TestCase` (`extends TestCase`), escreva as verificações com `check(condicao, "descrição")` dentro de `_ready()` e termine com `finish()`. Crie uma cena com um nó `Node` na raiz, anexe o script e rode com F6. Use `TestFactory` para montar peças rapidamente.

---

## 11. Cuidados e erros comuns

- **Chaves de custo e de atributo devem ser iguais em todos os lugares.** Se `"mana"` está no `SpellCost` e o seu dicionário usa `"Mana"`, a verificação falha. Se o seu dicionário usa `StringName`, converta nas pontes.
- **`class_name` duplicado.** Se aparecer erro de classe global repetida, há uma cópia antiga em outra pasta. Apague a antiga.
- **Arrays tipados.** Em `Elements`, `Effects` e `Variants`, use Add Element no Inspector e escolha o tipo na lista. Pelo código, use `.append(...)`.
- **Contexto incompleto.** Sem `stats`, os `StatValue` devolvem o `fallback`. Sem `payer`, não há cobrança. Isso é proposital.
- **`ProjectileShape` sem `launch`.** Se a cena do projétil não tiver o método `launch(spell, ctx)`, nada acontece além da instância ser criada.
- **`ShapeGroup` não tem custo nem prefixo próprios.** Esses campos existem por herança e são ignorados. Coloque custo e prefixo nas formas que o grupo escolhe.
- **Grupo sem saída.** Se nenhuma condição for verdadeira e não houver `fallback`, `resolve` devolve `null` e o `SpellBuilder` devolve `null` com um erro no Output.

---

## 12. SOLID no projeto

| Princípio | Onde aparece |
|---|---|
| **S** (responsabilidade única) | `SpellCost` só soma custos. `SpellNamer` só nomeia. `SpellBuilder` só monta. `SpellCaster` só cobra e dispara. Formas só entregam, elementos só definem o efeito. |
| **O** (aberto/fechado) | Formas, efeitos, fontes de valor, condições e nomeadores novos são arquivos novos. Nada existente é editado. |
| **L** (substituição de Liskov) | Qualquer `SpellShape` serve onde uma forma é esperada, inclusive o `ShapeGroup`. Qualquer `ValueSource` serve onde um número é esperado. |
| **I** (segregação de interfaces) | `StatProvider` e `CostPayer` são contratos separados e pequenos. O jogo implementa só o que precisa. |
| **D** (inversão de dependência) | O núcleo depende de abstrações (`StatProvider`, `CostPayer`, `SpellEffect`, `ValueSource`), nunca de classes do seu jogo. O `SpellBuilder` recebe o `SpellNamer` por parâmetro. |