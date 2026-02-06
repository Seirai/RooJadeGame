# Roo Behavior System Design

A behavior management system for AI-controlled Roos, driving autonomous actions based on profession assignments.

---

## Overview

Roos are the primary workforce of the settlement. Each Roo can be assigned a profession that determines their autonomous behavior. The behavior system must:

- Execute profession-specific tasks without player micromanagement
- Respond to world state changes (threats, resource availability, territory changes)
- Coordinate with settlement systems (ResourceManager, BuildingManager, TerritoryManager)
- Allow for priority overrides (flee from danger, respond to player commands)

---

## Controller Architecture

> **Note**: Consider renaming the existing `Controller` component to `PlayerController` to clarify that it handles player input for controlling a mob.

The control system should have two distinct controller types:

| Component | Purpose | Controls |
|-----------|---------|----------|
| `PlayerController` | Listens for player input (keyboard/gamepad) | Player-controlled mobs (Player, viewer Roos) |
| `AIController` | Receives commands from AI brain | AI-controlled mobs (AI Roos, enemies) |

### Controller Hierarchy

```
Mob
├── PlayerController  (optional - for player-controlled entities)
│   └── Reads input, calls Mob movement/action methods
│
└── AIController      (optional - for AI-controlled entities)
    └── RooBrain
        └── BehaviorTree
            └── Calls AIController methods, which call Mob methods
```

### Why Separate Controllers?

1. **Clean separation of concerns**: Input handling vs AI decision-making
2. **Swappable**: A Roo can switch between player and AI control
3. **Testable**: AI can be tested without input simulation
4. **Consistent interface**: Both controllers call the same Mob methods

### AIController Interface

```gdscript
class_name AIController
extends Node

var mob: Mob  # Owner reference

## Called by RooBrain/BehaviorTree to issue commands
func move_to(target: Vector2) -> void:
    mob.set_movement_target(target)

func stop() -> void:
    mob.stop_movement()

func perform_action(action: String) -> void:
    mob.execute_action(action)

func set_facing(direction: int) -> void:
    mob.facing_direction = direction
```

### Existing Controller Location

The current `Controller` component is at `src/scenes/components/controller.gd`. This should be renamed to `PlayerController` and a new `AIController` created alongside it.

### Future-Proofing: Dynamic Controller Swapping

Design the controller system to support runtime addition/removal of controllers, enabling:

1. **Possess any entity**: Player can take control of any Mob (Roo, enemy, NPC)
2. **Release control**: Return entity to AI control seamlessly
3. **Spectator mode**: Remove all controllers, entity becomes inert
4. **Cutscenes/scripted sequences**: Temporarily override with scripted controller

#### Controller Interface (Base Class)

```gdscript
class_name MobController
extends Node

var mob: Mob
var is_active: bool = true

func _ready() -> void:
    mob = get_parent() as Mob
    if mob:
        _on_attached()

func _on_attached() -> void:
    pass  # Override: setup when attached to mob

func _on_detached() -> void:
    pass  # Override: cleanup when removed from mob

func activate() -> void:
    is_active = true

func deactivate() -> void:
    is_active = false
```

#### Mob Controller Management

```gdscript
# In Mob class
var active_controller: MobController = null

func set_controller(controller: MobController) -> void:
    # Detach current controller
    if active_controller:
        active_controller._on_detached()
        active_controller.deactivate()

    # Attach new controller
    active_controller = controller
    if controller:
        if controller.get_parent() != self:
            add_child(controller)
        controller._on_attached()
        controller.activate()

func remove_controller() -> void:
    set_controller(null)

func get_controller() -> MobController:
    return active_controller
```

#### Use Cases

| Scenario | Implementation |
|----------|----------------|
| Player possesses Roo | `roo.set_controller(PlayerController.new())` |
| Release Roo to AI | `roo.set_controller(AIController.new())` |
| Debug: freeze entity | `mob.remove_controller()` |
| Cutscene control | `mob.set_controller(ScriptedController.new(cutscene_data))` |

#### Camera Follows Active Possession

When player possesses a new entity:
```gdscript
func possess(target_mob: Mob) -> void:
    # Release current possession
    if current_possessed:
        current_possessed.set_controller(AIController.new())

    # Take control of new target
    current_possessed = target_mob
    target_mob.set_controller(player_controller)

    # Camera follows new target
    GameManager.CameraService.set_follow_target(target_mob)
```

#### Signals for Controller Changes

```gdscript
# In Mob
signal controller_changed(old_controller: MobController, new_controller: MobController)
signal possessed_by_player()
signal released_from_player()
```

This architecture enables gameplay features like:
- Mind control abilities
- Debugging by possessing any entity
- Tutorial sequences controlling the player
- Multiplayer where players can swap controlled units

---

## Professions Recap

From `Enums.Professions`:

| Profession | Role | Primary Activity |
|------------|------|------------------|
| NONE | Unassigned | Idle, wander near settlement |
| SCOUT | Explorer | Reveal fog of war, detect threats, claim territory |
| LUMBERJACK | Resource gatherer | Harvest wood from forests/lumber mills |
| MINER | Resource gatherer | Extract stone and jade from quarries/deposits |
| BUILDER | Constructor | Build and repair settlement structures |
| FIGHTER | Combat | Patrol, defend, engage hostiles |

---

## Architecture Options

### Option A: Hierarchical State Machine (HSM)

```
RooBrain
├── GlobalState (handles interrupts: flee, die, player command)
└── ProfessionState (active profession behavior)
    ├── IdleState
    ├── MoveToTargetState
    ├── WorkState
    └── ReturnState
```

**Pros:**
- Simple to understand and debug
- Clear state transitions
- Low overhead

**Cons:**
- Complex professions lead to state explosion
- Hard to share behaviors across professions
- Difficult to add nuanced decision-making

### Option B: Behavior Tree (BT)

```
RooBehaviorTree
├── Selector (Priority)
│   ├── Sequence [Danger Response]
│   │   ├── Condition: IsThreatNearby
│   │   └── Action: FleeToSafety
│   ├── Sequence [Profession Work]
│   │   ├── Condition: HasAssignedProfession
│   │   └── SubTree: ProfessionBehavior
│   └── Action: IdleWander
```

**Pros:**
- Modular and reusable subtrees
- Easy to add/modify behaviors
- Natural priority handling
- Industry standard for game AI

**Cons:**
- More complex initial setup
- Requires BT implementation or plugin
- Debugging can be harder without visualization

### Option C: Utility AI

Score-based decision making where each action has a utility function.

**Pros:**
- Emergent, natural-feeling behavior
- Handles competing priorities smoothly
- Very flexible

**Cons:**
- Harder to predict/debug
- Requires careful tuning
- May feel "mushy" without clear priorities

### Decision: Option B - Behavior Tree

**Chosen approach**: Pure Behavior Tree implementation.

The BT approach provides the best balance of modularity, reusability, and maintainability for this project. Key reasons:

1. **Profession subtrees** can be swapped cleanly when profession changes
2. **Common behaviors** (MoveTo, Flee, Idle) are shared across all professions
3. **Priority handling** is built into selector nodes - danger always takes precedence
4. **Industry standard** - well-documented patterns and potential plugin support (e.g., Beehave)
5. **Visual debugging** possible with BT visualization tools

Action nodes will contain simple linear logic rather than nested state machines to keep complexity manageable.

---

## Core Behavior Components

### 1. RooBrain (Main Controller)

```gdscript
class_name RooBrain
extends Node

var roo: Roo  # Owner reference
var behavior_tree: BehaviorTree
var blackboard: Dictionary = {}  # Shared data for BT nodes

func _process(delta: float) -> void:
    behavior_tree.tick(delta)
```

### 2. Blackboard (Shared Context)

Data accessible to all behavior nodes:

```gdscript
blackboard = {
    # World references
    "settlement": Settlement,
    "world_grid": WorldGrid,

    # Current state
    "current_target": Vector2,
    "current_task": Task,
    "home_position": Vector2,

    # Perception
    "nearby_threats": Array[Node],
    "nearby_resources": Array[Vector2i],
    "visible_tiles": Array[Vector2i],

    # Profession-specific
    "work_site": Node,  # Building being worked at
    "resource_type": Enums.ResourceType,
    "carried_resources": Dictionary,
}
```

### 3. Common Action Nodes

Reusable across all professions:

| Node | Type | Description |
|------|------|-------------|
| `MoveTo` | Action | Navigate to blackboard["current_target"] |
| `IsAtTarget` | Condition | Check if within range of target |
| `IsThreatNearby` | Condition | Scan for hostiles within perception radius |
| `FleeToSafety` | Action | Move toward settlement center |
| `Wait` | Action | Idle for duration |
| `FindPath` | Action | Calculate path, store in blackboard |
| `FollowPath` | Action | Move along calculated path |

---

## Profession Behaviors

### NONE (Unassigned)

Simple idle behavior while awaiting assignment.

```
Selector
├── Sequence [Wander]
│   ├── Condition: IdleTimerExpired
│   ├── Action: PickRandomNearbyPoint
│   └── Action: MoveTo
└── Action: Idle
```

**Behaviors:**
- Wander within claimed territory
- Stay near settlement center
- Avoid leaving safe zones

---

### SCOUT

Exploration and territory expansion.

```
Selector
├── Sequence [Report Threat]
│   ├── Condition: SpottedThreat
│   └── Action: ReportThreatToSettlement
├── Sequence [Explore Frontier]
│   ├── Action: FindFrontierTile
│   ├── Condition: FoundTarget
│   ├── Action: MoveTo
│   └── Action: ScoutTile
├── Sequence [Return Home]
│   ├── Condition: TooFarFromSettlement
│   └── Action: ReturnToSettlement
└── Action: PatrolTerritory
```

**Key Methods:**
```gdscript
func find_frontier_tile() -> Vector2i:
    # Query WorldGrid for UNKNOWN tiles adjacent to SCOUTED/CLAIMED
    var frontier = world_grid.get_frontier_cells()
    # Prioritize tiles closer to settlement or strategic locations
    return _select_best_frontier(frontier)

func scout_tile(cell: Vector2i) -> void:
    # Reveal tile, check for threats/resources
    settlement.scout_tile(cell, roo.roo_id)
    # Trigger auto-claim if conditions met
    settlement.try_claim_tile(cell)
```

**Integration Points:**
- `WorldGrid.get_frontier_cells()` for exploration targets
- `Settlement.scout_tile()` to mark tiles as SCOUTED
- `Settlement.report_threat()` when hostiles detected
- `TerritoryManager` for auto-claiming scouted tiles

---

### LUMBERJACK

Wood harvesting from forests and lumber mills.

```
Selector
├── Sequence [Deposit Resources]
│   ├── Condition: InventoryFull
│   ├── Action: FindStorageBuilding
│   ├── Action: MoveTo
│   └── Action: DepositResources
├── Sequence [Harvest Wood]
│   ├── Action: FindHarvestSite (Forest/LumberMill)
│   ├── Condition: FoundTarget
│   ├── Action: MoveTo
│   └── Action: HarvestResource
└── Action: IdleAtWorksite
```

**Key Methods:**
```gdscript
func find_harvest_site() -> Node:
    # Priority: assigned lumber mill > nearest forest tile > any forest
    var lumber_mills = settlement.get_buildings(Enums.BuildingType.LUMBER_MILL)
    if not lumber_mills.is_empty():
        return _find_available_worksite(lumber_mills)

    # Fallback to natural forest tiles
    var forest_tiles = world_grid.get_cells_by_terrain(Enums.TerrainType.FOREST)
    return _nearest_claimable(forest_tiles)

func harvest_resource(site: Node, duration: float) -> void:
    # Play harvesting animation
    roo.sprite_node.play("harvesting")
    # Yield resource over time
    await get_tree().create_timer(duration).timeout
    _add_to_inventory(Enums.ResourceType.WOOD, harvest_amount)
```

**Resource Flow:**
1. Find work site (lumber mill or forest tile)
2. Travel to site
3. Harvest for duration (play animation)
4. Add to personal inventory
5. When inventory full, travel to storage
6. Deposit resources into settlement
7. Repeat

---

### MINER

Stone and jade extraction.

```
Selector
├── Sequence [Deposit Resources]
│   ├── Condition: InventoryFull
│   ├── Action: FindStorageBuilding
│   ├── Action: MoveTo
│   └── Action: DepositResources
├── Sequence [Mine Jade] (higher priority)
│   ├── Condition: JadeVeinAvailable
│   ├── Action: FindJadeVein
│   ├── Action: MoveTo
│   └── Action: MineResource
├── Sequence [Mine Stone]
│   ├── Action: FindQuarry
│   ├── Action: MoveTo
│   └── Action: MineResource
└── Action: IdleAtWorksite
```

**Jade Priority:**
- Jade is rare and valuable
- Miners should prioritize jade veins when available
- Stone is fallback when no jade accessible

**Integration:**
- `WorldGrid.get_cells_by_terrain(JADE_VEIN)` for jade deposits
- `WorldGrid.get_cells_by_terrain(ROCK)` for stone quarries
- Check `is_passable()` and `is_buildable()` for accessibility

---

### BUILDER

Construction and repair of settlement structures.

```
Selector
├── Sequence [Repair Damaged]
│   ├── Condition: DamagedBuildingsExist
│   ├── Action: FindDamagedBuilding
│   ├── Action: MoveTo
│   └── Action: RepairBuilding
├── Sequence [Construct Queued]
│   ├── Condition: ConstructionQueueNotEmpty
│   ├── Action: GetNextConstruction
│   ├── Action: CheckResourcesAvailable
│   ├── Action: MoveTo
│   └── Action: ConstructBuilding
└── Action: IdleAtConstructionYard
```

**Construction Process:**
```gdscript
func construct_building(blueprint: BuildingBlueprint, cell: Vector2i) -> void:
    # Verify resources still available
    if not settlement.can_afford(blueprint.cost):
        blackboard["construction_blocked"] = true
        return

    # Reserve resources
    settlement.reserve_resources(blueprint.cost)

    # Construction progress over time
    roo.sprite_node.play("building")
    var progress = 0.0
    while progress < 1.0:
        progress += construction_speed * delta
        emit_signal("construction_progress", progress)
        await next_frame

    # Spawn completed building
    settlement.complete_construction(blueprint, cell)
```

**Construction Queue:**
- Player queues buildings via UI
- Builders pick from queue in priority order
- Multiple builders can work on same large building

---

### FIGHTER

Combat and defense.

```
Selector
├── Sequence [Engage Threat]
│   ├── Condition: ThreatInRange
│   ├── Action: SelectTarget
│   ├── Action: MoveToAttackRange
│   └── Action: Attack
├── Sequence [Pursue Threat]
│   ├── Condition: ThreatSpotted
│   ├── Action: MoveTo
│   └── Action: Engage
├── Sequence [Patrol]
│   ├── Condition: OnPatrolDuty
│   ├── Action: GetNextPatrolPoint
│   └── Action: MoveTo
└── Action: GuardPosition
```

**Combat Integration:**
- Use existing `Mob` combat systems (health, damage, etc.)
- Coordinate with other fighters for group tactics
- Retreat when health low
- Call for reinforcements when outnumbered

**Patrol Routes:**
- Auto-generated based on territory boundaries
- Focus on frontier tiles
- Respond to `Settlement.threat_detected` signal

---

## Perception System

How Roos sense their environment:

### Vision Cone / Radius

```gdscript
@export var perception_radius: float = 200.0
@export var threat_detection_radius: float = 150.0

func _update_perception() -> void:
    # Find nearby entities
    var nearby = _get_bodies_in_radius(perception_radius)

    blackboard["nearby_threats"] = nearby.filter(func(n): return _is_threat(n))
    blackboard["nearby_allies"] = nearby.filter(func(n): return n is Roo)
    blackboard["nearby_resources"] = _scan_resource_tiles()
```

### Threat Detection

```gdscript
func _is_threat(node: Node) -> bool:
    if node.has_method("get_faction"):
        return node.get_faction() != Enums.Faction.SETTLEMENT
    return false

func _on_threat_detected(threat: Node) -> void:
    # Report to settlement
    settlement.report_threat(threat.global_position, threat.name)
    # Update blackboard for immediate response
    blackboard["immediate_threat"] = threat
```

---

## Task Assignment Flow

How professions get assigned and work begins:

```
1. Player/AI assigns profession via Settlement.assign_profession(roo, profession)
2. Settlement.ProfessionManager validates and updates roo.profession
3. roo.profession setter emits profession_changed signal
4. RooBrain receives signal, swaps behavior subtree
5. New profession behavior begins executing
```

### Profession Change Handler

```gdscript
# In RooBrain
func _on_profession_changed(new_profession: Enums.Professions) -> void:
    # Clear current task state
    _abort_current_action()
    blackboard.clear()

    # Load appropriate behavior subtree
    var subtree = _get_profession_subtree(new_profession)
    behavior_tree.set_profession_subtree(subtree)

    # Initialize profession-specific blackboard data
    _init_profession_data(new_profession)
```

---

## Work Sites and Job Allocation

Prevent multiple Roos from targeting the same resource:

### Job Reservation System

```gdscript
# In Settlement or dedicated JobManager
var _reserved_jobs: Dictionary = {}  # job_id -> roo_id

func reserve_job(job_id: String, roo_id: int) -> bool:
    if _reserved_jobs.has(job_id):
        return false  # Already taken
    _reserved_jobs[job_id] = roo_id
    return true

func release_job(job_id: String, roo_id: int) -> void:
    if _reserved_jobs.get(job_id) == roo_id:
        _reserved_jobs.erase(job_id)

func get_available_jobs(profession: Enums.Professions) -> Array:
    var all_jobs = _get_jobs_for_profession(profession)
    return all_jobs.filter(func(j): return not _reserved_jobs.has(j.id))
```

### Work Site Capacity

Buildings can have worker capacity:

```gdscript
# In Building base class
@export var max_workers: int = 1
var current_workers: Array[Roo] = []

func can_accept_worker() -> bool:
    return current_workers.size() < max_workers

func assign_worker(roo: Roo) -> void:
    if can_accept_worker():
        current_workers.append(roo)

func release_worker(roo: Roo) -> void:
    current_workers.erase(roo)
```

---

## Priority Overrides

Global behaviors that interrupt profession work:

### Priority Levels

```gdscript
enum Priority {
    IDLE = 0,
    PROFESSION_WORK = 10,
    LOW_HEALTH = 20,
    PLAYER_COMMAND = 30,
    THREAT_RESPONSE = 40,
    FLEE = 50,
    DEATH = 100,
}
```

### Interrupt Handling

```gdscript
func _check_interrupts() -> bool:
    # Check in priority order (highest first)

    if roo.health_component.is_dead():
        _trigger_interrupt(Priority.DEATH)
        return true

    if blackboard.get("immediate_threat") and not is_fighter:
        _trigger_interrupt(Priority.FLEE)
        return true

    if roo.health_component.health_percent < 0.25:
        _trigger_interrupt(Priority.LOW_HEALTH)
        return true

    if blackboard.get("player_command"):
        _trigger_interrupt(Priority.PLAYER_COMMAND)
        return true

    return false
```

---

## Animation Integration

DebugSprite shows state, future AnimatedSprite2D plays actual animations:

### State-to-Animation Mapping

```gdscript
const PROFESSION_ANIMATIONS = {
    Enums.Professions.SCOUT: {
        "work": "scouting",
        "move": "run",
        "idle": "idle",
    },
    Enums.Professions.LUMBERJACK: {
        "work": "harvesting",
        "move": "run",
        "idle": "idle",
    },
    Enums.Professions.MINER: {
        "work": "harvesting",  # Reuse or create "mining"
        "move": "run",
        "idle": "idle",
    },
    Enums.Professions.BUILDER: {
        "work": "building",
        "move": "run",
        "idle": "idle",
    },
    Enums.Professions.FIGHTER: {
        "work": "attack",
        "move": "run",
        "idle": "idle",
        "patrol": "run",
    },
}

func play_profession_animation(action: String) -> void:
    var anims = PROFESSION_ANIMATIONS.get(roo.profession, {})
    var anim_name = anims.get(action, "idle")
    roo.sprite_node.play(anim_name)
```

---

## File Structure

```
src/scripts/ai/
├── roo_brain.gd              # Main behavior controller
├── blackboard.gd             # Shared data container
├── behavior_tree/
│   ├── behavior_tree.gd      # BT executor
│   ├── bt_node.gd            # Base node class
│   ├── bt_selector.gd        # Selector composite
│   ├── bt_sequence.gd        # Sequence composite
│   ├── bt_condition.gd       # Condition node base
│   └── bt_action.gd          # Action node base
├── actions/
│   ├── move_to.gd
│   ├── harvest_resource.gd
│   ├── deposit_resources.gd
│   ├── scout_tile.gd
│   ├── construct_building.gd
│   ├── attack_target.gd
│   └── flee_to_safety.gd
├── conditions/
│   ├── is_threat_nearby.gd
│   ├── is_inventory_full.gd
│   ├── has_target.gd
│   └── is_at_target.gd
└── profession_trees/
    ├── scout_tree.gd
    ├── lumberjack_tree.gd
    ├── miner_tree.gd
    ├── builder_tree.gd
    └── fighter_tree.gd
```

---

## Implementation Phases

### Phase 1: Core Framework
- [ ] Implement basic BehaviorTree executor
- [ ] Create Blackboard system
- [ ] Implement RooBrain controller
- [ ] Add MoveTo action with pathfinding

### Phase 2: Basic Professions
- [ ] Implement NONE/Idle behavior
- [ ] Implement SCOUT behavior (explore, reveal tiles)
- [ ] Integrate with TerritoryManager

### Phase 3: Resource Gathering
- [ ] Implement LUMBERJACK behavior
- [ ] Implement MINER behavior
- [ ] Add inventory system to Roo
- [ ] Resource deposit flow

### Phase 4: Building & Combat
- [ ] Implement BUILDER behavior
- [ ] Construction queue system
- [ ] Implement FIGHTER behavior
- [ ] Threat response and patrol

### Phase 5: Polish
- [ ] Job reservation system
- [ ] Multi-Roo coordination
- [ ] Priority interrupts
- [ ] Animation integration
- [ ] Debug visualization (pathfinding, targets)

---

## Open Questions

1. **Pathfinding**: Use Godot's NavigationServer2D or custom A* on WorldGrid?
2. **Behavior Tree Plugin**: Use existing addon (e.g., Beehave) or roll custom?
3. **Roo Inventory**: How much can a Roo carry? Affects trip frequency.
4. **Night/Day Cycle**: Do Roos rest at night? Return home?
5. **Happiness/Morale**: Does it affect work efficiency?
6. **Specialization**: Can Roos level up in their profession?
7. **Player Control**: Can player directly command individual Roos?

---

## References

- Existing `Enums.Professions` in enums.gd
- `Settlement` facade for resource/building/population APIs
- `WorldGrid` for terrain and territory queries
- `TerritoryManager` for scouting/claiming
- `DebugSprite` for state visualization during development
