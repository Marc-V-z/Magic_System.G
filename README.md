# Magic_System.G

Sistema de magia dinâmica para Godot 4 (GDScript), feito com composição de Resources e princípios SOLID.

Uma magia é montada em tempo de execução a partir de **partes**. Cada parte tem uma **forma** (COMO ela é entregue: projétil, rajada, em si mesmo...) e **elementos** (O QUE ela faz: efeitos, números, custos). Uma magia pode ter uma parte (uma bola de fogo) ou várias (um tiro triplo, com três projéteis de elementos diferentes). Custo, requisitos, poder, parâmetros e nome são calculados automaticamente.

O sistema é **lógica pura e não conhece nenhum tipo de jogo**. Ele guarda números e nomes que você define, e devolve esses mesmos números e nomes ao seu jogo, que decide o que significam. Um "alcance 3" pode ser 3 casas de uma grade, 3 vezes X pixels, ou "as cartas dos 3 slots de trás". O sistema nunca sabe qual.

> **Premissas deste manual**
> - Godot 4.x e GDScript.
> - GDScript não tem interfaces, então os "contratos" são classes base com métodos vazios que você sobrescreve.
> - Alvos e conjuradores são `Object` (Node, Resource, objeto de dados...). O `DamageEffect` usa "duck typing": chama `take_damage(valor)` se o alvo tiver esse método.
> - Os NOMES de parâmetros usados nos exemplos (`reach`, `size`, `angle`, `range`) são só exemplos. Você escolhe os nomes que quiser, desde que o seu jogo os entenda.
> - Custos (`SpellCost`) são números fixos por chave. Parâmetros, duração e poder são dinâmicos (`ValueSource`). Custos dinâmicos ficam como evolução futura.
> - Chaves de custo, atributo e tag são textos simples (`"mana"`, `"magic_power"`, `"equip:staff"`). Use sempre o mesmo texto em todos os lugares.
> - Os exemplos de código do seu jogo (busca de alvos, projéteis) são ilustrativos, para você adaptar.

## Sumário

**Parte 1. Guia para iniciantes**

1. [A ideia, contada como uma história](#1-a-ideia-contada-como-uma-história)
2. [Vocabulário](#2-vocabulário)
3. [As três fases da vida de uma magia](#3-as-três-fases-da-vida-de-uma-magia)
4. [O sistema não conhece o seu jogo: o tradutor](#4-o-sistema-não-conhece-o-seu-jogo-o-tradutor)
5. [Instalação](#5-instalação)
6. [Sua primeira magia, clique a clique](#6-sua-primeira-magia-clique-a-clique)
7. [Sua segunda magia: o tiro triplo, clique a clique](#7-sua-segunda-magia-o-tiro-triplo-clique-a-clique)
8. [Receita para criar qualquer magia nova](#8-receita-para-criar-qualquer-magia-nova)
9. [Do teste para o seu jogo de verdade](#9-do-teste-para-o-seu-jogo-de-verdade)

**Parte 2. Manual de referência**

10. [Estrutura de pastas](#10-estrutura-de-pastas)
11. [A especificação no código](#11-a-especificação-no-código)
12. [Referência dos arquivos](#12-referência-dos-arquivos)
13. [Regras de dependência e o que pode ser apagado](#13-regras-de-dependência-e-o-que-pode-ser-apagado)
14. [Custos e requisitos](#14-custos-e-requisitos)
15. [Parâmetros de área](#15-parâmetros-de-área)
16. [Projétil e rajada](#16-projétil-e-rajada)
17. [Magias com várias partes](#17-magias-com-várias-partes)
18. [Usando em cada tipo de jogo](#18-usando-em-cada-tipo-de-jogo)
19. [Fluxos](#19-fluxos)
20. [Entradas e saídas](#20-entradas-e-saídas)
21. [Como estender](#21-como-estender)
22. [Extensão opcional: variações de forma](#22-extensão-opcional-variações-de-forma)
23. [Testes](#23-testes)
24. [Cuidados e erros comuns](#24-cuidados-e-erros-comuns)
25. [SOLID no projeto](#25-solid-no-projeto)

---

# Parte 1. Guia para iniciantes

## 1. A ideia, contada como uma história

Imagine que você é o dono de uma cozinha e tem uma regra: **ninguém cozinha direto, tudo sai de uma receita escrita num papel**.

- Cada **receita** é uma magia. Ex.: "Tiro triplo".
- Uma receita é dividida em **etapas**. Cada etapa é uma **parte**. O tiro triplo tem 3 etapas, uma para cada projétil. A bola de fogo tem 1.
- Cada etapa diz **como** a coisa é feita (o **molde**, que chamamos de **forma**: "atirar um projétil", "explodir em volta") e **com o quê** (os **ingredientes**, que chamamos de **elementos**: "fogo", "gelo"). O elemento diz o que acontece: quanto de dano, qual efeito.
- Cada etapa também pode ter **anotações** com números e nomes: `ângulo: 30`, `alcance: 8`. Você inventa os nomes.
- Os **custos** (mana, vida, item) e as **exigências** (precisa de cajado, não pode estar silenciado) ficam anotados na receita e nas etapas. O sistema soma tudo sozinho.

Agora a parte mais importante: **o sistema é só quem lê a receita**. Ele NÃO sabe cozinhar no seu jogo. Quando uma etapa diz "alcance 3", ele não sabe se são 3 casas, 3 metros ou 3 cartas. Ele pega o número 3 e entrega ao seu jogo, dizendo: "aqui está o 3 que a receita pediu. Você sabe o que isso significa no seu jogo, então faça".

Quem faz o trabalho de verdade no seu jogo são uns ajudantes que você escreve, chamados **tradutores** (no código, **contratos**). Os mais comuns:

| Tradutor | Pergunta que o sistema faz ao seu jogo |
|---|---|
| `TargetFinder` | "Com estes números e rótulos, quem é atingido?" |
| `ProjectileLauncher` | "Realize um projétil com estes números. Me avise quando ele acertar." |
| `CostPayer` | "Este personagem consegue pagar este custo? Cobre dele." |
| `StatProvider` | "Qual é o valor do atributo `magic_power` deste personagem?" |
| `TagProvider` | "Este personagem tem a tag `equip:staff`?" |

Você só escreve os tradutores das coisas que usar. Uma magia que só aplica um efeito em si mesmo não precisa de nenhum.

---

## 2. Vocabulário

| Palavra | O que é | Exemplo |
|---|---|---|
| **Magia** (`SpellDefinition`) | A receita inteira. Um arquivo `.tres` que você edita no Inspector. | Tiro triplo |
| **Parte** (`SpellPart`) | Uma etapa da receita: uma forma, elementos e anotações. | O projétil a 30 graus |
| **Forma** (`SpellShape`) | COMO a parte é entregue. | Projétil, rajada, em si mesmo |
| **Elemento** (`SpellElement`) | O QUE a parte faz: número de poder, efeitos, custo, nome. | Fogo, gelo |
| **Efeito** (`SpellEffect`) | Algo que acontece com um alvo. | Causar dano |
| **Parâmetros** (`SpellArea`) | Anotações com nome: números e rótulos. | `range: 8`, `angle: 30`, rótulo `enemies` |
| **Custo** (`SpellCost`) | O que a magia gasta. | `mana: 5`, `hp: 2`, `item:pocao: 1` |
| **Requisito** (`SpellRequirement`) | O que o personagem precisa ter ou cumprir. | Cajado equipado |
| **ValueSource** | De onde vem um número: constante, atributo, poder da magia, conta. | `ConstantValue 10` |
| **Instância** (`SpellInstance`) | A receita já "preparada" para uso. Criada pelo `SpellBuilder`. | |
| **Contexto** (`SpellContext`) | Uma caixa com os dados do momento: quem conjura, onde está, para onde mira, e os tradutores. | |
| **Contrato / tradutor** | Uma classe sua que responde as perguntas do sistema. | `TargetFinder` |

---

## 3. As três fases da vida de uma magia

```
 FASE 1: CRIAR                FASE 2: MONTAR                FASE 3: CONJURAR
 (no editor, uma vez)         (no código, uma vez)          (no jogo, toda vez que usa)

 Você preenche arquivos       SpellBuilder lê a receita     O jogador aperta o botão.
 .tres no Inspector:          e prepara a magia:            Você monta o Contexto e chama
   elementos                    resolve as formas           SpellCaster.cast(...).
   formas                       soma custos                 O sistema confere requisitos
   a magia (partes)             soma requisitos             e custo, cobra, e dispara cada
                                dá nome                     parte, uma depois da outra.
        │                            │                           │
        ▼                            ▼                           ▼
   SpellDefinition  ──────►    SpellInstance   ──────►    Efeitos acontecem no seu jogo,
   (um arquivo .tres)          (um objeto na memória)     pelos seus tradutores
```

Na prática, no código do seu jogo:

```gdscript
# FASE 2 (faça uma vez, por exemplo no _ready)
var spell := SpellBuilder.new().build(minha_magia_definition)

# FASE 3 (faça toda vez que o jogador usar a magia)
var ctx := SpellContext.new()
ctx.caster = self
# ... preencher o resto do contexto ...
var resultado := SpellCaster.new().cast(spell, ctx)
```

---

## 4. O sistema não conhece o seu jogo: o tradutor

Esta é a parte que mais confunde, então vamos devagar.

Digamos que uma parte de magia tem a anotação `reach: 3`. O que significa `3`? **Depende do jogo. Quem decide é o seu tradutor.** Exemplos, todos usando exatamente o mesmo arquivo de magia:

| Seu jogo | O que o seu `TargetFinder` faz com `reach = 3` |
|---|---|
| RPG tático em grade | "3 casas": pega todas as unidades a até 3 casas da casa do conjurador. |
| Action RPG 2D | "3 vezes 32 pixels": faz uma consulta de física de 96 pixels. |
| Jogo de cartas | "Slots de trás": devolve as cartas dos 3 últimos slots do campo do oponente. |
| RPG por turnos | Ignora o número e devolve os alvos que o jogador escolheu na tela. |

Veja como seriam três tradutores, só para você ENXERGAR a ideia (código ilustrativo, o que está em `grid`, `battlefield` e `physics_world` é o seu jogo):

```gdscript
# Grade: "reach" são casas
class_name GridTargetFinder
extends TargetFinder

func find_targets(area: ResolvedArea, ctx: SpellContext) -> Array:
	var tiles := int(area.get_number(&"reach"))
	var origin_cell: Vector2i = area.origin
	return grid.units_within(origin_cell, tiles)
```

```gdscript
# Action 2D: "reach" é multiplicado por um tamanho de tile em pixels
class_name PixelTargetFinder
extends TargetFinder

const PIXELS_PER_UNIT := 32.0

func find_targets(area: ResolvedArea, ctx: SpellContext) -> Array:
	var pixels := area.get_number(&"reach") * PIXELS_PER_UNIT
	return physics_world.bodies_within(area.origin, pixels)
```

```gdscript
# Cartas: "reach" são slots, e o rótulo "back_row" restringe à retaguarda
class_name CardTargetFinder
extends TargetFinder

func find_targets(area: ResolvedArea, ctx: SpellContext) -> Array:
	var slots := int(area.get_number(&"reach"))
	var only_back := area.has_label(&"back_row")
	return battlefield.cards_in_slots(slots, only_back)
```

Repare: o `ResolvedArea` que chega ao tradutor tem sempre as mesmas peças genéricas:

| Peça | O que é |
|---|---|
| `area.get_number(&"nome", padrão)` | Um número com nome, já calculado. |
| `area.has_label(&"rótulo")` | Um rótulo solto (`enemies`, `back_row`, `ground`...). |
| `area.origin` | O ponto de partida. Qualquer tipo que o seu jogo usar: `Vector2`, `Vector3`, `Vector2i`, um slot. |
| `area.direction` | A direção da mira, se o seu jogo tiver essa ideia. |

O sistema nunca olha dentro desses nomes. O nome `reach` foi inventado aqui. Se no seu jogo fizer mais sentido `casas`, `alcance` ou `slots`, use esses, é só combinar com o seu tradutor.

---

## 5. Instalação

Passo 1. Pelo gerenciador de arquivos do seu sistema (Explorador de Arquivos, Finder...), copie a pasta `Magic_System.G` inteira para dentro da pasta do seu projeto Godot, no mesmo nível do arquivo `project.godot`. O Godot pode ficar aberto.

Passo 2. Se você já tinha uma versão anterior destas classes em outra pasta do projeto, apague essa pasta antiga pelo painel FileSystem (clique direito, Delete) ANTES de voltar ao editor. Duas pastas com a mesma `class_name` causam o erro de classe global repetida.

Passo 3. Volte ao Godot e espere a barra de progresso de importação terminar. O painel FileSystem (canto inferior esquerdo) passa a mostrar `res://Magic_System.G/`.

Passo 4. Abra o painel Output (parte de baixo da janela) e confirme que não há erros vermelhos. Os scripts usam `class_name`, então todas as classes ficam disponíveis em qualquer script, sem `preload`.

> Os testes apontam para `res://Magic_System.G/Tests/...`. Se você renomear ou mover a pasta, só as cenas `.tscn` de teste precisam ser reanexadas (seção 23).

---

## 6. Sua primeira magia, clique a clique

Objetivo: criar a magia **Marca de fogo**, que causa 10 de dano em quem a conjura. É a magia mais simples possível: não precisa de nenhum tradutor. Vamos vê-la funcionar no painel Output.

### Etapa A. Criar uma pasta para os seus arquivos

No painel FileSystem, clique com o botão direito em `res://` (o nome do projeto), escolha **Create New** e depois **Folder**. Digite `magic_demo` e confirme. Tudo o que você criar neste guia fica nessa pasta, FORA de `Magic_System.G` (a pasta do sistema nunca recebe arquivos seus).

### Etapa B. Criar o elemento "fogo"

1. Clique com o botão direito na pasta `magic_demo`, escolha **Create New** e depois **Resource**.
2. Na janela que abrir, digite `SpellElement` na caixa de busca, clique em `SpellElement` na lista e confirme em **Create**.
3. Na janela seguinte, digite o nome `fogo` (vira `fogo.tres`) e confirme em **Save**.
4. Dê duplo clique em `fogo.tres`. As propriedades aparecem no painel **Inspector** (lado direito).
5. No campo **Display Name** escreva `fogo`.
6. No campo **Power** (que está vazio), clique nele e escolha **New ConstantValue**. Clique no valor que apareceu para expandi-lo e, em **Value**, digite `10`. Isso quer dizer "o poder do fogo é 10".
7. No campo **Effects**, clique no título para expandir, depois no botão **Add Element**. Aparece um espaço vazio: clique nele e escolha **New DamageEffect**. Isso quer dizer "este elemento causa dano".
8. Deixe tudo o resto como está. Salve com Ctrl+S.

### Etapa C. Criar a forma "em si mesmo"

1. Botão direito na pasta `magic_demo`, **Create New**, **Resource**.
2. Busque `SelfShape`, crie e salve como `marca`.
3. Dê duplo clique em `marca.tres`. No campo **Name Prefix** escreva `Marca de`. Salve.

Pronto: essa forma faz a magia atingir o próprio conjurador. O nome automático da magia será "Marca de" mais o nome do elemento.

### Etapa D. Criar a magia

1. Botão direito na pasta `magic_demo`, **Create New**, **Resource**, busque `SpellDefinition`, crie e salve como `marca_de_fogo`.
2. Dê duplo clique em `marca_de_fogo.tres`.
3. Clique no título do campo **Parts** para expandi-lo e depois em **Add Element**.
4. Clique no espaço vazio que apareceu e escolha **New SpellPart**. Clique na parte criada para expandi-la.
5. No campo **Shape** da parte, arraste o arquivo `marca.tres` do painel FileSystem e solte em cima do campo. (Se preferir, clique no campo, escolha **Quick Load** e selecione `marca.tres`.)
6. Ainda dentro da parte, expanda **Elements**, clique em **Add Element** e arraste `fogo.tres` para o espaço novo.
7. Deixe **Custom Name** vazio (assim o nome sai automático). Salve.

Você acabou de escrever a receita: uma parte, com a forma "marca" e o elemento "fogo".

### Etapa E. Criar o script de teste

1. Dentro de `magic_demo`, clique com o botão direito, **Create New**, **Script**. Em **Path** deixe `res://magic_demo/spell_demo.gd`. Em **Template** escolha **Empty** (se não houver, apague tudo o que o Godot escrever). Clique em **Create**.
2. Apague o conteúdo do arquivo e cole:

```gdscript
extends Node

@export var definition: SpellDefinition

var hp: float = 100.0

func take_damage(amount: float) -> void:
	hp -= amount
	print("Recebi ", amount, " de dano. Vida agora: ", hp)

func _ready() -> void:
	# FASE 2: montar a magia
	var spell := SpellBuilder.new().build(definition)
	if spell == null:
		print("A magia não pôde ser montada. Veja o erro no Output.")
		return
	print("Nome da magia: ", spell.display_name)

	# FASE 3: conjurar
	var ctx := SpellContext.new()
	ctx.caster = self
	ctx.launcher = PrintProjectileLauncher.new(self)
	var result := SpellCaster.new().cast(spell, ctx)
	print("Resultado (0 significa OK): ", result)
```

3. Crie outro script na mesma pasta, `print_projectile_launcher.gd`, com o conteúdo abaixo. Ele é um "tradutor de projéteis de mentira", só para você ver os projéteis aparecerem no Output (vamos usá-lo na próxima magia):

```gdscript
class_name PrintProjectileLauncher
extends ProjectileLauncher

var target: Object

func _init(demo_target: Object) -> void:
	target = demo_target

func launch(request: ProjectileRequest) -> void:
	print("Projétil '", request.projectile_id, "' saiu com os parâmetros ", request.area.numbers)
	var impact := ProjectileImpact.new()
	impact.point = Vector2.ZERO
	impact.targets = [target]
	impact.is_end = true
	request.on_impact.call(impact)
```

4. Salve os dois (Ctrl+S).

### Etapa F. Criar a cena e rodar

1. Menu **Scene**, **New Scene**. Em **Other Node**, escolha **Node** e crie.
2. Clique com o botão direito no nó, **Attach Script**, clique no ícone de pasta, escolha `spell_demo.gd` e confirme em **Attach**.
3. Com o nó selecionado, olhe o Inspector: apareceu o campo **Definition**. Arraste `marca_de_fogo.tres` para ele.
4. Salve a cena (Ctrl+S) como `spell_demo.tscn`.
5. Aperte **F6** (Run Current Scene).

Uma janela vazia abre. O que importa está no painel **Output**. Você deve ver algo parecido com:

```
Nome da magia: Marca de fogo
Recebi 10 de dano. Vida agora: 90
Resultado (0 significa OK): 0
```

(Os números podem aparecer como `10.0` e `90.0`.) Feche a janela do jogo.

### O que acabou de acontecer

1. `SpellBuilder.build` leu a receita `marca_de_fogo`, viu que ela tem 1 parte com a forma `marca` e o elemento `fogo`, e criou o nome: prefixo da forma ("Marca de") mais o nome do elemento ("fogo") deu "Marca de fogo".
2. `SpellCaster.cast` conferiu requisitos (nenhum) e custo (nenhum, não há `CostPayer`) e disparou a parte.
3. A forma `SelfShape` aplicou a parte no `ctx.caster`, que é o próprio nó `Demo`.
4. O elemento `fogo` tem poder 10 e um `DamageEffect`. O efeito chamou `take_damage(10)` no nó. Por isso a vida foi de 100 para 90.

Se algo deu errado, veja a seção 24.

---

## 7. Sua segunda magia: o tiro triplo, clique a clique

Objetivo: criar o **Tiro triplo**: 3 projéteis, um reto (ângulo 0), um a +30 e um a -30, cada um com seu elemento (fogo, gelo, raio). Isso mostra as **partes**, os **parâmetros** e a diferença entre o sistema e o seu jogo.

### Etapa A. Criar os elementos que faltam

Repita a Etapa B da seção 6 duas vezes:

- `gelo.tres`: **Display Name** `gelo`, **Power** `New ConstantValue` com **Value** `5`, e um `DamageEffect` em **Effects**.
- `raio.tres`: **Display Name** `raio`, **Power** `New ConstantValue` com **Value** `7`, e um `DamageEffect` em **Effects**.

O `fogo.tres` você já tem (poder 10).

### Etapa B. Criar a forma "projétil"

1. Botão direito em `magic_demo`, **Create New**, **Resource**, busque `ProjectileShape`, crie e salve como `tiro`.
2. Dê duplo clique em `tiro.tres` e preencha:
   - **Name Prefix**: `Tiro de`
   - **Projectile Id**: `tiro` (é um nome que o seu jogo usa para escolher qual cena de projétil usar)
   - **Area**: clique no campo vazio e escolha **New SpellArea**. Expanda-o. Em **Numbers**, expanda e clique em **Add Element**. Clique no espaço novo e escolha **New NamedValue**. Expanda-o. Em **Key** escreva `range`. Em **Value** escolha **New ConstantValue** e, em **Value** dele, digite `8`.
3. Salve.

Essa forma diz: "todo projétil que usar este molde tem `range: 8`". O nome `range` foi inventado: o seu jogo é quem decide o que 8 significa.

### Etapa C. Criar a magia com 3 partes

1. Crie um `SpellDefinition` chamado `tiro_triplo` (botão direito em `magic_demo`, **Create New**, **Resource**, `SpellDefinition`).
2. Em **Custom Name** escreva `Tiro triplo`.
3. Expanda **Parts** e clique **Add Element** três vezes. Em cada espaço vazio escolha **New SpellPart**.
4. Expanda a **primeira** parte e preencha:
   - **Shape**: arraste `tiro.tres`.
   - **Elements**: **Add Element** e arraste `fogo.tres`.
   - **Area**: **New SpellArea**, expanda, em **Numbers** **Add Element**, **New NamedValue**, **Key** = `angle`, **Value** = **New ConstantValue** com **Value** `0`.
5. Expanda a **segunda** parte e preencha igual, trocando: **Elements** = `gelo.tres` e o `angle` com **Value** `30`.
6. Expanda a **terceira** parte e preencha igual, trocando: **Elements** = `raio.tres` e o `angle` com **Value** `-30`.
7. Salve.

Resumo do que você montou: três partes que usam a MESMA forma `tiro.tres`, cada uma com seu elemento e seu `angle`. O `angle` da parte é somado aos números da forma (`range: 8` vale para as três).

### Etapa D. Rodar

1. Abra a cena `spell_demo.tscn`, clique no nó e, no campo **Definition**, arraste `tiro_triplo.tres` no lugar da magia anterior.
2. Aperte F6. No Output você deve ver algo parecido com:

```
Nome da magia: Tiro triplo
Projétil 'tiro' saiu com os parâmetros { &"range": 8.0, &"angle": 0.0 }
Recebi 10 de dano. Vida agora: 90
Projétil 'tiro' saiu com os parâmetros { &"range": 8.0, &"angle": 30.0 }
Recebi 5 de dano. Vida agora: 85
Projétil 'tiro' saiu com os parâmetros { &"range": 8.0, &"angle": -30.0 }
Recebi 7 de dano. Vida agora: 78
Resultado (0 significa OK): 0
```

### O que acabou de acontecer

1. `SpellBuilder.build` criou uma parte pronta para cada uma das 3 partes da receita, juntando os parâmetros da forma (`range: 8`) com os da parte (`angle: ...`).
2. `SpellCaster.cast` conferiu custo e requisitos UMA vez para a magia inteira e depois disparou as partes em ordem.
3. Para cada parte, a forma `ProjectileShape` chamou o tradutor de projéteis (`ProjectileLauncher`), entregando os parâmetros (`range` e `angle`) e o `projectile_id`.
4. O nosso tradutor de mentira só imprimiu os números e avisou "acertou o nó Demo". Como não há `DestroyAction` configurada, o padrão (aplicar efeitos e destruir) rodou, e cada parte aplicou o SEU elemento: 10, 5 e 7 de dano.
5. Num jogo de verdade, o seu `ProjectileLauncher` criaria projéteis voando (em 2D, 3D, na grade, em cartas...), e usaria o número `angle` como quiser: graus, uma faixa lateral, um deslocamento de coluna.

O sistema nunca soube o que `angle` ou `range` significam. Ele só os carregou da receita até o seu jogo.

### Variações para você experimentar

- Troque o `Custom Name` por vazio: o nome automático vira "Tiro de fogo e Tiro de gelo e Tiro de raio".
- Troque os três elementos por `fogo.tres`: o nome vira "Tiro de fogo (x3)".
- Se quiser um leque com mais projéteis, não precisa criar 9 partes à mão. Gere por código:

```gdscript
func make_fan(shape: SpellShape, element: SpellElement, count: int, spread: float) -> SpellDefinition:
	var definition := SpellDefinition.new()
	for i in count:
		var angle_value := ConstantValue.new()
		angle_value.value = (i - (count - 1) / 2.0) * spread
		var angle := NamedValue.new()
		angle.key = &"angle"
		angle.value = angle_value
		var area := SpellArea.new()
		area.numbers.append(angle)
		var part := SpellPart.new()
		part.shape = shape
		part.elements.append(element)
		part.area = area
		definition.parts.append(part)
	return definition
```

---

## 8. Receita para criar qualquer magia nova

Siga sempre esta ordem. Marque cada item.

1. **Pense em partes.** Quantas coisas distintas essa magia faz? Uma bola de fogo: 1 parte. Um tiro triplo: 3 partes. Uma explosão que depois solta estilhaços: 1 parte com uma ação de impacto que reconjura (seção 16).
2. **Para cada parte, escolha a forma.** `SelfShape` (em si mesmo), `ProjectileShape` (projétil), `BurstShape` (rajada ou explosão), ou uma forma sua (seção 21).
3. **Para cada parte, escolha os elementos.** Se um elemento vale para TODAS as partes, coloque-o em `Elements` da própria magia (ele conta uma vez só no custo). Se vale para só uma, coloque em `Elements` da parte.
4. **Crie os elementos** (`SpellElement`): `Display Name`, `Power` (de onde vem o número), `Effects` (o que acontece), e opcionalmente `Cost`, `Tags`, `Requirements`.
5. **Crie as formas** (`SpellShape`): `Name Prefix` (para o nome automático), `Power Multiplier`, `Anchor` (nasce no conjurador ou no ponto mirado), e os parâmetros da forma em `Area` (números e rótulos que o seu jogo entende).
6. **Ajuste por parte, se precisar.** Em `Area` da parte, escreva só o que muda (por exemplo o `angle`). O resto vem da forma. Quando o nome é igual, o da parte vence.
7. **Crie a magia** (`SpellDefinition`): `Parts`, `Elements` compartilhados, `Custom Name` (vazio = automático), e `Cost` e `Requirements` da magia inteira se quiser.
8. **Descubra os custos.** O custo final é a soma de: custo da magia + elementos compartilhados (uma vez) + forma de CADA parte + elementos de cada parte. Se uma forma é repetida em 3 partes, o custo dela conta 3 vezes. Se quiser um custo fixo, coloque-o na magia e deixe a forma sem custo.
9. **Teste** (a cena da seção 6) antes de ligar no jogo. Confira nome, custo e o que o seu tradutor recebe.

---

## 9. Do teste para o seu jogo de verdade

Na seção 6 você viu o ciclo completo com um tradutor de mentira. Para usar no jogo de verdade:

**Passo 1. Decida o que cada nome significa no seu jogo.** Faça uma lista curta. Exemplo: `reach` = casas, `size` = raio em casas, `angle` = graus, rótulo `enemies` = só inimigos.

**Passo 2. Escreva só os tradutores de que as suas magias precisam.**

| Se a sua magia usa | Escreva |
|---|---|
| Custo (`Cost`) | `CostPayer` |
| `StatValue` ou `StatAtLeastRequirement` | `StatProvider` |
| `TagRequirement` | `TagProvider` |
| `BurstShape`, ou `ApplyEffectsAction` com `impact_area` | `TargetFinder` |
| `ProjectileShape` | `ProjectileLauncher` |
| `BurstShape` com `Instant` desligado | `SustainedAreaRunner` |

Coloque esses arquivos numa pasta do SEU jogo (por exemplo `res://game/magic/`), nunca dentro de `Magic_System.G`. Exemplos prontos de `StatProvider`, `CostPayer` e `TagProvider`:

```gdscript
class_name PlayerStats
extends StatProvider

var player: Node

func _init(p: Node) -> void:
	player = p

func get_stat(key: StringName, default_value: float = 0.0) -> float:
	return player.stats.get(String(key), default_value)
```

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

```gdscript
class_name PlayerTags
extends TagProvider

var player: Node

func _init(p: Node) -> void:
	player = p

func has_tag(tag: StringName) -> bool:
	return player.tags.has(String(tag))
```

Aqui `player.stats`, `player.resources` e `player.tags` são dados do SEU personagem. Troque pelo que o seu jogo tiver.

**Passo 3. Monte as magias uma vez.** Por exemplo, no `_ready` do jogador, para cada `SpellDefinition` que ele conhece, chame `SpellBuilder.new().build(definition)` e guarde o `SpellInstance` numa lista.

**Passo 4. Quando o jogador usar a magia, monte o contexto.**

```gdscript
var ctx := SpellContext.new()
ctx.caster = self
ctx.stats = PlayerStats.new(self)
ctx.tags = PlayerTags.new(self)
ctx.payer = PlayerPayer.new(self)
ctx.finder = meu_target_finder
ctx.launcher = meu_projectile_launcher
ctx.origin = global_position                         # o que "origem" significar no seu jogo
ctx.direction = meu_calculo_de_direcao               # opcional
ctx.aim_point = ponto_ou_alvo_mirado                 # opcional
```

Preencha só o que o seu jogo e as suas magias usam. Tudo é opcional.

**Passo 5. Conjure e trate o resultado.**

```gdscript
var caster := SpellCaster.new()

# Opcional: só perguntar, sem cobrar nada (bom para habilitar botões ou destacar cartas)
var pode := caster.can_cast(spell, ctx) == SpellCaster.Result.OK

var resultado := caster.cast(spell, ctx)
match resultado:
	SpellCaster.Result.OK:
		pass   # a magia foi disparada
	SpellCaster.Result.REQUIREMENT_NOT_MET:
		print(spell.find_unmet_requirement(ctx).failure_message)
	SpellCaster.Result.CANNOT_PAY:
		print("Recursos insuficientes")
```

**Passo 6. Em caso de dúvida, volte ao teste da seção 6** e troque o tradutor de mentira pelo seu, um de cada vez.

---

# Parte 2. Manual de referência

## 10. Estrutura de pastas

```
Magic_System.G/
├── README.md
├── scripts/                          Código real do sistema
│   ├── core/                         Peças fundamentais de uma magia
│   │   ├── components/               Forma, elemento, efeito, instância, parte pronta
│   │   ├── area/                     Parâmetros descritos e parâmetros calculados
│   │   ├── requirements/             Base de requisitos
│   │   ├── cost/                     Custos
│   │   ├── values/                   Números (ValueSource) e números com nome
│   │   └── contracts/                Pontes com o jogo (os "tradutores")
│   │       └── requests/             Pedidos e resultados trocados com o jogo
│   ├── building/                     Construção: receita, parte da receita, construtor, nomeador
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
    └── test_*.gd / .tscn             Testes do núcleo, requisitos, áreas e partes
```

- **core**: o que uma magia É. Não conhece construtores, execução, biblioteca nem extensões.
- **building**: como uma magia é MONTADA a partir de uma receita.
- **casting**: como uma magia pronta é DISPARADA.
- **library**: formas, ações, requisitos e efeitos concretos prontos. Podem ser trocados ou apagados.
- **extensions**: funcionalidades extras. Apagar uma pasta daqui não quebra nada no resto.
- **Tests**: nada em `scripts` depende desta pasta. Pode ser apagada inteira.

---

## 11. A especificação no código

| Na especificação | Onde está |
|---|---|
| **Nome da magia** | `SpellDefinition.custom_name`. Se vazio, `SpellNamer` junta, para cada parte, `SpellShape.name_prefix` + `SpellElement.display_name`. Partes iguais viram "(xN)". |
| **Custo** (mágico, hp, item...) | `SpellCost` na magia, nos elementos e nas formas, somados pelo `SpellBuilder`. Chaves livres: `mana`, `hp`, `item:pocao`. O `CostPayer` do jogo decide o significado. |
| **Requisitos** (equipamentos, estados...) | `SpellRequirement` na magia, nos elementos e nas formas. Prontos: `TagRequirement` e `StatAtLeastRequirement`. |
| **Composição** | `SpellDefinition`: `parts` (cada `SpellPart` com `shape` e `elements`) e `elements` compartilhados. |
| **Mais de um projétil** | Uma parte por projétil. Cada parte tem a sua forma, os seus elementos e os seus parâmetros. |
| **Forma**: tipo | Subclasses de `SpellShape`: `ProjectileShape`, `BurstShape`, `SelfShape`, ou a sua. |
| **Forma**: onde é conjurado | `SpellShape.anchor`: `CASTER` (no usuário, padrão) ou `AIM_POINT` (no ponto mirado). |
| **Forma**: efeito | `SpellShape.effects`, somados aos efeitos dos elementos. |
| **Distância, raio, direção, ângulo...** | NÃO são campos fixos. São números nomeados e rótulos em `SpellArea` (na forma e na parte), cada número um `ValueSource`. Quem interpreta é o seu jogo. |
| **Projétil**: colisão do início ao fim | `ProjectileShape.collide_along_path`. |
| **Projétil**: efeito ao acertar | `ProjectileShape.impact_actions`: `ApplyEffectsAction`, `RecastAction`, `DestroyAction`. |
| **Rajada**: instantânea ou não | `BurstShape.instant` (mais `duration` e `tick_interval`). |
| **Nada travado** | Todo número é `ValueSource`: constante, atributo do conjurador (`StatValue`), poder da parte (`SpellPowerValue`) ou conta (`ProductValue`). |

---

## 12. Referência dos arquivos

### scripts/core/components

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_component.gd` | `SpellComponent` | Base de forma e elemento: `cost`, `tags`, `requirements`. |
| `spell_shape.gd` | `SpellShape` | Base de formas: `name_prefix`, `power_multiplier`, `anchor`, `area` (parâmetros padrão), `effects`, `resolve(elements)`, `cast(part, ctx)`, `get_origin(ctx)`. |
| `spell_element.gd` | `SpellElement` | Elemento: `display_name`, `power` (um `ValueSource`), `effects`. |
| `spell_effect.gd` | `SpellEffect` | Base de efeitos: `apply(target, power, ctx)`. |
| `spell_part_instance.gd` | `SpellPartInstance` | Parte pronta: forma resolvida, elementos (compartilhados + próprios), parâmetros já combinados. Calcula poder (`compute_power`) e aplica efeitos (`apply_to`). |
| `spell_instance.gd` | `SpellInstance` | Magia pronta: `display_name`, `parts`, `cost`, `requirements`. `find_unmet_requirement(ctx)`. |

### scripts/core/area

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_area.gd` | `SpellArea` | Parâmetros descritos: `numbers` (lista de `NamedValue`) e `labels`. `resolve(ctx, origem)` calcula. `SpellArea.merged(base, override)` junta duas. |
| `resolved_area.gd` | `ResolvedArea` | Parâmetros calculados: `origin`, `direction`, `numbers`, `labels`. `get_number(nome, padrão)`, `has_number`, `has_label`, `is_empty`, `moved_to(ponto)`. |

### scripts/core/requirements e cost

| Arquivo | Classe | Resumo |
|---|---|---|
| `requirements/spell_requirement.gd` | `SpellRequirement` | Base: `is_met(ctx)` e `failure_message`. |
| `cost/spell_cost.gd` | `SpellCost` | Dicionário `amounts` e `merged_with(outro)`, que soma sem alterar os originais. |

### scripts/core/values

| Arquivo | Classe | Resumo |
|---|---|---|
| `value_source.gd` | `ValueSource` | Base: `get_value(ctx)`. Atalho estático `ValueSource.read(fonte, ctx, padrão)`, seguro para fonte nula. |
| `constant_value.gd` | `ConstantValue` | Número fixo. |
| `stat_value.gd` | `StatValue` | Atributo do conjurador (via `StatProvider`) vezes uma escala, com `fallback`. |
| `product_value.gd` | `ProductValue` | Multiplica dois `ValueSource`. |
| `spell_power_value.gd` | `SpellPowerValue` | Poder da parte em execução vezes uma escala. Não usar dentro de `element.power`. |
| `named_value.gd` | `NamedValue` | Um número com nome (`key` e `value`), usado em `SpellArea.numbers`. |

### scripts/core/contracts

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_context.gd` | `SpellContext` | Dados da conjuração e as pontes com o jogo. `derive(ponto)` cria um contexto filho para reconjurar. |
| `stat_provider.gd` | `StatProvider` | Contrato: `get_stat(chave, padrão)`. |
| `tag_provider.gd` | `TagProvider` | Contrato: `has_tag(tag)`. |
| `cost_payer.gd` | `CostPayer` | Contrato: `can_pay(custo)` e `pay(custo)`. |
| `target_finder.gd` | `TargetFinder` | Contrato: `find_targets(area, ctx)` devolve quem é atingido. |
| `projectile_launcher.gd` | `ProjectileLauncher` | Contrato: `launch(request)` realiza o projétil e avisa cada impacto. |
| `sustained_area_runner.gd` | `SustainedAreaRunner` | Contrato: `start(request)` repete a área ao longo do tempo. |
| `requests/projectile_request.gd` | `ProjectileRequest` | Pedido ao launcher: parte, contexto, parâmetros, `projectile_id`, `collide_along_path`, `on_impact`. |
| `requests/projectile_impact.gd` | `ProjectileImpact` | Um impacto: `point`, `targets`, `is_end`, `destroyed`. |
| `requests/sustained_request.gd` | `SustainedRequest` | Pedido ao runner: parte, contexto, parâmetros, `duration`, `tick_interval`, `on_tick`. |

### scripts/building

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_definition.gd` | `SpellDefinition` | Receita: `custom_name`, `parts`, `elements` (compartilhados), `cost`, `requirements`. |
| `spell_part.gd` | `SpellPart` | Parte da receita: `shape`, `elements` (próprios) e `area` (parâmetros que sobrescrevem os da forma). |
| `spell_builder.gd` | `SpellBuilder` | `build(definition)`: resolve as formas, junta elementos e parâmetros por parte, soma custos e requisitos, dá nome. Aceita um `SpellNamer` próprio. |
| `spell_namer.gd` | `SpellNamer` | Nome: `custom_name` se existir, senão o nome de cada parte (prefixo da forma + elementos), agrupando partes iguais. |

### scripts/casting

| Arquivo | Classe | Resumo |
|---|---|---|
| `spell_caster.gd` | `SpellCaster` | `can_cast` (só verifica), `cast` (verifica, cobra uma vez e dispara todas as partes), `fire` (dispara sem verificar nem cobrar). Devolve `SpellCaster.Result`. |

### scripts/library

| Arquivo | Classe | Resumo |
|---|---|---|
| `shapes/self_shape.gd` | `SelfShape` | Aplica a parte no próprio conjurador. |
| `shapes/burst_shape.gd` | `BurstShape` | Rajada ou explosão, instantânea ou ao longo do tempo. |
| `shapes/projectile_shape.gd` | `ProjectileShape` | Projétil realizado pelo `ProjectileLauncher` do jogo. Tem `impact_area` e `impact_actions`. |
| `impact/impact_action.gd` | `ImpactAction` | Base das ações de impacto. |
| `impact/apply_effects_action.gd` | `ApplyEffectsAction` | Aplica os efeitos nos alvos diretos, ou nos alvos que o `TargetFinder` devolver para a `impact_area`. |
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
| `support/test_factory.gd` | Atalhos para montar custos, parâmetros, formas, elementos, partes, definições e contexto. |
| `support/test_dummy.gd` | Personagem falso com `hp`, `stats`, `resources`, `take_damage`. |
| `support/test_stats.gd`, `test_payer.gd`, `test_tags.gd` | Implementações de teste de `StatProvider`, `CostPayer`, `TagProvider`. |
| `support/test_finder.gd`, `test_launcher.gd`, `test_sustained_runner.gd` | Implementações de teste de `TargetFinder`, `ProjectileLauncher`, `SustainedAreaRunner`. |
| `support/test_recording_shape.gd` | Forma de teste que conta conjurações. |
| `test_core_spell.gd` e `.tscn` | Custo somado, nomes (inclusive com várias partes), elementos compartilhados, conjuração, falta de recursos. |
| `test_requirements.gd` e `.tscn` | Requisitos de tag e atributo, soma de requisitos e bloqueio da conjuração. |
| `test_area_shapes.gd` e `.tscn` | Parâmetros nomeados genéricos, âncora, rajada instantânea e sustentada, herança de parâmetros da parte, projétil, ações de impacto, reconjuração e tiro triplo. |
| `extensions/test_shape_variants.gd` e `.tscn` | Grupo de formas. Apague junto com a extensão. |

---

## 13. Regras de dependência e o que pode ser apagado

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
| `library/impact/` | Some o efeito ao acertar. Apague também `projectile_shape.gd`, que usa `ApplyEffectsAction` e `DestroyAction` como padrão. |
| `library/shapes/burst_shape.gd` ou `projectile_shape.gd` | Some aquela forma. Nada mais depende delas, só o `RecastAction` precisa de uma forma para reconjurar. |
| `library/requirements/` | Somem os requisitos prontos. O núcleo continua aceitando os seus. |
| `core/contracts/target_finder.gd`, `projectile_launcher.gd`, `sustained_area_runner.gd` e `requests/` | Só se você apagar também `burst_shape.gd`, `projectile_shape.gd` e `library/impact/`. Num jogo sem áreas nem projéteis (por exemplo, cartas que só aplicam efeitos), `SelfShape` e formas suas bastam. |

---

## 14. Custos e requisitos

**Custos.** O custo final de uma magia é a soma de: custo da própria magia, custo dos elementos compartilhados (uma vez), custo da forma de cada parte e custo dos elementos de cada parte. O `SpellBuilder` soma chave por chave: forma `mana 5` + elemento `mana 2, hp 2` = `mana 7, hp 2`. Itens também são custos: use uma chave como `item:pocao` com valor `1` e deixe o seu `CostPayer` consumir o item do inventário. O sistema nunca sabe o que "mana", "hp" ou "item:pocao" significam. O custo é cobrado UMA vez por conjuração, não por parte.

**Requisitos.** Seguem a mesma regra de soma. Todos precisam estar cumpridos. Equipamentos e estados entram como tags: o seu `TagProvider` responde `true` para `equip:staff` quando o cajado está equipado, e para `state:silenced` quando o personagem está silenciado.

| Quero exigir | Requisito |
|---|---|
| Cajado equipado | `TagRequirement`, `tag` = `equip:staff`, `must_have` ligado |
| Não estar silenciado | `TagRequirement`, `tag` = `state:silenced`, `must_have` desligado |
| Nível 5 ou mais | `StatAtLeastRequirement`, `stat_key` = `level`, `minimum` = `5` |

Cada requisito tem `failure_message`, útil para mostrar ao jogador por que a magia não saiu. A ordem de verificação do `SpellCaster` é: a magia tem partes, requisitos, custo. Só depois cobra e dispara.

---

## 15. Parâmetros de área

`SpellArea` é uma lista de **números nomeados** e **rótulos**. Não existe nenhum campo fixo como "distância" ou "raio": **você inventa os nomes** e o seu jogo os interpreta.

| Peça | Significado |
|---|---|
| `numbers` | Lista de `NamedValue` (`key` + `value`). Cada `value` é um `ValueSource`. |
| `labels` | Lista de rótulos soltos (`&"enemies"`, `&"back_row"`...). |

Onde ficam: em `SpellShape.area` (padrão da forma), em `SpellPart.area` (ajustes da parte) e em `ProjectileShape.impact_area` (parâmetros do efeito no impacto).

**Combinação.** O `SpellBuilder` junta `SpellShape.area` com `SpellPart.area`: números com o mesmo nome valem os da parte, números novos são somados à lista, rótulos são unidos. A forma original nunca é alterada, então a mesma forma serve em várias partes.

**Cálculo.** Na conjuração, `SpellArea.resolve(ctx, origem)` calcula cada `ValueSource` com o contexto atual e devolve uma `ResolvedArea`. Como cada número é um `ValueSource`, ele pode vir de:

| De onde | Como |
|---|---|
| Número fixo | `ConstantValue` |
| Atributo do conjurador | `StatValue` |
| Atributo vezes constante | `ProductValue` |
| Poder da parte | `SpellPowerValue` |
| Algo seu | Uma subclasse sua de `ValueSource` |

**Origem e direção.** `ResolvedArea.origin` vem da âncora da forma: `CASTER` usa `ctx.origin` e `AIM_POINT` usa `ctx.aim_point`. `ResolvedArea.direction` vem de `ctx.direction`. Todos são `Variant`, então servem para `Vector2`, `Vector3`, célula de grade, slot de carta ou o que o seu jogo usar.

**Quem interpreta.** O seu `TargetFinder` e o seu `ProjectileLauncher` recebem a `ResolvedArea` e usam `get_number`, `has_label`, `origin` e `direction` como quiserem (seção 4).

---

## 16. Projétil e rajada

### ProjectileShape

| Campo | Significado |
|---|---|
| `projectile_id` | Identificador que o seu jogo usa para escolher a cena, a animação ou a carta. |
| `collide_along_path` | Ligado: colide em todo o trajeto. Desligado: só vale o impacto no fim. |
| `area` (herdado) | Parâmetros do trajeto. Cada parte pode ajustar. |
| `impact_area` | Parâmetros do efeito no impacto. Vazio: só os alvos atingidos diretamente. |
| `impact_actions` | Lista, em ordem, do que fazer a cada impacto. Vazio: aplicar efeitos e destruir. |

**Ações de impacto:**

| Ação | O que faz |
|---|---|
| `ApplyEffectsAction` | Aplica os efeitos da parte. Se a forma tem `impact_area` e `use_impact_area` está ligado, pergunta ao `TargetFinder` quem é atingido por essa área centrada no ponto de impacto. Senão, usa os alvos diretos. |
| `RecastAction` | Conjura outra `SpellDefinition` a partir do ponto de impacto, sem custo e sem requisitos. `max_depth` (padrão 3) impede laço infinito. |
| `DestroyAction` | Marca o projétil como destruído, e o launcher para de movê-lo. |

Sem `DestroyAction` na lista, o projétil continua depois do impacto (atravessa).

### BurstShape

| Campo | Significado |
|---|---|
| `area` (herdado) | Parâmetros da rajada. Cada parte pode ajustar. |
| `instant` | Ligado: acerta uma vez. Desligado: repete ao longo do tempo pelo `SustainedAreaRunner`. |
| `duration`, `tick_interval` | Usados só quando `instant` está desligado (um `ValueSource` cada). As unidades (segundos, turnos...) são do seu jogo. |

A área é calculada uma vez, na conjuração. Uma rajada sustentada não acompanha o conjurador se ele se mover.

### Receitas prontas

| Quero | Monte assim |
|---|---|
| Bola de fogo | `ProjectileShape`, colisão ligada, `impact_actions` vazio |
| Flecha que atravessa | `ProjectileShape`, `impact_actions` = [`ApplyEffectsAction`] sem `DestroyAction` |
| Míssil que só explode no fim | `ProjectileShape`, `collide_along_path` desligado, `impact_area` preenchida |
| Bola que explode e solta estilhaços | `impact_actions` = [`ApplyEffectsAction`, `RecastAction` (definição dos estilhaços), `DestroyAction`] |
| Explosão em volta do conjurador | `BurstShape`, âncora `CASTER`, parâmetros que o seu finder entenda como "em volta" |
| Bomba no ponto mirado | `BurstShape`, âncora `AIM_POINT` |
| Rajada contínua | `BurstShape`, `instant` desligado, `duration` e `tick_interval` |
| Buff ou cura em si | `SelfShape` com elementos de cura |
| Tiro triplo, leque, salva de mísseis | Várias partes (seção 17) |
| Absorção | Elemento com um efeito seu que causa dano no alvo e cura `ctx.caster` (seção 21) |

---

## 17. Magias com várias partes

Uma `SpellDefinition` tem uma lista `parts`. Cada `SpellPart` tem:

| Campo | Significado |
|---|---|
| `shape` | A forma desta parte. Pode ser a mesma `.tres` em várias partes. |
| `elements` | Elementos só desta parte. |
| `area` | Parâmetros desta parte, que sobrescrevem por nome os da forma. |

E a própria `SpellDefinition` tem `elements`: elementos **compartilhados**, que valem para TODAS as partes.

| Pergunta | Resposta |
|---|---|
| Quais elementos uma parte usa? | Os compartilhados da magia, mais os próprios da parte. |
| O custo dos compartilhados conta quantas vezes? | Uma. |
| O custo de uma forma usada em 3 partes? | Três vezes. Para custo fixo, coloque-o na magia e deixe a forma sem custo. |
| O custo é cobrado quantas vezes? | Uma vez só, pelo `SpellCaster`. |
| Em que ordem as partes são disparadas? | A da lista `parts`, de cima para baixo. |
| Como o nome é montado? | `custom_name` se houver. Senão, o nome de cada parte (prefixo da forma + elementos dela) ligado por " e ", com partes iguais agrupadas ("Bola de fogo (x2) e Bola de água"). |

**Tiro triplo** (seção 7): 3 partes, mesma forma `tiro`, `angle` 0, 30 e -30, elementos fogo, gelo e raio.

**Magia com mistura de formas**: parte 1 projétil, parte 2 explosão no ponto mirado, parte 3 `SelfShape` que cura o conjurador. Cada uma com seus elementos.

**Uma parte afetando as outras**: não existe. As partes são independentes. Para encadear (uma parte que nasce quando a outra acerta), use `RecastAction` (seção 16).

---

## 18. Usando em cada tipo de jogo

O sistema decide O QUE acontece. O jogo decide ONDE e COMO. O que muda de um jogo para outro é só a implementação dos tradutores e o significado que você dá aos nomes.

| Tipo de jogo | `TargetFinder` | `ProjectileLauncher` | `SustainedAreaRunner` | Contexto |
|---|---|---|---|---|
| **RPG por turnos** | Devolve os alvos escolhidos na UI, ou grupos inteiros | Toca a animação e chama `on_impact` uma vez, com `is_end` verdadeiro | Aplica um tick por turno | `aim_point` = alvo escolhido. `origin` e `direction` talvez nem usados |
| **RPG tático (grade)** | Converte os números em células | Percorre as células da linha e chama `on_impact` na primeira ocupada, ou só no fim | Aplica ticks por turno | `origin` = célula do conjurador, `aim_point` = célula mirada |
| **Action RPG 2D ou 3D** | Consulta de física | Instancia uma cena por `projectile_id` e a move | `Timer` | `origin`, `direction` e `aim_point` em `Vector2` ou `Vector3` |
| **Jogo de cartas** | Devolve cartas em slots, ou os alvos escolhidos | Instantâneo | Aplica ticks por turno | Cada carta aponta para uma `SpellDefinition`. `can_cast` destaca as cartas jogáveis |

### Exemplo: `ProjectileLauncher` instantâneo (turnos e cartas)

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

### Exemplo: `ProjectileLauncher` e projétil para action 2D (ilustrativo)

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

Script da raiz da cena do projétil (um `Area2D`). Aqui, e só aqui, o jogo decide que `range` é distância em unidades de tela e `angle` é graus:

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
	direction = direction.rotated(deg_to_rad(request.area.get_number(&"angle")))
	global_position = origin
	_velocity = direction * SPEED
	_remaining = request.area.get_number(&"range")
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

---

## 19. Fluxos

### Montagem (build)

```
SpellDefinition  (partes + elementos compartilhados + nome, custo e requisitos opcionais)
      │
      ▼
SpellBuilder.build(definition)
      │  custo e requisitos começam com os da magia e os dos elementos compartilhados
      │  para cada SpellPart:
      │     1. elementos da parte = compartilhados + próprios
      │     2. forma = part.shape.resolve(elementos da parte)
      │     3. soma custo e requisitos da forma e dos elementos próprios
      │     4. parâmetros = SpellArea.merged(forma.area, part.area)
      │     5. cria um SpellPartInstance
      │  nome = SpellNamer.build_name(definition, partes)
      ▼
SpellInstance  (display_name, parts, cost, requirements)
```

### Conjuração (cast)

```
SpellCaster.cast(spell, ctx)
      │
      ├─ sem partes?                         → devolve NO_SHAPE
      ├─ algum requisito não cumprido?       → devolve REQUIREMENT_NOT_MET
      ├─ payer existe e não consegue pagar?  → devolve CANNOT_PAY
      │        (nos três casos nada é cobrado nem disparado)
      ▼
payer.pay(spell.cost)   (uma vez, se houver payer)
      │
      ▼
fire(spell, ctx):  para cada parte, na ordem:
      │     ctx.part = parte
      │     parte.shape.cast(parte, ctx)
      ▼
a forma acha ou cria os alvos e chama parte.apply_to(ctx, alvo)
      │
      ▼
para cada efeito dos elementos da parte e da forma: effect.apply(alvo, poder, ctx)
      │
      ▼
devolve OK
```

### Parâmetros

```
SpellShape.area  (padrão da forma)  +  SpellPart.area  (ajustes da parte)
      │  SpellArea.merged: mesmo nome, vale o da parte
      ▼
SpellPartInstance.area
      │  resolve(ctx, forma.get_origin(ctx))
      │    origem    = ctx.origin  (âncora CASTER)  ou  ctx.aim_point  (âncora AIM_POINT)
      │    direção   = ctx.direction
      │    números   = cada ValueSource lido com o contexto atual
      │    rótulos   = copiados
      ▼
ResolvedArea  →  TargetFinder.find_targets(area, ctx)  ou  ProjectileLauncher
                 (o jogo interpreta cada nome)
```

### Custos (exemplo numérico)

```
Forma "Bola de"     : mana 5
Elemento "fogo"     : mana 2, hp 2
Definição da magia  : (sem custo)
                      ───────────────
Custo final         : mana 7, hp 2
```

### Poder (por parte)

```
Elemento fogo       : power = StatValue("magic_power")
Atributo do jogo    : magic_power = 10        (vem do StatProvider)
Soma dos elementos  : 10                      (da parte: compartilhados + próprios)
Forma da parte      : power_multiplier = 1.5
Poder da parte      : 10 * 1.5 = 15
DamageEffect        : multiplier = 1.0  →  alvo.take_damage(15)
```

### Rajada (BurstShape)

```
BurstShape.cast(parte, ctx)
      │  resolve a área da parte
      ├─ instant ligado (ou sem SustainedAreaRunner)
      │       └─ finder.find_targets(área)  →  parte.apply_to(ctx, cada alvo)
      └─ instant desligado
              └─ SustainedAreaRunner.start(request)
                      └─ a cada tick: finder.find_targets(área)  →  apply_to em cada alvo
```

### Projétil (ProjectileShape)

```
ProjectileShape.cast(parte, ctx)
      │  resolve os parâmetros do trajeto e os do impacto, monta o ProjectileRequest
      ▼
ProjectileLauncher.launch(request)          (o jogo realiza o projétil)
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
todas as partes da nova magia seguem o fluxo normal
```

### Nome

```
custom_name preenchido?
   ├─ sim: usa custom_name                         →  "Tiro triplo"
   └─ não: para cada parte, prefixo da forma + nomes dos elementos da parte
           partes com o mesmo nome são agrupadas "(xN)"
           nomes das partes ligados por " e "
                                                   →  "Bola de fogo"
                                                   →  "Bola de fogo (x2) e Bola de água"
```

### Variação de forma (extensão opcional)

```
Uma parte usa um ShapeGroup como forma
      │
      ▼
SpellBuilder chama group.resolve(elementos da parte)
      │
      ├─ percorre as variantes em ordem
      │     └─ primeira condição verdadeira: devolve variante.shape.resolve(elementos)
      └─ nenhuma verdadeira: devolve fallback.resolve(elementos)

Elemento com tag "solid"  →  forma "Estaca de"  →  "Estaca de terra"
Qualquer outro elemento   →  forma "Bola de"    →  "Bola de fogo"
```

---

## 20. Entradas e saídas

| Chamada | Entrada | Saída |
|---|---|---|
| `SpellBuilder.new(namer?)` | `SpellNamer` opcional | construtor |
| `SpellBuilder.build(def)` | `SpellDefinition` | `SpellInstance` ou `null` (sem partes, parte sem forma ou forma não resolvida) |
| `SpellCaster.can_cast(spell, ctx)` | `SpellInstance`, `SpellContext` | `Result` (nada muda) |
| `SpellCaster.cast(spell, ctx)` | `SpellInstance`, `SpellContext` | `Result`: `OK`, `NO_SHAPE`, `REQUIREMENT_NOT_MET`, `CANNOT_PAY` |
| `SpellCaster.fire(spell, ctx)` | `SpellInstance`, `SpellContext` | nada (dispara sem verificar nem cobrar) |
| `SpellPartInstance.compute_power(ctx)` | `SpellContext` | `float` |
| `SpellPartInstance.apply_to(ctx, alvo)` | `SpellContext`, `Object` | nada (efeitos agem no alvo) |
| `SpellInstance.find_unmet_requirement(ctx)` | `SpellContext` | `SpellRequirement` ou `null` |
| `SpellCost.merged_with(outro)` | `SpellCost` ou `null` | novo `SpellCost` |
| `ValueSource.get_value(ctx)` | `SpellContext` | `float` |
| `ValueSource.read(fonte, ctx, padrão)` | fonte ou `null` | `float` |
| `SpellArea.resolve(ctx, origem)` | `SpellContext`, `Variant` | `ResolvedArea` |
| `SpellArea.merged(base, override)` | duas `SpellArea` (ou `null`) | nova `SpellArea` |
| `ResolvedArea.get_number(nome, padrão)` | `StringName`, `float` | `float` |
| `SpellShape.resolve(elements)` | `Array[SpellElement]` | `SpellShape` (ou `null` em grupos sem saída) |
| `SpellShape.cast(parte, ctx)` | `SpellPartInstance`, `SpellContext` | nada |
| `SpellEffect.apply(alvo, poder, ctx)` | `Object`, `float`, `SpellContext` | nada |
| `SpellRequirement.is_met(ctx)` | `SpellContext` | `bool` |
| `StatProvider.get_stat(chave, padrão)` | `StringName`, `float` | `float` |
| `TagProvider.has_tag(tag)` | `StringName` | `bool` |
| `CostPayer.can_pay(custo)` e `pay(custo)` | `SpellCost` | `bool` e nada |
| `TargetFinder.find_targets(area, ctx)` | `ResolvedArea`, `SpellContext` | `Array` de alvos |
| `ProjectileLauncher.launch(request)` | `ProjectileRequest` | nada (chama `request.on_impact`) |
| `SustainedAreaRunner.start(request)` | `SustainedRequest` | nada (chama `request.on_tick`) |

---

## 21. Como estender

Em todos os casos abaixo você CRIA um arquivo novo e não edita nenhum existente.

**Nova forma** (cone, corrente, alvo único...): crie um script que herda de `SpellShape` e sobrescreva `cast(part, ctx)`. Calcule os parâmetros com `part.area.resolve(ctx, get_origin(ctx))`, ache os alvos pelo `ctx.finder` e chame `part.apply_to(ctx, alvo)` para cada um. Guarde em `scripts/library/shapes/`.

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

**Nova ação de impacto** (quicar, dividir, grudar): herde de `ImpactAction` e sobrescreva `execute(part, ctx, impact_area, impact)`. Guarde em `scripts/library/impact/`.

**Novo requisito** (hora do dia, recurso em recarga): herde de `SpellRequirement` e sobrescreva `is_met(ctx)`.

**Nova fonte de número** (soma, mínimo, nível do conjurador): herde de `ValueSource` e sobrescreva `get_value(ctx)`.

**Nova regra de nome**: herde de `SpellNamer`, sobrescreva `build_name(definition, parts)` e passe ao construtor: `SpellBuilder.new(MeuNamer.new())`.

**Novo contrato do mundo** (sons, câmera, log de combate): crie uma classe base como as de `core/contracts/`, adicione um campo no `SpellContext` e use-a nas suas formas e efeitos.

---

## 22. Extensão opcional: variações de forma

Serve para a mesma "forma de projétil" virar "Estaca de..." ou "Bola de..." conforme o elemento da parte.

**Como montar no editor.** Crie `bola.tres` e `estaca.tres` (cada um um `ProjectileShape`, com seus prefixos). Crie `projetil.tres` do tipo `ShapeGroup`. No Inspector, em `Variants`, clique em Add Element e escolha `ShapeVariant`; em `Condition` escolha `ElementTagCondition` e escreva `solid` no campo `Tag`; em `Shape` arraste `estaca.tres`. Em `Fallback` do grupo arraste `bola.tres`. Na `SpellPart`, use `projetil.tres` como `Shape`. Marque a tag `solid` nos elementos sólidos (`terra.tres`, por exemplo).

**Como remover por completo.**

Passo 1. Abra os seus `.tres` e troque qualquer `ShapeGroup` por uma forma direta (`bola.tres`, por exemplo). Se algum recurso ainda apontar para `ShapeGroup`, `ShapeVariant` ou `ElementTagCondition`, o Godot mostrará um aviso de script ausente.

Passo 2. No painel FileSystem, apague a pasta `scripts/extensions/shape_variants/`.

Passo 3. Apague a pasta `Tests/extensions/`, porque o teste dela só funciona com a extensão.

Passo 4. Pronto. O núcleo, o construtor, o conjurador, a biblioteca e os outros testes continuam funcionando sem nenhuma edição.

---

## 23. Testes

Os testes ficam em `Tests/` e são descartáveis. São cenas que rodam sozinhas, imprimem o resultado no painel Output e fecham.

**Rodar um teste.** No FileSystem, dê duplo clique em uma das cenas abaixo para abri-la e aperte F6 (Run Current Scene). No painel Output, cada verificação aparece como `[ok]` ou `[FALHOU]`, e no fim há a linha `Resultado: N ok, M falhas`.

| Cena | O que testa |
|---|---|
| `Tests/test_core_spell.tscn` | Custo somado, nomes (inclusive com várias partes), elementos compartilhados, conjuração, falta de recursos, `SelfShape` |
| `Tests/test_requirements.tscn` | Requisitos de tag e de atributo, soma de requisitos, bloqueio da conjuração |
| `Tests/test_area_shapes.tscn` | Parâmetros nomeados genéricos, âncora, rajada instantânea e sustentada, herança de parâmetros da parte, projétil, ações de impacto, reconjuração, limite de profundidade e tiro triplo |
| `Tests/extensions/test_shape_variants.tscn` | Grupo de formas (extensão opcional) |

**Se a cena reclamar de script ausente** (você moveu ou renomeou a pasta): abra a cena, clique no nó raiz, no Inspector em Script escolha Load e selecione o `.gd` de mesmo nome, depois salve.

**Criar um teste novo.** Crie um script que herda de `TestCase` (`extends TestCase`), escreva as verificações com `check(condicao, "descrição")` dentro de `_ready()` e termine com `finish()`. Crie uma cena com um `Node` na raiz, anexe o script e rode com F6. Use `TestFactory` para montar peças (`TestFactory.area({"reach": 3.0})`, `TestFactory.part(...)`) e os dublês de `Tests/support` no lugar do seu jogo.

---

## 24. Cuidados e erros comuns

- **"A magia não pôde ser montada".** A receita precisa de pelo menos uma parte, e toda parte precisa de uma forma. Abra o `.tres` e confira se a lista `Parts` não está vazia e se cada parte tem `Shape`.
- **Nome da magia vazio ou estranho.** Preencha `Name Prefix` na forma e `Display Name` nos elementos, ou use `Custom Name` na magia.
- **Nada acontece ao conjurar.** O sistema só chama os tradutores que existem no contexto. Sem `ctx.launcher`, o projétil não sai (aparece um aviso no Output). Sem `ctx.finder`, rajadas não acertam ninguém.
- **Um parâmetro "não funciona".** O sistema só entrega o número. Confira se o seu tradutor usa o MESMO nome (`&"angle"` e `angle` são o mesmo, mas `angulo` é outro).
- **Chaves iguais em todos os lugares.** Se `"mana"` está no `SpellCost` e o seu dicionário usa `"Mana"`, a verificação falha. Se o seu dicionário usa `StringName`, converta nas pontes.
- **`class_name` duplicado.** Se aparecer erro de classe global repetida, há uma cópia antiga em outra pasta. Apague a antiga.
- **Arrays tipados.** Em `Parts`, `Elements`, `Effects`, `Requirements`, `Numbers`, `Variants` e `Impact Actions`, use Add Element no Inspector e escolha o tipo na lista (por exemplo, **New SpellPart**). Pelo código, use `.append(...)`.
- **Contexto incompleto é proposital.** Sem `stats`, os `StatValue` devolvem o `fallback`. Sem `payer`, não há cobrança. Sem `tags`, requisitos de "ter tag" falham.
- **Poder e parâmetros.** `SpellPowerValue` serve para parâmetros e durações. Nunca use dentro de `element.power`, porque o poder depende dele (laço infinito).
- **Custo de forma repetida.** Uma forma usada em 3 partes custa 3 vezes. Para custo fixo, coloque-o na magia.
- **Reconjuração é gratuita.** `RecastAction` usa um contexto filho sem `payer`.
- **Área sustentada é fixa.** Em `BurstShape` não instantânea, a área é calculada uma vez e não acompanha o conjurador.
- **`ShapeGroup` não tem custo, requisitos, prefixo nem parâmetros próprios.** Esses campos existem por herança e são ignorados. Coloque-os nas formas que o grupo escolhe.
- **Grupo sem saída.** Se nenhuma condição for verdadeira e não houver `fallback`, `resolve` devolve `null` e o `SpellBuilder` devolve `null` com um erro no Output.

---

## 25. SOLID no projeto

| Princípio | Onde aparece |
|---|---|
| **S** (responsabilidade única) | `SpellCost` só soma custos. `SpellNamer` só nomeia. `SpellBuilder` só monta. `SpellCaster` só verifica, cobra e dispara. `SpellArea` só guarda parâmetros. Formas só entregam, elementos só definem o efeito. |
| **O** (aberto/fechado) | Formas, efeitos, ações de impacto, requisitos, fontes de valor e condições novos são arquivos novos. Nada existente é editado. Nomes de parâmetros novos não exigem mudar o sistema. |
| **L** (substituição de Liskov) | Qualquer `SpellShape` serve onde uma forma é esperada, inclusive o `ShapeGroup`. Qualquer `ValueSource`, `SpellRequirement` ou `ImpactAction` serve onde o tipo base é esperado. |
| **I** (segregação de interfaces) | Seis contratos pequenos e separados (`StatProvider`, `TagProvider`, `CostPayer`, `TargetFinder`, `ProjectileLauncher`, `SustainedAreaRunner`). O jogo implementa só os que usa. |
| **D** (inversão de dependência) | O núcleo depende de abstrações e de nomes que o jogo define, nunca de física, grade, cenas ou tipo de jogo. O `SpellBuilder` recebe o `SpellNamer` por parâmetro. Tudo que depende do mundo entra pelos contratos. |
