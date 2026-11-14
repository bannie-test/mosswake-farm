extends Node
## NPC delivery orders and the reward pipeline (GDD section 8; spec section 5). Autoload: Orders.
## M1 fills the board from a fixed list; the generator of section 8 replaces `_next_order` in M2.

signal changed
signal delivered(order: Dictionary)

var orders: Array = []                 # open OrderDefinition dictionaries
var slot_refill_at: Dictionary = {}    # "npc_id/slot" -> game minute the slot refills
var _fixed: Array = []                 # M1 scaffolding: the fixed order list
var _fixed_next := 0
var _serial := 0
var _last_gift_day := 0


func _ready() -> void:
	Sim.register(self)
	Sim.dawn.connect(_on_dawn)


func new_game(fixed_orders: Array) -> void:
	orders.clear()
	slot_refill_at.clear()
	_fixed = fixed_orders
	_fixed_next = 0
	_serial = 0
	_last_gift_day = 0
	_fill_slots()


func advance(_delta_minutes: float) -> void:
	for key: String in slot_refill_at.keys():
		if Sim.game_minute + _delta_minutes >= float(slot_refill_at[key]):
			slot_refill_at.erase(key)
			_fill_slots()


func _slot_of(order: Dictionary) -> String:
	return order["slot"]


func _fill_slots() -> void:
	var added := false
	for npc_id: String in GameData.ids("npcs"):
		var slots := int(GameData.def("npcs", npc_id)["orderRules"]["deliverySlots"])
		for slot: int in range(slots):
			var key := "%s/%d" % [npc_id, slot + 1]
			if slot_refill_at.has(key) or orders.any(func(o: Dictionary) -> bool: return o["slot"] == key):
				continue
			var order := _next_order(npc_id)
			if order.is_empty():
				continue
			order["slot"] = key
			orders.append(order)
			added = true
	if added:
		changed.emit()


func _next_order(npc_id: String) -> Dictionary:
	for i: int in range(_fixed.size()):
		var template: Dictionary = _fixed[(_fixed_next + i) % _fixed.size()]
		if template["npcId"] == npc_id:
			_fixed_next = (_fixed_next + i + 1) % _fixed.size()
			return build_order(npc_id, template["lines"], template.get("bonusItems", []))
	return {}


## An OrderDefinition with rewards from the section 10 formulas.
func build_order(npc_id: String, lines: Array, bonus_items: Array = []) -> Dictionary:
	var eco: Dictionary = GameData.config["economy"]
	var value := 0.0
	var out_lines: Array = []
	for line: Dictionary in lines:
		value += int(line["qty"]) * float(GameData.item(line["itemId"])["baseValue"])
		out_lines.append({"itemId": line["itemId"], "qty": int(line["qty"]), "minQuality": int(line.get("minQuality", 1))})
	_serial += 1
	return {
		"orderId": "ord_%06d" % _serial,
		"npcId": npc_id,
		"category": "delivery",
		"lines": out_lines,
		"rewards": {
			"coins": roundi(value * float(eco["saleRate"]["delivery"])),
			"xp": roundi(value * float(eco["xpRate"]["delivery"])),
			"reputation": int(GameData.config["reputation"]["delivery"]),
			"bonusItems": bonus_items.duplicate(true),
		},
		"createdAt": int(Sim.game_minute),
		"expiresAt": null,
		"pinnedForSpirit": false,
	}


func orders_for(npc_id: String) -> Array:
	return orders.filter(func(o: Dictionary) -> bool: return o["npcId"] == npc_id)


func can_deliver(order: Dictionary) -> bool:
	for line: Dictionary in order["lines"]:
		if Inventory.count(line["itemId"], int(line["minQuality"])) < int(line["qty"]):
			return false
	return true


## Hand over the goods and pay the rewards. Returns false and changes nothing when a line is short.
func deliver(order_id: String) -> bool:
	var order: Dictionary = {}
	for o: Dictionary in orders:
		if o["orderId"] == order_id:
			order = o
	if order.is_empty() or not can_deliver(order):
		return false
	for line: Dictionary in order["lines"]:
		Inventory.remove(line["itemId"], int(line["qty"]), int(line["minQuality"]))
	var rewards: Dictionary = order["rewards"]
	GameState.add_coins(int(rewards["coins"]))
	GameState.add_reputation(order["npcId"], int(rewards["reputation"]))
	for bonus: Dictionary in rewards["bonusItems"]:
		Inventory.add(bonus["itemId"], int(bonus["qty"]))
	GameState.player["stats"]["ordersCompleted"] += 1
	GameState.add_xp(int(rewards["xp"]))
	orders.erase(order)
	slot_refill_at[order["slot"]] = Sim.game_minute + float(GameData.config["orders"]["refillMinutes"]["completed"])
	delivered.emit(order)
	changed.emit()
	return true


## Deadlock rule (section 10): a player with no coins, no seeds and nothing growing gets Carrot
## seeds from Mara, once per game day.
func _on_dawn(day: int) -> void:
	check_deadlock(day)


func check_deadlock(day: int) -> bool:
	var rule: Dictionary = GameData.config["economy"]["deadlock"]
	if day == _last_gift_day or GameState.coins() >= int(rule["coinsBelow"]) or Farm.anything_growing():
		return false
	for item_id: String in GameData.ids("items"):
		var def: Dictionary = GameData.item(item_id)
		if (def["category"] == "seed" or def["sellable"]) and Inventory.count(item_id) > 0:
			return false
	_last_gift_day = day
	Inventory.add(rule["giftItemId"], int(rule["giftQty"]))
	GameState.notice.emit("%s left you %d %s" % [GameData.def("npcs", rule["giverNpcId"])["name"].get_slice(" ", 0), int(rule["giftQty"]), GameData.item(rule["giftItemId"])["name"]])
	return true
