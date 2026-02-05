# Settlement Systems Design

Overall systems design context for the upcoming settlement functionality implementation.

## Architecture Overview

Settlement uses a **Manager Pattern** with Settlement.gd as the coordinator/facade.
Static definitions use the **Library Pattern** (consistent with ItemsLibrary).

## Directory Structure

```
src/scripts/systems/
├── settlement.gd              # Facade - coordinates managers, public API
├── profession_manager.gd      # AI profession distribution & assignment
├── building_manager.gd        # Building lifecycle & spatial queries
├── population_manager.gd      # Roo registration & tracking
├── resource_manager.gd        # Resource inventory & transactions
└── research_manager.gd        # Tech tree & unlocks

src/scripts/resource/
├── building_library.gd        # Static building definitions
└── research_library.gd        # Static research definitions
```

## State Ownership

**Settlement owns all runtime state.** Managers receive references and operate on Settlement's data.
This provides a single source of truth and simplifies serialization.

```gdscript
# Settlement.gd owns all data
var _resources: Dictionary = {}
var _roos: Dictionary = {}
var _viewer_roos: Dictionary = {}
var _ai_roos: Dictionary = {}
var _buildings: Dictionary = {}
var _buildings_by_type: Dictionary = {}
var _profession_targets: Dictionary = {}
var _unlocked_techs: Array = []
var _research_queue: Array = []
var _claimed_tiles: Dictionary = {}

# Managers receive references on init
func _ready() -> void:
    _resource_manager.init(_resources)
    _population_manager.init(_roos, _viewer_roos, _ai_roos)
    # etc.
```

## Manager Specifications

Managers encapsulate **logic**, not data. They operate on Settlement's state.

### ResourceManager
- **Operates on**: `_resources` (from Settlement)
- **Methods**: `deposit()`, `withdraw()`, `can_afford()`, `spend()`, `get_resource()`
- **Signals**: `resource_changed`, `resource_deposited`, `resource_withdrawn`

### PopulationManager
- **Operates on**: `_roos`, `_viewer_roos`, `_ai_roos` (from Settlement)
- **Methods**: `register_roo()`, `unregister_roo()`, `get_by_profession()`, `get_population_count()`
- **Signals**: `roo_joined`, `roo_left`

### ProfessionManager
- **Operates on**: `_profession_targets` (from Settlement), uses PopulationManager
- **Methods**: `assign_profession()`, `rebalance_ai()`, `get_distribution()`, `set_target()`
- **Signals**: `profession_changed`, `distribution_changed`

### BuildingManager
- **Operates on**: `_buildings`, `_buildings_by_type` (from Settlement)
- **Methods**: `register()`, `unregister()`, `find_nearest()`, `find_available()`, `construct()`
- **Signals**: `building_placed`, `building_completed`, `building_destroyed`

### ResearchManager
- **Operates on**: `_unlocked_techs`, `_research_queue` (from Settlement)
- **Methods**: `start_research()`, `unlock_tech()`, `is_unlocked()`, `get_available()`
- **Signals**: `tech_unlocked`, `research_complete`

## Library Pattern (Static Definitions)

### BuildingLibrary
Following ItemsLibrary pattern:
- `enum Buildings { LIVING_QUARTERS, LUMBER_MILL, ... }`
- `get_building(id) -> BuildingDefinition`
- `get_construction_cost(id) -> Dictionary`
- `get_buildings_by_category(category) -> Array`

### ResearchLibrary
- `enum Techs { ADVANCED_TOOLS, JADE_REFINING, ... }`
- `get_tech(id) -> TechDefinition`
- `get_research_cost(id) -> Dictionary`
- `get_prerequisites(id) -> Array`

## Communication Pattern

- **Settlement owns state** - single source of truth for serialization
- **Managers emit signals** - other systems react to changes
- **Cross-manager coordination** goes through Settlement facade
- **Libraries are stateless** - provide static definitions only

## Initialization Order

All managers receive their data references from Settlement during init:

1. ResourceManager - receives `_resources`
2. PopulationManager - receives `_roos`, `_viewer_roos`, `_ai_roos`
3. ProfessionManager - receives `_profession_targets`, reference to PopulationManager
4. BuildingManager - receives `_buildings`, `_buildings_by_type`
5. ResearchManager - receives `_unlocked_techs`, `_research_queue`

## Serialization

Since Settlement owns all state, serialization is straightforward:

```gdscript
func save_state() -> Dictionary:
    return {
        "resources": _resources.duplicate(),
        "roos": _serialize_roos(),
        "buildings": _serialize_buildings(),
        "profession_targets": _profession_targets.duplicate(),
        "unlocked_techs": _unlocked_techs.duplicate(),
        "research_queue": _research_queue.duplicate(),
        "claimed_tiles": _serialize_tiles(),
    }

func load_state(data: Dictionary) -> void:
    _resources = data.get("resources", {})
    # ... restore all state
    # Re-init managers with loaded data
```

## Implementation Phases

### Phase 1: ResourceManager
- Extract resource logic from settlement.gd
- No dependencies, simplest to implement first

### Phase 2: PopulationManager
- Extract roo tracking from settlement.gd

### Phase 3: ProfessionManager
- Extract profession logic from settlement.gd
- Replace current empty placeholder

### Phase 4: BuildingLibrary + BuildingManager
- Static definitions in library, runtime state in manager
- Follow ItemsLibrary pattern

### Phase 5: ResearchLibrary + ResearchManager
- Static definitions in library, runtime state in manager
- Add `Enums.ResearchTech` enum

### Phase 6: Refactor Settlement.gd
- Convert to facade that delegates to managers
- Keep public API stable
- Handle cross-manager coordination
- Manage serialization across all managers
