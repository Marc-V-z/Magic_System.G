class_name ProjectileShape
extends SpellShape

@export var projectile_scene: PackedScene

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate()
	ctx.caster.get_parent().add_child(projectile)
	# A cena do projétil decide como se mover e quando chamar spell.apply_to(...)
	if projectile.has_method("launch"):
		projectile.launch(spell, ctx)