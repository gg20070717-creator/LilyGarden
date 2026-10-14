extends Resource
@export var puzzle_id: StringName = &"well_memory"
@export var options: Array[Resource] = []
@export var answer_left: StringName = &"A"
@export var answer_right: StringName = &"B"
@export var sentence_verb := "看见"
@export var failure_text := "水面很平静，毫无波澜"
## Disable white UI backings while retaining the original moon shapes and hit areas.
@export var ui_backing_enabled := true
## Opt-in moonlight text, curved slots and quiet interaction effects.
@export var moonlight_ui_enabled := false
## Optional local contrast mist for sentences over bright water; zero leaves it off.
@export_range(0.0, 0.6) var moonlight_sentence_mist_opacity := 0.0
## Independent readability settings; defaults preserve the well layout.
@export_range(16, 96) var underwater_word_font_size: int = 32
@export_range(24, 96) var word_font_size: int = 46
@export var word_token_size := Vector2(120, 72)
@export_range(1.0, 6.0) var slot_line_width: float = 1.4
@export_range(0.0, 1.0) var slot_empty_opacity: float = 0.66
## False completes the puzzle and fades back to exploration without a CG.
@export var play_success_story := true
@export var success_image: Texture2D
## Optional story constants INTRO_PAGES / NARRATIVE_PAGES.
@export var story_script: Script
## Background retained through selection and word restoration; moon_well is an optional foreground layer.
@export var moon_environment: Texture2D
@export var moon_well: Texture2D
@export var moon_reference_size := Vector2(1920, 1080)
@export var moon_well_rect := Rect2(600, 842, 750, 230)
@export var moon_water_rect := Rect2(630, 877, 690, 105)
## Fragment-only bounds in reference canvas coordinates; empty uses the water shape.
@export var fragment_drop_rect: Rect2 = Rect2()
@export var fragment_drop_margin: float = 0.0
## First-drag guide target and layout in reference canvas coordinates.
@export var drag_hint_target_name: String = "水面"
@export var drag_hint_rect: Rect2 = Rect2(32, 32, 460, 224)
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
