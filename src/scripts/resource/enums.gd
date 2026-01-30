extends Node
## All global enums in the game
## This autoload provides a single source of truth for all game constants

#region Professions

enum Professions {
	NONE,       ## Unassigned
	SCOUT,      ## Explores frontier, claims territory, detects threats
	LUMBERJACK, ## Harvests wood from lumber mills
	MINER,      ## Extracts stone and jade from quarries
	BUILDER,    ## Constructs settlement infrastructure
	FIGHTER,    ## Combat unit for hostile encounters
}

#endregion

#region Combat

## Health state enum
enum HealthState {
	ALIVE,          ## Normal functional state
	DEAD,           ## Entity has died (used for players, NPCs, mobs, and destructible objects)
	RECOVERY,       ## Cannot die, enters recovery mode instead
	INCAPACITATED   ## Downed but not dead (e.g., for revive mechanics)
}

## Damage types for combat calculations
enum DamageType {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	POISON,
	MAGIC,
	TRUE  ## Ignores resistances
}

## Team enum for damage filtering
## Determines which entities can damage each other
enum Team {
	NEUTRAL,        ## Can be damaged by anyone, damages no one by default
	PLAYER,         ## Player and player allies
	ENEMY,          ## Enemies and hostile NPCs
	ENVIRONMENT,    ## Environmental hazards (damages all except ENVIRONMENT)
	DESTRUCTIBLE    ## Destructible objects (damaged by PLAYER and ENEMY)
}

#endregion

#region Settlement

## Building types in the settlement
enum BuildingType {
	NONE,
	LIVING_QUARTERS,  ## Housing for Roos
	LUMBER_MILL,      ## Wood production
	STONE_QUARRY,     ## Stone production
	JADE_QUARRY,      ## Jade production (premium)
	DEPOT,            ## Resource storage
	RESEARCH_FACILITY,## Unlocks Scientist profession and tech
	WORKSHOP,         ## Equipment crafting
}

## Settlement progression stages
enum ProgressionStage {
	FOUNDING,     ## Initial stage, minimal buildings
	ESTABLISHED,  ## Basic infrastructure complete
	GROWING,      ## Expanding territory
	THRIVING,     ## Advanced buildings and research
	ADVANCED,     ## Near jade asteroid
}

#endregion

#region Items

## Item categories
enum ItemType {
	MISC,           ## Generic item
	COLLECTIBLE,    ## Picked up and counted (coins, gems)
	CONSUMABLE,     ## Single-use items (potions, food)
	EQUIPMENT,      ## Wearable/usable items
	KEY_ITEM,       ## Quest/progression items
	MATERIAL        ## Crafting materials
}

## Item rarity tiers
enum Rarity {
	COMMON,         ## White/Gray - 60% base
	UNCOMMON,       ## Green - 25% base
	RARE,           ## Blue - 10% base
	EPIC,           ## Purple - 4% base
	LEGENDARY       ## Orange/Gold - 1% base
}

#endregion