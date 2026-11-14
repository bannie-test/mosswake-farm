extends Node
## Shipping bin (GDD section 10): pays the bin rate at dawn. After a number of units of one
## tier 3+ good in a day the price for it drops per unit, down to a floor. Autoload: Shipping.

signal changed

var bin: Dictionary = {}       # item ID -> units waiting for dawn


func _ready() -> void:
	Sim.dawn.connect(func(_day: int) -> void: pay_out())
	SaveGame.register_section("shipping", self)


func new_game() -> void:
	bin.clear()
	changed.emit()


func ship(item_id: String, qty: int) -> bool:
	if qty <= 0 or not GameData.item(item_id)["sellable"] or not Inventory.remove(item_id, qty):
		return false
	bin[item_id] = int(bin.get(item_id, 0)) + qty
	changed.emit()
	return true


## Coins that `qty` units of an item fetch in the bin in one day.
func value_of(item_id: String, qty: int) -> int:
	var eco: Dictionary = GameData.config["economy"]
	var def: Dictionary = GameData.item(item_id)
	var unit: float = float(def["baseValue"]) * float(eco["saleRate"]["bin"])
	var flood: Dictionary = eco["binFlood"]
	if int(def["tier"]) < int(flood["tierMin"]):
		return roundi(unit * qty)
	var total := 0.0
	for n: int in range(qty):
		var over := maxi(0, n + 1 - int(flood["freeUnitsPerDay"]))
		total += unit * maxf(float(flood["floor"]), 1.0 - float(flood["dropPerUnit"]) * over)
	return roundi(total)


func pending_value() -> int:
	var total := 0
	for item_id: String in bin:
		total += value_of(item_id, int(bin[item_id]))
	return total


func pay_out() -> int:
	var total := pending_value()
	bin.clear()
	if total > 0:
		GameState.add_coins(total)
		GameState.notice.emit("Shipping bin paid %d coins" % total)
	changed.emit()
	return total


func save_state() -> Dictionary:
	return bin.duplicate(true)


func load_state(data: Dictionary) -> void:
	bin = SaveGame.whole_numbers(data)
	changed.emit()
