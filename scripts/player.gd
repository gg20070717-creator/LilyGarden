extends CharacterBody2D
@export var speed := 300.0
@export var interaction_range := 65.0
## 100 world units = 1 metre. The sprite stands above its foot collider.
@export var body_height := 150.0
var input_blocked := false
var facing := Vector2.DOWN
var walk_phase := 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	if input_blocked:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	if direction != Vector2.ZERO:
		facing = direction
	var before := position
	move_and_slide()
	walk_phase = walk_phase + delta * 9.0 if position.distance_to(before) > 0.01 else 0.0
	queue_redraw()

func _limb(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.2, 0.2, 0.2), 10.0, true)
	draw_line(from, to, Color(0.88, 0.88, 0.88), 6.0, true)

func _draw() -> void:
	# Keep the editable whitebox height independent from the foot collider.
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * body_height / 170.0)
	var stride := sin(walk_phase) * 5.0
	_limb(Vector2(-11, -66), Vector2(-14, -4 + stride))
	_limb(Vector2(11, -66), Vector2(14, -4 - stride))
	_limb(Vector2(-20, -124), Vector2(-29, -74 - stride))
	_limb(Vector2(20, -124), Vector2(29, -74 + stride))
	draw_rect(Rect2(-5, -145, 10, 14), Color(0.85, 0.85, 0.85))
	var torso := Rect2(-21, -135, 42, 70)
	draw_rect(torso, Color(0.8, 0.8, 0.8))
	draw_rect(torso, Color(0.2, 0.2, 0.2), false, 2.5)
	var head := Rect2(-12, -170, 24, 26)
	draw_rect(head, Color.WHITE)
	draw_rect(head, Color(0.2, 0.2, 0.2), false, 2.5)
	if facing.y >= 0:
		draw_rect(Rect2(-7, -161, 4, 4), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(3, -161, 4, 4), Color(0.2, 0.2, 0.2))
	elif facing.x != 0:
		draw_rect(Rect2(5 if facing.x > 0 else -9, -161, 4, 4), Color(0.2, 0.2, 0.2))
