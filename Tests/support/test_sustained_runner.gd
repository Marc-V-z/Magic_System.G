class_name TestSustainedRunner
extends SustainedAreaRunner
## SustainedAreaRunner de teste: dispara um número fixo de ticks na hora.

var ticks: int = 3
var last_request: SustainedRequest

func start(request: SustainedRequest) -> void:
	last_request = request
	for i in ticks:
		request.on_tick.call()
