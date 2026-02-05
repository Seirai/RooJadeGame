extends Node
class_name ProfessionManager
## Manages AI Roo profession distribution and assignment.
##
## Handles target percentages, rebalancing, and distribution queries.
## Operates on Settlement's _ai_profession_targets dictionary.
## Requires a PopulationManager reference for accessing Roo data.
## Does not own data - receives references via init().

#region Signals

signal profession_changed(roo: Node, old_profession: Enums.Professions, new_profession: Enums.Professions)
signal distribution_changed()

#endregion

#region State References

var _profession_targets: Dictionary
var _population_manager: PopulationManager

#endregion

#region Initialization

func init(profession_targets: Dictionary, population_manager: PopulationManager) -> void:
	_profession_targets = profession_targets
	_population_manager = population_manager

#endregion

#region Public API

## Get the target profession distribution for AI Roos
func get_targets() -> Dictionary:
	return _profession_targets.duplicate()


## Set target percentage for a profession (0.0-1.0)
## Used by streamer/player to manage AI Roo distribution
func set_target(profession: Enums.Professions, percentage: float) -> void:
	percentage = clampf(percentage, 0.0, 1.0)
	_profession_targets[profession] = percentage
	_normalize_targets()
	distribution_changed.emit()


## Get current actual distribution of AI Roo professions
func get_distribution() -> Dictionary:
	var distribution: Dictionary = {}
	for profession in Enums.Professions.values():
		distribution[profession] = 0

	var total_ai = _population_manager.get_ai_count()
	if total_ai == 0:
		return distribution

	for roo in _population_manager._ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			distribution[prof] = distribution.get(prof, 0) + 1

	# Convert to percentages
	for profession in distribution.keys():
		distribution[profession] = float(distribution[profession]) / float(total_ai)

	return distribution


## Rebalance AI Roos to match target distribution
## Called periodically or when targets change
func rebalance_ai() -> void:
	var total_ai = _population_manager.get_ai_count()
	if total_ai == 0:
		return

	# Calculate target counts for each profession
	var target_counts: Dictionary = {}
	for profession in _profession_targets.keys():
		target_counts[profession] = roundi(_profession_targets[profession] * total_ai)

	# Get current counts
	var current_counts: Dictionary = {}
	for profession in Enums.Professions.values():
		current_counts[profession] = 0

	for roo in _population_manager._ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			current_counts[prof] = current_counts.get(prof, 0) + 1

	# Find Roos that need reassignment (excess in current profession)
	var roos_to_reassign: Array[Node] = []
	for roo in _population_manager._ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			var target = target_counts.get(prof, 0)
			var current = current_counts.get(prof, 0)

			if current > target:
				roos_to_reassign.append(roo)
				current_counts[prof] -= 1

	# Assign to professions that need more
	for roo in roos_to_reassign:
		var best_profession = Enums.Professions.NONE
		var best_deficit = 0

		for profession in target_counts.keys():
			var deficit = target_counts[profession] - current_counts.get(profession, 0)
			if deficit > best_deficit:
				best_deficit = deficit
				best_profession = profession

		if best_profession != Enums.Professions.NONE:
			_population_manager.set_roo_profession(roo, best_profession)
			current_counts[best_profession] = current_counts.get(best_profession, 0) + 1

#endregion

#region Internal

## Normalize profession targets to sum to 1.0
func _normalize_targets() -> void:
	var total = 0.0
	for percentage in _profession_targets.values():
		total += percentage

	if total > 0.0 and total != 1.0:
		for profession in _profession_targets.keys():
			_profession_targets[profession] /= total

#endregion
