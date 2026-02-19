extends CanvasLayer
class_name DevConsole
## In-game developer console for runtime game state inspection and manipulation.
##
## Toggle with the backtick / grave (`) key. Blocked from production builds via
## export preset filter: src/scenes/components/debug/*
##
## Bootstrapped by GameManager._maybe_init_dev_console() using load() at runtime
## so no static preload reference to this file survives a production export.
##
## Adding a command:
##   register("name", _cmd_name, "Description.", "name <arg>")
##   func _cmd_name(args: Array) -> void: ...

#region Nodes

@onready var _output: RichTextLabel = $Panel/Margin/VBox/Output
@onready var _input_field: LineEdit = $Panel/Margin/VBox/InputRow/Input

#endregion

#region State

## Command registry: name -> {callable, description, usage}
var _commands: Dictionary = {}

## Input history for up/down arrow navigation
var _history: PackedStringArray = []
var _history_cursor: int = -1

#endregion

#region Resource name lookup (matches ItemsLibrary.Items enum order)

const _RESOURCE_NAMES: Dictionary = {
	"wood":  ItemsLibrary.Items.WOOD,
	"stone": ItemsLibrary.Items.STONE,
	"jade":  ItemsLibrary.Items.JADE,
}

#endregion

#region Lifecycle

func _ready() -> void:
	hide()
	_input_field.text_submitted.connect(_on_input_submitted)
	_input_field.gui_input.connect(_on_input_gui_input)
	_register_all_commands()
	_info("[DevConsole] Ready. Type [color=cyan]help[/color] to list commands.")


func _unhandled_input(event: InputEvent) -> void:
	# Open the console. Closing is handled in _on_input_gui_input while LineEdit has focus.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_toggle()
			get_viewport().set_input_as_handled()

#endregion

#region Command Registration

## Register a command. Handler signature: func(args: Array) -> void
func register(cmd_name: String, handler: Callable, description: String, usage: String = "") -> void:
	_commands[cmd_name.to_lower()] = {
		"callable":    handler,
		"description": description,
		"usage":       usage if not usage.is_empty() else cmd_name,
	}


func _register_all_commands() -> void:
	register("help",       _cmd_help,       "List all commands, or show usage for one.",            "help [command]")
	register("clear",      _cmd_clear,      "Clear the console output.")
	register("player",     _cmd_player,     "Player info and control.",                             "player pos | player tp <x> <y>")
	register("mobs",       _cmd_mobs,       "List active mobs.",                                    "mobs list | mobs count")
	register("settlement", _cmd_settlement, "Settlement inspection.",                               "settlement resources | roos | stage | add <item> <amount>")
	register("world",      _cmd_world,      "World grid queries.",                                  "world cell <x> <y> | world pos <x> <y>")
	register("scene",      _cmd_scene,      "Scene control.",                                       "scene reload")
	register("debug",      _cmd_debug,      "Debug tools.",                                         "debug overlays on|off")

#endregion

#region Input Handling

func _toggle() -> void:
	if visible:
		hide()
	else:
		show()
		_input_field.grab_focus()


func _on_input_submitted(text: String) -> void:
	var trimmed := text.strip_edges()
	_input_field.clear()
	if trimmed.is_empty():
		return
	_history.append(trimmed)
	_history_cursor = -1
	print_line("> " + trimmed, "cyan")
	_parse_and_run(trimmed)


func _on_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_UP:
			_history_navigate(1)
		KEY_DOWN:
			_history_navigate(-1)
		KEY_TAB:
			_autocomplete()
			get_viewport().set_input_as_handled()
		KEY_QUOTELEFT:
			# Close the console from within the LineEdit so backtick isn't inserted as text
			_toggle()
			get_viewport().set_input_as_handled()


func _history_navigate(direction: int) -> void:
	if _history.is_empty():
		return
	_history_cursor = clamp(_history_cursor + direction, 0, _history.size() - 1)
	_input_field.text = _history[_history.size() - 1 - _history_cursor]
	_input_field.set_caret_column(_input_field.text.length())


func _autocomplete() -> void:
	var prefix := _input_field.text.strip_edges().to_lower()
	if prefix.is_empty():
		return
	var matches: PackedStringArray = []
	for cmd in _commands.keys():
		if (cmd as String).begins_with(prefix):
			matches.append(cmd)
	if matches.size() == 1:
		_input_field.text = matches[0] + " "
		_input_field.set_caret_column(_input_field.text.length())
	elif matches.size() > 1:
		_sys("  ".join(matches))

#endregion

#region Output Helpers

## Write a line of BBCode text to the output panel.
func print_line(text: String, color: String = "white") -> void:
	_output.append_text("[color=%s]%s[/color]\n" % [color, text])

func _ok(text: String)   -> void: print_line(text, "green")
func _info(text: String) -> void: _output.append_text(text + "\n")
func _warn(text: String) -> void: print_line("WARN  " + text, "yellow")
func _err(text: String)  -> void: print_line("ERR   " + text, "red")
func _sys(text: String)  -> void: print_line(text, "gray")
func _sep()              -> void: _sys("─────────────────────────────────")

#endregion

#region Command Parsing

func _parse_and_run(text: String) -> void:
	var parts := text.split(" ", false)
	if parts.is_empty():
		return
	var cmd_name := (parts[0] as String).to_lower()
	var args := parts.slice(1)
	if not _commands.has(cmd_name):
		_err("Unknown command '%s'. Type 'help' to list commands." % cmd_name)
		return
	_commands[cmd_name]["callable"].call(args)

#endregion

#region Commands — Meta

func _cmd_help(args: Array) -> void:
	if not args.is_empty():
		var name := (args[0] as String).to_lower()
		if _commands.has(name):
			var c: Dictionary = _commands[name]
			_ok(c["usage"])
			_sys("  " + c["description"])
		else:
			_err("No command '%s'" % name)
		return
	_sep()
	_ok("Dev Console")
	_sep()
	for name: String in _commands.keys():
		var c: Dictionary = _commands[name]
		_output.append_text("[color=cyan]%-12s[/color] [color=gray]%s[/color]\n" % [name, c["description"]])
	_sep()


func _cmd_clear(_args: Array) -> void:
	_output.clear()

#endregion

#region Commands — Player

func _cmd_player(args: Array) -> void:
	if args.is_empty():
		_err("Usage: " + _commands["player"]["usage"])
		return
	match (args[0] as String).to_lower():
		"pos":
			_player_pos()
		"tp":
			if args.size() < 3:
				_err("Usage: player tp <x> <y>")
				return
			_player_tp(Vector2((args[1] as String).to_float(), (args[2] as String).to_float()))
		_:
			_err("Unknown player subcommand '%s'" % args[0])


func _player_pos() -> void:
	var ms := GameManager.MobService
	if not ms or not ms.is_player_alive():
		_warn("No player in scene.")
		return
	var pos := ms.get_player_position()
	var wg := GameManager.WorldGridService
	var cell := wg.world_to_cell(pos) if wg else Vector2i.ZERO
	_ok("pos (%.1f, %.1f)  cell (%d, %d)" % [pos.x, pos.y, cell.x, cell.y])


func _player_tp(target: Vector2) -> void:
	var ms := GameManager.MobService
	if not ms or not ms.is_player_alive():
		_warn("No player in scene.")
		return
	ms.player.global_position = target
	_ok("Teleported player to (%.1f, %.1f)" % [target.x, target.y])

#endregion

#region Commands — Mobs

func _cmd_mobs(args: Array) -> void:
	var ms := GameManager.MobService
	if not ms:
		_warn("MobService unavailable.")
		return
	var sub := (args[0] as String).to_lower() if not args.is_empty() else "list"
	match sub:
		"list":
			_mobs_list(ms)
		"count":
			_ok("Total active mobs: %d" % ms.get_total_mob_count())
		_:
			_err("Unknown mobs subcommand '%s'" % sub)


func _mobs_list(ms: Node) -> void:
	_sep()
	_ok("Active Mobs (%d)" % ms.get_total_mob_count())
	_sep()
	for mob_id: String in ms._active_mobs.keys():
		var mob: Node = ms._active_mobs[mob_id]
		if not is_instance_valid(mob):
			continue
		var team: int = ms._mob_teams.get(mob_id, 0)
		var pos := (mob as Node2D).global_position if mob is Node2D else Vector2.ZERO
		_info("[color=cyan][%s][/color]  team=%d  pos=(%.0f, %.0f)" % [mob_id, team, pos.x, pos.y])
	_sep()

#endregion

#region Commands — Settlement

func _cmd_settlement(args: Array) -> void:
	if args.is_empty():
		_err("Usage: " + _commands["settlement"]["usage"])
		return
	var settlement := _get_settlement()
	if not settlement:
		_warn("No settlement in scene.")
		return
	match (args[0] as String).to_lower():
		"resources":
			_settlement_resources(settlement)
		"roos":
			_settlement_roos(settlement)
		"stage":
			var stage_name: String = Enums.ProgressionStage.keys()[settlement.progression_stage]
			_ok("Progression stage: %s" % stage_name)
		"add":
			if args.size() < 3:
				_err("Usage: settlement add <wood|stone|jade> <amount>")
				return
			_settlement_add(settlement, (args[1] as String).to_lower(), (args[2] as String).to_int())
		_:
			_err("Unknown settlement subcommand '%s'" % args[0])


func _settlement_resources(settlement: Node) -> void:
	var resources: Dictionary = settlement.get_all_resources()
	var item_keys := ItemsLibrary.Items.keys()
	_sep()
	_ok("Settlement Resources")
	_sep()
	if resources.is_empty():
		_sys("  (empty)")
	else:
		for item_id: int in resources.keys():
			var label: String = item_keys[item_id].capitalize() if item_id < item_keys.size() else str(item_id)
			_info("  [color=white]%-8s[/color] [color=green]%d[/color]" % [label, resources[item_id]])
	_sep()


func _settlement_roos(settlement: Node) -> void:
	_sep()
	_ok("Population: %d" % settlement.get_population())
	_sep()
	for prof: int in Enums.Professions.values():
		var roos: Array = settlement.get_roos_by_profession(prof)
		if not roos.is_empty():
			_info("  [color=cyan]%-14s[/color] %d" % [Enums.Professions.keys()[prof].capitalize(), roos.size()])
	_sep()


func _settlement_add(settlement: Node, resource_name: String, amount: int) -> void:
	if not _RESOURCE_NAMES.has(resource_name):
		_err("Unknown resource '%s'. Valid: wood, stone, jade" % resource_name)
		return
	if amount <= 0:
		_err("Amount must be positive.")
		return
	settlement.deposit_resource(_RESOURCE_NAMES[resource_name], amount)
	_ok("Added %d %s to settlement." % [amount, resource_name])


func _get_settlement() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("settlement")

#endregion

#region Commands — World

func _cmd_world(args: Array) -> void:
	if args.size() < 3:
		_err("Usage: " + _commands["world"]["usage"])
		return
	var sub := (args[0] as String).to_lower()
	var wg := GameManager.WorldGridService
	if not wg:
		_warn("WorldGridService unavailable.")
		return
	match sub:
		"cell":
			_world_query(wg, Vector2i((args[1] as String).to_int(), (args[2] as String).to_int()))
		"pos":
			var world_pos := Vector2((args[1] as String).to_float(), (args[2] as String).to_float())
			_world_query(wg, wg.world_to_cell(world_pos))
		_:
			_err("Unknown world subcommand '%s'. Use: cell | pos" % sub)


func _world_query(wg: Node, cell: Vector2i) -> void:
	if not wg.has_cell(cell):
		_warn("Cell (%d, %d) is not in the grid." % [cell.x, cell.y])
		return
	var terrain: int  = wg.get_terrain(cell)
	var passable: bool = wg.is_passable(cell)
	var state: int    = wg.get_territory_state(cell)
	_sep()
	_ok("Cell (%d, %d)" % [cell.x, cell.y])
	_info("  terrain   [color=cyan]%s[/color]" % Enums.TerrainType.keys()[terrain])
	_info("  passable  [color=cyan]%s[/color]" % str(passable))
	_info("  state     [color=cyan]%s[/color]" % Enums.TileState.keys()[state])
	_sep()

#endregion

#region Commands — Scene

func _cmd_scene(args: Array) -> void:
	if args.is_empty():
		_err("Usage: " + _commands["scene"]["usage"])
		return
	match (args[0] as String).to_lower():
		"reload":
			_info("Reloading scene...")
			get_tree().reload_current_scene()
		_:
			_err("Unknown scene subcommand '%s'" % args[0])

#endregion

#region Commands — Debug Tools

func _cmd_debug(args: Array) -> void:
	if args.size() < 2 or (args[0] as String).to_lower() != "overlays":
		_err("Usage: " + _commands["debug"]["usage"])
		return
	var enabled := (args[1] as String).to_lower() == "on"
	_toggle_overlays(enabled)


func _toggle_overlays(enabled: bool) -> void:
	var overlays := get_tree().get_nodes_in_group("debug_overlay")
	var count := 0
	for overlay: Node in overlays:
		if overlay.has_method("set_labels_visible"):
			overlay.set_labels_visible(enabled)
			count += 1
	_ok("Set %d debug overlays %s." % [count, "on" if enabled else "off"])

#endregion
