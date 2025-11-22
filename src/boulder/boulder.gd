class_name Boulder
extends RigidBody2D


func take_damage(_amount: int) -> void:
    apply_force(Vector2(1000, 0)*50, Vector2.ZERO)