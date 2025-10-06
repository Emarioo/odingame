package assimp

ASSIMP_SHARED :: #config(ASSIMP_SHARED, false)

when ODIN_OS == .Windows {
	// No windows stuff yet
	// @(extra_linker_flags="/NODEFAULTLIB:" + ("msvcrt" when ASSIMP_SHARED else "libcmt"))
	// foreign import lib {
	// 	"windows/raylibdll.lib" when ASSIMP_SHARED else "windows/raylib.lib" ,
	// 	"system:Winmm.lib",
	// 	"system:Gdi32.lib",
	// 	"system:User32.lib",
	// 	"system:Shell32.lib",
	// }
} else when ODIN_OS == .Linux  {
	foreign import lib {
		"linux/libassimp.so" when ASSIMP_SHARED else "linux/libassimp.a",
	}
} else {
	foreign import lib "system:raylib"
}