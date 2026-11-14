extends Node
## Starts or resumes a game: resets every system in order. Autoload: Session.
var slot := 1            ## the save slot in use; tests point it elsewhere


func _ready() -> void:
	Sim.dawn.connect(func(_day: int) -> void: autosave())


func new_game(seed_value: int) -> void:
	GameState.new_game(seed_value)
	Inventory.new_game()
	Farm.new_game()
	Animals.new_game()
	Shipping.new_game()
	Research.new_game()
	Spirits.new_game()
	Orders.new_game()
	Quests.new_game()


## Load the slot if it holds a save; otherwise start a new game. Returns true when a save was loaded.
func continue_or_new(seed_value: int) -> bool:
	new_game(seed_value)
	if SaveGame.has_save(slot) and SaveGame.load_slot(slot) == OK:
		return true
	return false


var autosave_enabled := false      ## switched on by the game scene; tests leave it off


func autosave() -> void:
	if autosave_enabled:
		SaveGame.save(slot)
