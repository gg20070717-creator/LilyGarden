extends Resource
@export var puzzle_id: StringName = &"well_memory"
@export var options: Array[Resource] = []
@export var answer_left: StringName = &"A"
@export var answer_right: StringName = &"B"
@export var sentence_verb := "看见"
@export var failure_text := "水面很平静，毫无波澜"
## False completes the puzzle and fades back to exploration without a CG.
@export var play_success_story := true
@export var success_image: Texture2D
## Optional story constants INTRO_PAGES / NARRATIVE_PAGES.
@export var story_script: Script
## Optional well art retained through selection and word restoration, expressed in its source canvas coordinates.
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

## Optional layout in moon_reference_size coordinates; empty keeps the well layout.
@export var moon_centers := PackedVector2Array()
@export var moon_token_size := Vector2(144, 144)
@export var underwater_word_centers := PackedVector2Array()
@export var sentence_rect := Rect2()
## Local reference-space polygon inside moon_water_rect; empty uses an ellipse.
@export var water_drop_polygon := PackedVector2Array()
@export var enter_hint_center := Vector2(-1, -1)
@export var feedback_center := Vector2(-1, -1)
## Reveal each deposited word immediately; Enter then opens the filling phase.
@export var rise_on_drop := false
