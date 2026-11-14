class_name ProjectileShape
extends SpellShape
## Instancia uma cena de projétil. A cena decide movimento e colisão.

@export var projectile_scene: PackedScene

func cast(spell: SpellInstance, ctx: SpellContext) -> void:
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate()
	ctx.caster.get_parent().add_child(projectile)
	# O projétil precisa ter launch(spell, ctx) e chamar spell.apply_to(ctx, alvo) ao acertar.
	if projectile.has_method("launch"):
		projectile.launch(spell, ctx)
