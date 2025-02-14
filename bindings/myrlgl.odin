package rlgl

import "core:c"
import rl "../."


when ODIN_OS == .Windows {
    @(extra_linker_flags="/NODEFAULTLIB:" + ("msvcrt" when RAYLIB_SHARED else "libcmt"))
    foreign import lib {
        "../windows/raylibdll.lib" when RAYLIB_SHARED else "../windows/raylib.lib" ,
        "system:Winmm.lib",
        "system:Gdi32.lib",
        "system:User32.lib",
        "system:Shell32.lib",
    }
} else when ODIN_OS == .Linux  {
    foreign import lib {
        // Note(bumbread): I'm not sure why in `linux/` folder there are
        // multiple copies of raylib.so, but since these bindings are for
        // particular version of the library, I better specify it. Ideally,
        // though, it's best specified in terms of major (.so.4)
        "../linux/libraylib.so.550" when RAYLIB_SHARED else "../linux/libraylib.a",
        "system:dl",
        "system:pthread",
    }
} else when ODIN_OS == .Darwin {
    foreign import lib {
        "../macos/libraylib.550.dylib" when RAYLIB_SHARED else "../macos/libraylib.a",
        "system:Cocoa.framework",
        "system:OpenGL.framework",
        "system:IOKit.framework",
    } 
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import lib {
        RAYLIB_WASM_LIB,
    }
} else {
    foreign import lib "system:raylib"
}

@(default_calling_convention="c", link_prefix="rl")
foreign lib {

    //------------------------------------------------------------------------------------
    // Functions Declaration - Personal
    //------------------------------------------------------------------------------------
    SetClipPlanes :: proc( nearPlane, farPlane:c.double) ---
    GetCullDistanceNear :: proc() -> c.double ---
    GetCullDistanceFar :: proc() -> c.double ---

}