class_name SfxDirector
extends Node
## Traduz eventos do bus em sons. Sons de tiro ficam na própria torre
## (TowerData.shoot_sfx); aqui ficam os eventos globais da partida.

const SFX_DEATH := preload("res://assets/audio/sfx/enemy_death.ogg")
const SFX_LEAK := preload("res://assets/audio/sfx/leak.ogg")
const SFX_BUILD := preload("res://assets/audio/sfx/build.ogg")
const SFX_SELL := preload("res://assets/audio/sfx/sell.ogg")
const SFX_ERROR := preload("res://assets/audio/sfx/error.ogg")
const JINGLE_VICTORY := preload("res://assets/audio/music/victory.ogg")
const JINGLE_DEFEAT := preload("res://assets/audio/music/defeat.ogg")


func _ready() -> void:
	GameEvents.enemy_died.connect(func(_e: Node2D, _g: int) -> void: AudioManager.play_sfx(SFX_DEATH))
	GameEvents.enemy_leaked.connect(func(_e: Node2D, _l: int) -> void: AudioManager.play_sfx(SFX_LEAK))
	GameEvents.tower_placed.connect(func(_t: Node2D) -> void: AudioManager.play_sfx(SFX_BUILD))
	GameEvents.tower_sold.connect(func(_c: Vector2i, _r: int) -> void: AudioManager.play_sfx(SFX_SELL))
	GameEvents.placement_rejected.connect(func(_r: int) -> void: AudioManager.play_sfx(SFX_ERROR))
	GameEvents.game_over.connect(
		func(won: bool) -> void:
			AudioManager.play_music(JINGLE_VICTORY if won else JINGLE_DEFEAT, false)
	)
