# Enums Rework Design

Revise the logic of the project to have a single source of truth for free string definitions of objects in the game.

1. Create a new enums folder under resources.
2. Have a central enums.gd be autoloaded as a globally accessible singleton node in the project.
3. Create sub-sections that get imported by enums.gd if deemed necessary for compartmentalization.
4. Move all enums to the enums folder.

The structure of the code should look like this:

enums/
├── Professions 
├── Structures                  # Example scenes for GUIDE
├── Combat
│   ├── HealthState
│   ├── DamageType 
│   ├── Team 
...