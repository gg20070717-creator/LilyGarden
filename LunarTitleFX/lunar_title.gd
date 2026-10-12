extends TextureRect
## A single planar title: pointer-driven perspective and a procedural sheen.
## Keep this folder at res://LunarTitleFX/ when importing into a project.

const TITLE_SHADER: Shader = preload("res://LunarTitleFX/lunar_title.gdshader")

@export_range(0.0, 20.0, 0.1) var yaw_limit_degrees: float = 10.0
@export_range(0.0, 10.0, 0.1) var pitch_limit_degrees: float = 3.0
@export_range(0.02, 0.5, 0.01) var follow_seconds: float = 0.10
@export_range(2.0, 6.0, 0.1) var camera_distance: float = 3.0
@export_range(0.65, 0.95, 0.01) var content_scale: float = 0.88
@export_range(2.0, 30.0, 0.1) var sheen_cycle: float = 10.0
@export_range(0.5, 1.0, 0.01) var base_brightness: float = 0.82
@export_range(0.0, 1.0, 0.01) var sheen_strength: float = 0.60
@export_range(0.05, 0.5, 0.01) var sheen_width: float = 0.22
@export_range(0.0, 0.15, 0.005) var glow_strength: float = 0.025
@export var sheen_enabled: bool = true
@export var auto_rock: bool = false
@export var highlight_mask: Texture2D

var _fx_material: ShaderMaterial
var _tilt: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _rock_phase: Vector2 = Vector2.ZERO
var _pointer_in_window: bool = true


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_SCALE
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Every instance owns its uniforms; other UI materials are unaffected.
    _fx_material = ShaderMaterial.new()
    _fx_material.shader = TITLE_SHADER
    material = _fx_material
    get_window().mouse_exited.connect(_on_window_mouse_exited)
    get_window().mouse_entered.connect(_on_window_mouse_entered)
    _update_uniforms()


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _pointer_in_window = true


func _process(delta: float) -> void:
    if _fx_material == null or size.x <= 0.0 or size.y <= 0.0:
        return
    _elapsed = fmod(_elapsed + delta, maxf(sheen_cycle, 0.1))
    _rock_phase.x = fmod(_rock_phase.x + delta * 0.85, TAU)
    _rock_phase.y = fmod(_rock_phase.y + delta * 0.55, TAU)
    var target := Vector2.ZERO
    if auto_rock:
        target = Vector2(
            sin(_rock_phase.x) * yaw_limit_degrees,
            sin(_rock_phase.y) * pitch_limit_degrees * 0.5
        )
    elif _pointer_in_window and get_window().has_focus():
        var half_extent := size * 0.5 * content_scale
        var relative := (get_local_mouse_position() - size * 0.5) / half_extent
        var reach := maxf(absf(relative.x), absf(relative.y))
        var influence := 1.0 - smoothstep(1.0, 1.35, reach)
        target = Vector2(
            clampf(relative.x, -1.0, 1.0) * yaw_limit_degrees,
            -clampf(relative.y, -1.0, 1.0) * pitch_limit_degrees
        ) * influence
    var weight := 1.0 - exp(-delta / maxf(follow_seconds, 0.001))
    _tilt = _tilt.lerp(target, weight)
    _update_uniforms()


func _update_uniforms() -> void:
    _fx_material.set_shader_parameter("tilt_degrees", _tilt)
    _fx_material.set_shader_parameter("rect_aspect", size.x / maxf(size.y, 1.0))
    _fx_material.set_shader_parameter("camera_distance", camera_distance)
    _fx_material.set_shader_parameter("content_scale", content_scale)
    _fx_material.set_shader_parameter("elapsed", _elapsed)
    _fx_material.set_shader_parameter("sheen_cycle", sheen_cycle)
    _fx_material.set_shader_parameter("base_brightness", base_brightness)
    _fx_material.set_shader_parameter("sheen_strength", sheen_strength)
    _fx_material.set_shader_parameter("sheen_width", sheen_width)
    _fx_material.set_shader_parameter("glow_strength", glow_strength)
    _fx_material.set_shader_parameter("sheen_enabled", sheen_enabled)
    _fx_material.set_shader_parameter("use_highlight_mask", highlight_mask != null)
    if highlight_mask != null:
        _fx_material.set_shader_parameter("highlight_mask", highlight_mask)


func _on_window_mouse_exited() -> void:
    _pointer_in_window = false


func _on_window_mouse_entered() -> void:
    _pointer_in_window = true
