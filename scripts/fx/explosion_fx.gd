class_name ExplosionFx
extends Node2D
## Efecto visual simple de explosión (círculo que se expande y se desvanece).

const LIFETIME := 0.7

var _age := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var radius := lerpf(10.0, 110.0, t)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.55, 0.1, 0.8 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.9, 0.4, 1.0 - t), 4.0)
