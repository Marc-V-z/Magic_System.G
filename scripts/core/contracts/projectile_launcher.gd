class_name ProjectileLauncher
extends RefCounted
## Contrato: o jogo realiza o projétil (cena em movimento, trajetória instantânea, animação...).
##
## Regras para quem implementa launch(request):
## 1. Mova o projétil a partir de request.area (origem, direção, alcance).
## 2. Para cada impacto, crie um ProjectileImpact (point, targets, is_end) e chame
##    request.on_impact.call(impact).
## 3. Depois da chamada, se impact.destroyed for true, pare o projétil.
## 4. Se request.collide_along_path for false, só chame on_impact uma vez, no fim do trajeto.

func launch(_request: ProjectileRequest) -> void:
	pass
