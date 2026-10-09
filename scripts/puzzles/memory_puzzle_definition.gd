extends Resource
@export var puzzle_id: StringName = &"well_memory"
@export var options: Array[Resource] = []
@export var answer_left: StringName = &"A"
@export var answer_right: StringName = &"B"
@export var sentence_verb := "看见"
@export var success_image: Texture2D
## Optional selection-stage art, expressed in its source canvas coordinates.
@export var moon_environment: Texture2D
@export var moon_well: Texture2D
@export var moon_reference_size := Vector2(1920, 1080)
@export var moon_well_rect := Rect2(600, 842, 750, 230)
@export var moon_water_rect := Rect2(630, 877, 690, 105)
## A one-shot animation below the word layer; source UVs trim transparent margins.
@export var water_ripple: SpriteFrames
@export var ripple_source_uv := Rect2(0.036, 0.4448, 0.9216, 0.254)
@export_range(0.1, 5.0) var rise_duration := 0.45
@export_range(0.1, 5.0) var failure_duration := 1.5
