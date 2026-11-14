class_name SustainedAreaRunner
extends RefCounted
## Contrato: o jogo repete uma área ao longo do tempo (rajada não instantânea).
##
## Regras para quem implementa start(request): chame request.on_tick.call() a cada
## request.tick_interval durante request.duration. As unidades (segundos, turnos...)
## são do seu jogo.

func start(_request: SustainedRequest) -> void:
	pass
