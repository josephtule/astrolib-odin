package sandbox

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import rl "vendor:raylib"


loadFont :: proc(fontId: u16, fontSize: u16, path: cstring) {
	raylibFonts[fontId] = RaylibFont {
		font   = rl.LoadFontEx(path, cast(i32)fontSize * 2, nil, 0),
		fontId = cast(u16)fontId,
	}
	rl.SetTextureFilter(
		raylibFonts[fontId].font.texture,
		rl.TextureFilter.TRILINEAR,
	)
}


// :VEIEWPORT
RaylibViewport :: proc () {}