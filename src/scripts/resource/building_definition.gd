extends Resource
class_name BuildingDefinition
## Data class for static building definitions.
##
## Contains all metadata about a building type: costs, descriptions,
## unlock requirements. Used by BuildingLibrary for static lookups.

## The building type this definition represents
@export var building_type: Enums.BuildingType = Enums.BuildingType.NONE

## Display name
@export var display_name: String = "Building"

## Description shown in UI
@export_multiline var description: String = ""

## Construction cost [ItemsLibrary.Items -> amount]
@export var construction_cost: Dictionary = {}

## Maximum number of this building allowed (0 = unlimited)
@export var max_count: int = 0

## Required progression stage to unlock
@export var required_stage: Enums.ProgressionStage = Enums.ProgressionStage.FOUNDING

## Worker capacity (how many Roos can work here)
@export var worker_capacity: int = 0
