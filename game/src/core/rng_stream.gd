class_name RngStream
extends RefCounted
## One seeded random stream (GDD section 14: "each system has its own seeded stream stored in
## the save"). The whole state is a single 32-bit integer, so it survives a JSON round trip
## exactly and a reload cannot change the next roll.

const MASK := 0xFFFFFFFF

var state: int = 0


func _init(seed_value: int = 0) -> void:
	state = seed_value & MASK


func next_u32() -> int:
	state = (state + 0x6D2B79F5) & MASK
	var t := state
	t = ((t ^ (t >> 15)) * (t | 1)) & MASK
	t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & MASK)) & MASK)) & MASK
	return (t ^ (t >> 14)) & MASK


## Uniform float in [0, 1).
func randf() -> float:
	return float(next_u32()) / 4294967296.0


## Uniform float in [0, 100): the unit every displayed percentage is rolled against.
func roll_percent() -> float:
	return self.randf() * 100.0


## Uniform integer in [from, to], both included.
func randi_range(from: int, to: int) -> int:
	return from + int(self.randf() * float(to - from + 1))
