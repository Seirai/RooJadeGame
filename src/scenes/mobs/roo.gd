extends Mob
class_name Roo
## Roo - A citizen of the settlement.
##
## Roos are the primary workforce of the settlement, performing various
## professions like scouting, lumber harvesting, mining, building, and fighting.

#region Signals

signal profession_changed(new_profession: Enums.Professions)

#endregion

#region Properties

## Reference to the AI brain (if present)
var roo_brain: RooBrain = null

## Current profession assignment
var profession: Enums.Professions = Enums.Professions.NONE:
	set(value):
		if profession != value:
			profession = value
			_update_debug_info()
			profession_changed.emit(value)

## Unique Roo ID (set by PopulationManager)
var roo_id: int = -1:
	set(value):
		roo_id = value
		_update_debug_name()

## Whether this is a viewer-controlled Roo or AI-controlled
var is_viewer_controlled: bool = false

#endregion

#region Lifecycle

func _ready() -> void:
	super._ready()
	roo_brain = get_node_or_null("RooBrain") as RooBrain
	_update_debug_name()
	_update_debug_info()


func _update_debug_name() -> void:
	if sprite_node and sprite_node is DebugSprite:
		var name_str = "Roo"
		if roo_id >= 0:
			name_str = "Roo #%d" % roo_id
		if is_viewer_controlled:
			name_str += " [P]"
		sprite_node.set_display_name(name_str)


func _update_debug_info() -> void:
	if sprite_node and sprite_node is DebugSprite:
		var prof_name = Enums.Professions.keys()[profession]
		sprite_node.set_info(prof_name)

#endregion

#region Public API

## Assign a profession to this Roo
func set_profession(new_profession: Enums.Professions) -> void:
	profession = new_profession


## Get the current profession
func get_profession() -> Enums.Professions:
	return profession


## Mark this Roo as viewer-controlled
func set_viewer_controlled(controlled: bool) -> void:
	is_viewer_controlled = controlled
	_update_debug_name()

#endregion
