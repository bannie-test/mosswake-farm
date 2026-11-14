extends Node
## Starts a game: resets every system in order. Autoload: Session.
## In M1 it also applies the scaffolding scenario (design/specs/m1_first_playable.md, section 6).

const M1_SCENARIO := "res://dev/m1_scenario.json"


func new_game(seed_value: int) -> void:
	GameState.new_game(seed_value)
	Inventory.new_game()
	Farm.new_game()
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(M1_SCENARIO))
	for building_id: String in scenario["buildings"]:
		GameState.buildings[building_id] = int(scenario["buildings"][building_id])
	for recipe_id: String in scenario["knownRecipes"]:
		GameState.unlock(recipe_id)
	Orders.new_game(scenario["orders"])
