

# Unsorted

# Important
- [ ] Loading *Iuno* model stutters the game. It takes 50ms (including console prints). Solutions are: load a few meshes in each frame instead of all meshes. Use opengl pixel, storage buffer objects, give gpu memory mapped data. This would be asynchronous instead of serial glBufferData and glTexImage2D calls?
- [ ] Add tracy profiler

# Game world
- [ ] Decide on beginner experience, procedural terrain or a pre-made town?
- [ ] Protoype world in Krita. buildings, blocks, monsters areas. nothing detailed.
- [ ] Model the prototype in blender. we care about speed not quality.



# Engine stuff
- [ ] Entity movement from AI pathfinding and User input, how to connect them.
- [ ] Network architecture? server verifies. If a person is messing with the connection (hacking) we don't care how buggy their client gets.
- [ ] Modding support and architecture. Even if the game won't have mods it's good to modularize the game to keep things neat.

# Improve develop experience
- [ ] Game remembers window pos,size and monitor it's own. (i usally want it on second monitor but it always appears on my coding monitor, annoying)
- [ ] Process to auto export blender models. build.py exports through **Blender CLI** if blender files are new. For this we need to declare which blender files we have in the game, and where in assets they should go. Maybe just `art/models/X -> assets/models/X`. In art we may have sub folders for the models though. There is also how to deal with mods, can they auto export?.


# Done
- [x] Key in the game to hotreload code. (instead of typing build.py hot in a terminal)








# Real time editing in blender and export to game
https://lotusspring.substack.com/p/how-i-wrote-the-fastest-blender-exporter