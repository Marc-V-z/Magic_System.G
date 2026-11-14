class_name TestLauncher
extends ProjectileLauncher
## ProjectileLauncher de teste: simula impactos na ordem e para quando um é destruído.

var impacts: Array = []
var last_request: ProjectileRequest
var launch_count: int = 0

func launch(request: ProjectileRequest) -> void:
	last_request = request
	launch_count += 1
	for impact in impacts:
		request.on_impact.call(impact)
		if impact.destroyed:
			break
