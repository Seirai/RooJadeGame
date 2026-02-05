extends Node
class_name ResourceManager
## Manages settlement resource inventory and transactions.
##
## Operates on Settlement's _resources and _stats dictionaries.
## Does not own data - receives references via init().

#region Signals

signal resource_changed(resource_id: int, old_amount: int, new_amount: int)
signal resource_deposited(resource_id: int, amount: int, depositor: Node)
signal resource_withdrawn(resource_id: int, amount: int)

#endregion

#region State References

var _resources: Dictionary
var _stats: Dictionary

#endregion

#region Initialization

func init(resources: Dictionary, stats: Dictionary) -> void:
	_resources = resources
	_stats = stats
	_ensure_resources_initialized()


## Ensure all resource types have an entry
func _ensure_resources_initialized() -> void:
	for item_id in ItemsLibrary.Items.values():
		if not _resources.has(item_id):
			_resources[item_id] = 0

#endregion

#region Public API

## Get current amount of a resource
func get_resource(resource_id: int) -> int:
	return _resources.get(resource_id, 0)


## Get all resources as dictionary
func get_all_resources() -> Dictionary:
	return _resources.duplicate()


## Add resources to settlement inventory
func deposit(resource_id: int, amount: int, depositor: Node = null) -> void:
	if amount <= 0:
		return

	var old_amount = _resources.get(resource_id, 0)
	var new_amount = old_amount + amount
	_resources[resource_id] = new_amount

	# Track statistics
	match resource_id:
		ItemsLibrary.Items.WOOD:
			_stats["total_wood_collected"] = _stats.get("total_wood_collected", 0) + amount
		ItemsLibrary.Items.STONE:
			_stats["total_stone_collected"] = _stats.get("total_stone_collected", 0) + amount
		ItemsLibrary.Items.JADE:
			_stats["total_jade_collected"] = _stats.get("total_jade_collected", 0) + amount

	resource_changed.emit(resource_id, old_amount, new_amount)
	resource_deposited.emit(resource_id, amount, depositor)


## Remove resources from settlement inventory
## Returns actual amount withdrawn (may be less if insufficient)
func withdraw(resource_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var old_amount = _resources.get(resource_id, 0)
	var actual_withdraw = mini(amount, old_amount)

	if actual_withdraw > 0:
		var new_amount = old_amount - actual_withdraw
		_resources[resource_id] = new_amount
		resource_changed.emit(resource_id, old_amount, new_amount)
		resource_withdrawn.emit(resource_id, actual_withdraw)

	return actual_withdraw


## Check if settlement has enough of a resource
func has_resource(resource_id: int, amount: int) -> bool:
	return get_resource(resource_id) >= amount


## Check if settlement can afford a cost (dictionary of resource_id -> amount)
func can_afford(cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if not has_resource(resource_id, cost[resource_id]):
			return false
	return true


## Spend resources (returns true if successful)
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false

	for resource_id in cost.keys():
		withdraw(resource_id, cost[resource_id])
	return true

#endregion
