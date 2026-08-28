extends Node


@export_category("Tracks")

## Normal music used while the Player is exploring
## and no enemies are actively engaged.
@export var exploration_track: AudioStream

## Music used whenever at least one Enemy
## considers itself actively engaged with the Player.
@export var battle_track: AudioStream

## Music reserved for explicit victory or celebration events.
## Combat ending does not automatically count as a victory.
@export var celebration_track: AudioStream

@export var menu_track: AudioStream

@export var danger_track: AudioStream

@export_category("Transitions")

## Seconds used when transitioning INTO battle music.
## Useful for matching a Battle track that has a quiet intro.
@export_range(0.0, 5.0, 0.05)
var battle_crossfade_duration := 0.7


## Seconds used when transitioning back into exploration music.
@export_range(0.0, 5.0, 0.05)
var exploration_crossfade_duration := 1.5


## Seconds used when transitioning into celebration music.
@export_range(0.0, 5.0, 0.05)
var celebration_crossfade_duration := 1.0


@onready var track_a: AudioStreamPlayer = (
	$TrackA
)

@onready var track_b: AudioStreamPlayer = (
	$TrackB
)


var active_player: AudioStreamPlayer
var standby_player: AudioStreamPlayer

var music_tween: Tween


func _ready() -> void:
	active_player = track_a
	standby_player = track_b

	CombatTracker.combat_started.connect(
		_on_combat_started
	)

	CombatTracker.combat_ended.connect(
		_on_combat_ended
	)

	_switch_track(
		exploration_track,
		true
	)


func _on_combat_started() -> void:
	_switch_track(
		battle_track,
		false,
		battle_crossfade_duration
	)


func _on_combat_ended() -> void:
	_switch_track(
		exploration_track,
		false,
		exploration_crossfade_duration
	)


func play_celebration() -> void:
	_switch_track(
		celebration_track,
		false,
		celebration_crossfade_duration
	)


func return_to_context_music() -> void:
	if CombatTracker.is_in_combat():
		_switch_track(
			battle_track,
			false,
			battle_crossfade_duration
		)

		return

	_switch_track(
		exploration_track,
		false,
		exploration_crossfade_duration
	)


func _switch_track(
	stream: AudioStream,
	immediate := false,
	fade_duration := 1.0
) -> void:
	if stream == null:
		return

	if (
		active_player.playing
		and active_player.stream == stream
	):
		return

	if music_tween != null:
		music_tween.kill()

	if immediate:
		standby_player.stop()

		active_player.stream = stream
		active_player.volume_db = 0.0

		active_player.play()

		return

	var previous_player := (
		active_player
	)

	var next_player := (
		standby_player
	)

	next_player.stop()

	next_player.stream = stream
	next_player.volume_db = -60.0

	next_player.play()

	music_tween = create_tween()

	music_tween.set_parallel(
		true
	)

	music_tween.tween_property(
		previous_player,
		"volume_db",
		-60.0,
		fade_duration
	)

	music_tween.tween_property(
		next_player,
		"volume_db",
		0.0,
		fade_duration
	)

	music_tween.finished.connect(
		func() -> void:
			previous_player.stop()
	)

	active_player = next_player
	standby_player = previous_player
