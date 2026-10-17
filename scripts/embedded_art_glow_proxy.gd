@tool
extends Node2D
## Exposes an alpha mask to the existing click/glow interfaces without drawing it.
## The visible artwork remains baked into the scene background.
@export var size := Vector2.ONE
@export var artwork: Texture2D
@export var artwork_size := Vector2.ZERO
@export var artwork_offset := Vector2.ZERO
@export var oval := false
@export var draw_placeholder := false
