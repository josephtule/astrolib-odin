package sandbox

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import rl "vendor:raylib"


headerTextConfig := clay.TextElementConfig {
	fontId    = FONT_ID_BODY_18,
	fontSize  = 18,
	textColor = SOFT_WHITE,
}
errorHandler :: proc "c" (errorData: clay.ErrorData) {
	if (errorData.errorType == clay.ErrorType.DUPLICATE_ID) {

	}
}



FONT_ID_BODY_12 :: 0
FONT_ID_BODY_14 :: 1
FONT_ID_BODY_16 :: 2
FONT_ID_BODY_18 :: 3
FONT_ID_BODY_20 :: 4
FONT_ID_BODY_24 :: 5
FONT_ID_BODY_28 :: 6
FONT_ID_BODY_30 :: 7
FONT_ID_BODY_32 :: 8
FONT_ID_BODY_36 :: 9
// FONT_ID_TITLE_56 :: 9
// FONT_ID_TITLE_52 :: 1
// FONT_ID_TITLE_48 :: 2
// FONT_ID_TITLE_36 :: 3
// FONT_ID_TITLE_32 :: 4

COLOR_LIGHT :: clay.Color{244, 235, 230, 255}
COLOR_LIGHT_HOVER :: clay.Color{224, 215, 210, 255}
COLOR_BUTTON_HOVER :: clay.Color{238, 227, 225, 255}
COLOR_BROWN :: clay.Color{61, 26, 5, 255}
//COLOR_RED :: clay.Color {252, 67, 27, 255}
COLOR_RED :: clay.Color{168, 66, 28, 255}
COLOR_RED_HOVER :: clay.Color{148, 46, 8, 255}
COLOR_ORANGE :: clay.Color{225, 138, 50, 255}
COLOR_BLUE :: clay.Color{111, 173, 162, 255}
COLOR_TEAL :: clay.Color{111, 173, 162, 255}
COLOR_BLUE_DARK :: clay.Color{2, 32, 82, 255}


SOFT_WHITE :: clay.Color({230, 230, 230, 255})
DARK_GRAY :: clay.Color({24, 24, 24, 255})
MEDIUM_GRAY :: clay.Color({45, 45, 45, 255})
LIGHT_GRAY :: clay.Color({60, 60, 60, 255})

// CONTAINER_BACKGROUND :: clay.Color{}

color_c_to_r :: proc(color: clay.Color) -> rl.Color {
	color_out: rl.Color
	color_out.r = u8(color.r)
	color_out.g = u8(color.g)
	color_out.b = u8(color.b)
	color_out.a = u8(color.a)
	return color_out
}
color_r_to_c :: proc(color: rl.Color) -> clay.Color {
	color_out: clay.Color
	color_out.r = f32(color.r)
	color_out.g = f32(color.g)
	color_out.b = f32(color.b)
	color_out.a = f32(color.a)
	return color_out
}
