extends RefCounted
class_name DropTable
## Defines loot drops for combat encounters and other reward sources.
##
## A lightweight drop table that can be configured with items, chances,
## and quantity ranges. Used by enemies, chests, and event rewards.
##
## Usage:
##   var table = DropTable.new()
##   table.add_entry(ItemsLibrary.Items.WOOD, 1.0, 2, 5)  # 100% chance, 2-5 wood
##   table.add_entry(ItemsLibrary.Items.JADE, 0.1, 1, 1)  # 10% chance, 1 jade
##   var drops = table.roll_drops()

#region Types

## A single entry in the drop table
class DropEntry:
	var item_id: int = -1
	var chance: float = 1.0      ## 0.0-1.0 drop probability
	var count_min: int = 1
	var count_max: int = 1
	var weight: float = 1.0      ## For weighted random selection

	func _init(p_item_id: int, p_chance: float = 1.0, p_min: int = 1, p_max: int = 1, p_weight: float = 1.0) -> void:
		item_id = p_item_id
		chance = clampf(p_chance, 0.0, 1.0)
		count_min = maxi(0, p_min)
		count_max = maxi(count_min, p_max)
		weight = maxf(0.0, p_weight)

	func to_dict() -> Dictionary:
		return {
			"item_id": item_id,
			"chance": chance,
			"count_min": count_min,
			"count_max": count_max,
			"weight": weight,
		}

	static func from_dict(data: Dictionary) -> DropEntry:
		return DropEntry.new(
			data.get("item_id", -1),
			data.get("chance", 1.0),
			data.get("count_min", 1),
			data.get("count_max", 1),
			data.get("weight", 1.0)
		)

#endregion

#region Properties

## All drop entries
var entries: Array[DropEntry] = []

## Guaranteed drops (always drop regardless of chance)
var guaranteed: Array[DropEntry] = []

## Maximum total items that can drop (0 = unlimited)
var max_drops: int = 0

## Whether to use weighted selection instead of individual rolls
var use_weighted_selection: bool = false

## Number of picks when using weighted selection
var weighted_picks: int = 1

#endregion

#region Entry Management

## Add a drop entry
func add_entry(item_id: int, chance: float = 1.0, count_min: int = 1, count_max: int = 1, weight: float = 1.0) -> DropTable:
	var entry = DropEntry.new(item_id, chance, count_min, count_max, weight)
	entries.append(entry)
	return self


## Add a guaranteed drop (always drops)
func add_guaranteed(item_id: int, count_min: int = 1, count_max: int = 1) -> DropTable:
	var entry = DropEntry.new(item_id, 1.0, count_min, count_max)
	guaranteed.append(entry)
	return self


## Add entry using ItemsLibrary enum directly
func add_item(item: ItemsLibrary.Items, chance: float = 1.0, count_min: int = 1, count_max: int = 1) -> DropTable:
	return add_entry(item, chance, count_min, count_max)


## Remove all entries for an item
func remove_item(item_id: int) -> void:
	entries = entries.filter(func(e): return e.item_id != item_id)
	guaranteed = guaranteed.filter(func(e): return e.item_id != item_id)


## Clear all entries
func clear() -> void:
	entries.clear()
	guaranteed.clear()


## Set maximum drops
func set_max_drops(max_count: int) -> DropTable:
	max_drops = maxi(0, max_count)
	return self


## Configure for weighted selection mode
func set_weighted_mode(picks: int = 1) -> DropTable:
	use_weighted_selection = true
	weighted_picks = maxi(1, picks)
	return self

#endregion

#region Drop Rolling

## Roll all drops and return results
## @param luck_modifier: Multiplier for drop chances (1.0 = normal)
## @return: Array of { "item_id": int, "count": int }
func roll_drops(luck_modifier: float = 1.0) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	# Always include guaranteed drops
	for entry in guaranteed:
		var count = randi_range(entry.count_min, entry.count_max)
		if count > 0:
			_add_to_results(results, entry.item_id, count)

	# Roll for other drops
	if use_weighted_selection:
		_roll_weighted(results, luck_modifier)
	else:
		_roll_individual(results, luck_modifier)

	# Enforce max drops limit
	if max_drops > 0:
		results = _limit_drops(results, max_drops)

	return results


## Roll each entry individually
func _roll_individual(results: Array[Dictionary], luck_modifier: float) -> void:
	for entry in entries:
		var adjusted_chance = minf(entry.chance * luck_modifier, 1.0)

		if randf() <= adjusted_chance:
			var count = randi_range(entry.count_min, entry.count_max)
			if count > 0:
				_add_to_results(results, entry.item_id, count)


## Roll using weighted random selection
func _roll_weighted(results: Array[Dictionary], luck_modifier: float) -> void:
	if entries.is_empty():
		return

	var total_weight: float = 0.0
	for entry in entries:
		total_weight += entry.weight

	if total_weight <= 0.0:
		return

	for _i in range(weighted_picks):
		var roll = randf() * total_weight
		var cumulative: float = 0.0

		for entry in entries:
			cumulative += entry.weight
			if roll <= cumulative:
				# Still check chance for this entry
				var adjusted_chance = minf(entry.chance * luck_modifier, 1.0)
				if randf() <= adjusted_chance:
					var count = randi_range(entry.count_min, entry.count_max)
					if count > 0:
						_add_to_results(results, entry.item_id, count)
				break


## Add or merge item into results
func _add_to_results(results: Array[Dictionary], item_id: int, count: int) -> void:
	# Check if item already in results, merge if so
	for result in results:
		if result["item_id"] == item_id:
			result["count"] += count
			return

	results.append({
		"item_id": item_id,
		"count": count
	})


## Limit total drops to max amount
func _limit_drops(results: Array[Dictionary], limit: int) -> Array[Dictionary]:
	var total: int = 0
	for result in results:
		total += result["count"]

	if total <= limit:
		return results

	# Proportionally reduce all drops
	var scale: float = float(limit) / float(total)
	var limited: Array[Dictionary] = []
	var remaining: int = limit

	for result in results:
		var new_count = maxi(1, roundi(result["count"] * scale))
		new_count = mini(new_count, remaining)

		if new_count > 0:
			limited.append({
				"item_id": result["item_id"],
				"count": new_count
			})
			remaining -= new_count

		if remaining <= 0:
			break

	return limited

#endregion

#region Utility

## Check if table has any entries
func is_empty() -> bool:
	return entries.is_empty() and guaranteed.is_empty()


## Get total number of entries
func get_entry_count() -> int:
	return entries.size() + guaranteed.size()


## Convert to array format for ItemService.process_drop_table()
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in guaranteed:
		var dict = entry.to_dict()
		dict["guaranteed"] = true
		result.append(dict)

	for entry in entries:
		result.append(entry.to_dict())

	return result


## Create from array format
static func from_array(data: Array) -> DropTable:
	var table = DropTable.new()

	for entry_data in data:
		if entry_data is Dictionary:
			var entry = DropEntry.from_dict(entry_data)
			if entry_data.get("guaranteed", false):
				table.guaranteed.append(entry)
			else:
				table.entries.append(entry)

	return table

#endregion

#region Serialization

## Save to dictionary
func save() -> Dictionary:
	return {
		"entries": entries.map(func(e): return e.to_dict()),
		"guaranteed": guaranteed.map(func(e): return e.to_dict()),
		"max_drops": max_drops,
		"use_weighted_selection": use_weighted_selection,
		"weighted_picks": weighted_picks,
	}


## Load from dictionary
static func load_from(data: Dictionary) -> DropTable:
	var table = DropTable.new()

	table.max_drops = data.get("max_drops", 0)
	table.use_weighted_selection = data.get("use_weighted_selection", false)
	table.weighted_picks = data.get("weighted_picks", 1)

	for entry_data in data.get("entries", []):
		table.entries.append(DropEntry.from_dict(entry_data))

	for entry_data in data.get("guaranteed", []):
		table.guaranteed.append(DropEntry.from_dict(entry_data))

	return table

#endregion
