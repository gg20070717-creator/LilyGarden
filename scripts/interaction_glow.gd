extends Node2D
## A separate, padded effect behind the visible object; no collision or input.
const GLOW_SHADER = preload("res://shaders/interaction_glow.gdshader")
const OUTLINE_WIDTH_PX := 3.2
const HALO_RADIUS_PX := 9.0
const FADE_SECONDS := 0.2
const BREATH_SECONDS := 1.8

var _glow_material: ShaderMaterial
var _content_rect := Rect2()
var _quad_rect := Rect2()
var _screen_scale := Vector2.ZERO
var _configured := false
var _active := false
var _opacity := 0.0
var _elapsed := 0.0
var _breathing := false

func _ready() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hide()
	set_process(false)

func bind_visual(visual: Node2D) -> bool:
	var size_value: Variant = visual.get("size")
	if not size_value is Vector2:
		return false
	var footprint: Vector2 = size_value
	if footprint.x <= 0.0 or footprint.y <= 0.0:
		return false
	_glow_material = ShaderMaterial.new()
	_glow_material.shader = GLOW_SHADER
	material = _glow_material
	_glow_material.set_shader_parameter("outline_width_px", OUTLINE_WIDTH_PX)
	_glow_material.set_shader_parameter("halo_radius_px", HALO_RADIUS_PX)
	var artwork_value: Variant = visual.get("artwork")
	if artwork_value is Texture2D:
		var artwork: Texture2D = artwork_value
		var drawn_size: Vector2 = visual.get("artwork_size")
		if drawn_size == Vector2.ZERO:
			var texture_size := artwork.get_size()
			drawn_size = texture_size * minf(footprint.x / texture_size.x, footprint.y / texture_size.y)
		var drawn_offset: Vector2 = visual.get("artwork_offset")
		_content_rect = Rect2(drawn_offset - drawn_size * 0.5, drawn_size)
		_glow_material.set_shader_parameter("textured", true)
		_bind_texture(artwork)
	else:
		if not bool(visual.get("draw_placeholder")):
			return false
		# The original whitebox outline extends 1.5 units beyond its footprint.
		var outer_size := footprint + Vector2.ONE * 3.0
		_content_rect = Rect2(-outer_size * 0.5, outer_size)
		_glow_material.set_shader_parameter("textured", false)
		_glow_material.set_shader_parameter("ellipse", bool(visual.get("oval")))
	_glow_material.set_shader_parameter("content_center", _content_rect.get_center())
	_glow_material.set_shader_parameter("content_size", _content_rect.size)
	_configured = true
	_update_screen_scale()
	return true

func _bind_texture(artwork: Texture2D) -> void:
	var source_texture: Texture2D = artwork
	var source_region := Rect2(Vector2.ZERO, artwork.get_size())
	# Current art uses AtlasTexture crops. Resolve the source without changing it.
	while source_texture is AtlasTexture:
		var atlas_texture := source_texture as AtlasTexture
		source_region.position += atlas_texture.region.position
		source_texture = atlas_texture.atlas
	var atlas_size := source_texture.get_size()
	var uv_rect := Rect2(source_region.position / atlas_size, source_region.size / atlas_size)
	_glow_material.set_shader_parameter("mask_texture", source_texture)
	_glow_material.set_shader_parameter("source_rect", Vector4(uv_rect.position.x, uv_rect.position.y, uv_rect.size.x, uv_rect.size.y))
	_glow_material.set_shader_parameter("source_texel_size", Vector2.ONE / atlas_size)

func set_active(value: bool, tint: Color) -> void:
	if not _configured:
		return
	if value and not _active:
		_elapsed = 0.0
	_active = value
	_breathing = not tint.is_equal_approx(Color.WHITE)
	_glow_material.set_shader_parameter("glow_color", tint)
	if _active or _opacity > 0.0:
		show()
		set_process(true)
		_update_screen_scale()

func _process(delta: float) -> void:
	_update_screen_scale()
	_opacity = move_toward(_opacity, 1.0 if _active else 0.0, delta / FADE_SECONDS)
	_elapsed += delta
	var breath := 0.94 + 0.06 * cos(_elapsed * TAU / BREATH_SECONDS) if _breathing else 1.0
	_glow_material.set_shader_parameter("intensity", _opacity * breath)
	if not _active and is_zero_approx(_opacity):
		hide()
		set_process(false)

func _update_screen_scale() -> void:
	# Keep the chosen thickness in screen pixels as the camera/window changes.
	var next_scale := get_global_transform_with_canvas().get_scale().abs().max(Vector2(0.001, 0.001))
	if next_scale.is_equal_approx(_screen_scale):
		return
	_screen_scale = next_scale
	_glow_material.set_shader_parameter("screen_scale", _screen_scale)
	var padding := Vector2.ONE * (OUTLINE_WIDTH_PX + HALO_RADIUS_PX * 2.0 + 1.0) / _screen_scale
	_quad_rect = _content_rect.grow_individual(padding.x, padding.y, padding.x, padding.y)
	queue_redraw()

func _draw() -> void:
	if _configured:
		draw_rect(_quad_rect, Color.WHITE)
