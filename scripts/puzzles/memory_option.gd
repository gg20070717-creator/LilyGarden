extends Resource
## Stable identity is separate from the visible word and replaceable moon artwork.
@export var choice_id: StringName
@export var fragment_id: StringName
@export var fragment_display_name := ""
@export var word := ""
## Visible lunar illumination: circular rim plus elliptical terminator.
@export_range(0.05, 1.0) var moon_fraction := 0.5
@export var moon_texture: Texture2D
