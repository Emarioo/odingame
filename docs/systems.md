
Game architecture tries to be modular. Swap out systems, easier to optimize, reuse systems in other projects.

In a game there are core systems we need.
- Resource System (textures, models, sound, terrain)
- Game Main Driver (dll hotreload)
- 

# Resource System
Static assets. We load them from disc, do some processing into 


# Game Main Driver
Hot reload dynmamic libraries.
When reloading game dll we need to preserve global data from game itself but also libraries like glfw, glad, cgltf we need to preserve global data.

# Game State System

Save the state of the game. Close the game. And load it at that exact frame. All entities, terrain, chests, momentum, input is restored.

Rewing the state of the game. Jump of a rock, you fall through the ground. Go back a couple of frames, step forward to the moment it happens and investigate the entities position, velocity, collision data
to figure out the problem.




# Asset system

Reload on change