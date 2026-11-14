class_name TestLauncher
extends ProjectileLauncher
## ProjectileLauncher de teste: guarda os pedidos e simula impactos, parando se um for destruído.

var impacts: Array = []
var requests: Array[ProjectileRequest] = []
var last_request: ProjectileRequest
var launch_count: int = 0

func launch(request: ProjectileRequest) -> void:
	last_request = request
	requests.append(request)
	launch_count += 1
	for impact in impacts:
		request.on_impact.call(impact)
		if impact.destroyed:
			break
