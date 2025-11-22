extends CharacterBody2D

@export_category("Movement")
@export var speed = 300.0
@export var acceleration = 0.25
@export var friction = 0.1

@export_category("Jump")
@export var jump_velocity = 400.0
@export var additional_jump_height = 150.0 # Hold jump button to go higher
@export var jump_release_force = 200.0 # Let go of jump button to fall faster
@export var fall_gravity_multiplier = 2.0 # Gravity is stronger when falling

@export_category("Polish")
@export var coyote_time = 0.1
var coyote_timer = 0.0
@export var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _punch_area_initial_pos_x: float

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_area: Area2D = %PunchArea



func _ready() -> void:
    _punch_area_initial_pos_x = punch_area.position.x
    punch_area.monitoring = false
    punch_area.body_entered.connect(
        func(body: Node) -> void:
            if body.has_method("take_damage"):
                body.take_damage(1)
    )


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("punch"):
        _handle_punch()


func _physics_process(delta):

    _handle_gravity(delta)
    _handle_jump(delta)
    _handle_horizontal_movement(delta)

    move_and_slide()

    jump_buffer_timer -= delta


func _handle_gravity(delta):

    if not is_on_floor():
        velocity.y += gravity * delta
        
        # Falling
        if velocity.y > 0:
            velocity.y += gravity * fall_gravity_multiplier * delta



func _handle_jump(delta):
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = jump_buffer_time

    if is_on_floor():
        coyote_timer = coyote_time
    else:
        coyote_timer -= delta


    if jump_buffer_timer > 0 and coyote_timer > 0:
        velocity.y = -jump_velocity
        jump_buffer_timer = 0.0
        coyote_timer = 0.0


    # Variable jump height
    if Input.is_action_pressed("jump") and velocity.y < 0:
        velocity.y -= additional_jump_height * delta

    if Input.is_action_just_released("jump") and velocity.y < 0:
        velocity.y = max(velocity.y, -jump_release_force)


func _handle_horizontal_movement(_delta):
    var direction = Input.get_axis("move_left", "move_right")
    
    if direction:
        velocity.x = lerp(velocity.x, direction * speed, acceleration)
    else:
        velocity.x = lerp(velocity.x, 0.0, friction)
    
    if direction > 0:
        animated_sprite_2d.flip_h = false
        punch_area.position.x = _punch_area_initial_pos_x
    elif direction < 0:
        animated_sprite_2d.flip_h = true
        punch_area.position.x = -_punch_area_initial_pos_x


func _handle_punch():
    punch_area.monitoring = true
    animated_sprite_2d.play("punch")
    animated_sprite_2d.animation_finished.connect(func():
        punch_area.monitoring = false
        animated_sprite_2d.play("idle")
    , Object.CONNECT_ONE_SHOT)