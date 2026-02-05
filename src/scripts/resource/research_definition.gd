extends Resource
class_name ResearchDefinition
## Data class for static research/tech definitions.
##
## Contains all metadata about a research technology: costs, prerequisites,
## descriptions. Used by ResearchLibrary for static lookups.

## The tech this definition represents
@export var tech_id: Enums.ResearchTech

## Display name
@export var display_name: String = "Research"

## Description shown in UI
@export_multiline var description: String = ""

## Research cost [ItemsLibrary.Items -> amount]
@export var research_cost: Dictionary = {}

## Required progression stage to begin research
@export var required_stage: Enums.ProgressionStage = Enums.ProgressionStage.ESTABLISHED

## Prerequisite techs that must be unlocked first
@export var prerequisites: Array[Enums.ResearchTech] = []

## Research duration in seconds (for game-time pacing)
@export var duration: float = 60.0
