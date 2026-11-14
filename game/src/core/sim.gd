extends Node
## Simulation core (GDD section 14, "Simulation and offline progression").
## Autoload name: Sim. Every gameplay system registers here and implements
## advance(delta_game_minutes). The frame loop feeds small deltas; sleeping feeds a large
## one in steps, so every system moves through time the same way in both cases.

signal hour_changed(hour: int)
signal dawn(day: int)

const MINUTES_PER_HOUR := 60.0

var game_minute: float = 0.0
var paused: bool = false
var time_scale: float = 1.0          ## 1.0 in play; tests and soak runs raise it

var _systems: Array = []
var _minutes_per_real_second: float = 1.0
var _hours_per_day: int = 24
var _day_start_hour: int = 6
var _night_start_hour: int = 20
var _sleep_step: float = 10.0


func _ready() -> void:
	configure(GameData.config.get("time", {}))


func configure(time_cfg: Dictionary) -> void:
	if time_cfg.is_empty():
		return
	_minutes_per_real_second = MINUTES_PER_HOUR / float(time_cfg["realSecondsPerGameHour"])
	_hours_per_day = int(time_cfg["hoursPerDay"])
	_day_start_hour = int(time_cfg["dayStartHour"])
	_night_start_hour = int(time_cfg["nightStartHour"])
	_sleep_step = float(time_cfg["sleepStepMinutes"])


func register(system: Object) -> void:
	assert(system.has_method("advance"), "a simulation system must implement advance(delta_minutes)")
	if not _systems.has(system):
		_systems.append(system)


func unregister(system: Object) -> void:
	_systems.erase(system)


func _process(delta: float) -> void:
	if not paused:
		advance(delta * _minutes_per_real_second * time_scale)


## Move the whole simulation forward. Steps are cut at hour boundaries so that hour and dawn
## events fire in order, between the system updates on either side of them.
func advance(delta_minutes: float) -> void:
	var remaining := delta_minutes
	while remaining > 0.0:
		var next_hour := (floorf(game_minute / MINUTES_PER_HOUR) + 1.0) * MINUTES_PER_HOUR
		var step := minf(remaining, next_hour - game_minute)
		for system: Object in _systems:
			system.advance(step)
		remaining -= step
		if game_minute + step >= next_hour - 0.000001:
			game_minute = next_hour
			hour_changed.emit(hour())
			if hour() == _day_start_hour:
				dawn.emit(day())
		else:
			game_minute += step


## Sleeping in the farmhouse: skip to the next dawn in fixed steps so spirits, moisture and
## animals interleave correctly.
func sleep_until_dawn() -> void:
	var target := next_dawn_minute()
	while game_minute < target:
		advance(minf(_sleep_step, target - game_minute))


func next_dawn_minute() -> float:
	var day_minutes := _hours_per_day * MINUTES_PER_HOUR
	var dawn_today := floorf(game_minute / day_minutes) * day_minutes + _day_start_hour * MINUTES_PER_HOUR
	return dawn_today if game_minute < dawn_today else dawn_today + day_minutes


func hour() -> int:
	return int(floorf(game_minute / MINUTES_PER_HOUR)) % _hours_per_day


func minute_of_hour() -> int:
	return int(floorf(game_minute)) % int(MINUTES_PER_HOUR)


func day() -> int:
	return int(floorf(game_minute / (_hours_per_day * MINUTES_PER_HOUR))) + 1


func is_night() -> bool:
	return hour() >= _night_start_hour or hour() < _day_start_hour


func clock_text() -> String:
	return "Day %d  %02d:%02d" % [day(), hour(), minute_of_hour()]
