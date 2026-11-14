class_name ProjectileLauncher
extends RefCounted
## Contrato: o jogo realiza o projétil (cena em movimento, trajetória instantânea,
## animação de carta...). request.area traz os números nomeados da parte; o jogo decide
## o significado de cada um.
##
## Regras para quem implementa launch(request):
## 1. Realize o projétil como o seu jogo entender.
## 2. Para cada impacto, crie um ProjectileImpact (point, targets, is_end) e chame
##    request.on_impact.call(impact).
## 3. Depois da chamada, se impact.destroyed for true, pare o projétil.
## 4. Se request.collide_along_path for false, só chame on_impact uma vez, no fim.

func launch(_request: ProjectileRequest) -> void:
	pass
