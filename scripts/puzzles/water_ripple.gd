extends TextureRect
## Decorative one-shot feedback. It never receives mouse input or blocks a turn.
const RIPPLE_SHADER = preload("res://scripts/puzzles/water_ripple.gdshader")
var animation: SpriteFrames
var current_frame := -1
var elapsed := 0.0
var playing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var ripple_material := ShaderMaterial.new()
	ripple_material.shader = RIPPLE_SHADER
	material = ripple_material
	stop()

func configure(frames: SpriteFrames, source_uv: Rect2) -> void:
	animation = frames
	material.set_shader_parameter("source_rect", Vector4(source_uv.position.x, source_uv.position.y, source_uv.size.x, source_uv.size.y))

func play() -> void:
	if animation == null or not animation.has_animation(&"ripple") or animation.get_frame_count(&"ripple") == 0:
		return
	elapsed = 0.0
	current_frame = 0
	texture = animation.get_frame_texture(&"ripple", current_frame)
	playing = true
	show()
	set_process(true)

func stop() -> void:
	playing = false
	elapsed = 0.0
	current_frame = -1
	texture = null
	hide()
	set_process(false)

func _process(delta: float) -> void:
	elapsed += delta
	var next_frame := int(elapsed * animation.get_animation_speed(&"ripple"))
	if next_frame >= animation.get_frame_count(&"ripple"):
		stop()
	elif next_frame != current_frame:
		current_frame = next_frame
		texture = animation.get_frame_texture(&"ripple", current_frame)
