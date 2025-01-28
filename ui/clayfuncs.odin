package ui

import "core:c"
import "core:fmt"
import "core:math"
import str "core:strings"
import rl "vendor:raylib"

import ast "../astrolib"
import clay "../external/clay-odin"

u_to_rl :: ast.u_to_rl

CameraType :: enum {
	origin = 0,
	satellite,
	body,
	locked,
}

CameraParams :: struct {
	azel:           [3]f64, // TODO: change to degrees
	target_sat:     ^ast.Satellite,
	target_sat_id:  int,
	target_body:    ^ast.CelestialBody,
	target_body_id: int,
	frame:          CameraType,
}

DisplayInfo :: enum {
	satellite,
	body,
	system,
	orbit_gen,
}

DisplayOrbitGen :: enum {
	posvel,
	coes,
}

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

clay_textinput_box :: proc(
	ctx: ^Context,
	fieldname: string,
	$T: typeid,
) -> (
	val: T,
) {
	if clay.UI(
		clay.ID(fieldname),
		clay.Rectangle(
			{color = MEDIUM_GRAY, cornerRadius = clay.CornerRadiusAll(4)},
		),
		clay.Layout(
			{
				padding = clay.Padding {
					left = gaps,
					right = gaps,
					top = gaps,
					bottom = gaps,
				},
				sizing = {width = clay.SizingGrow({})},
			},
		),
	) {
		clay.Text("Enter value...", &button_text_config)
	}
	return val
}


back_button :: proc(name: string) {}


header_button :: proc(text: string) {
	if clay.UI(
		clay.ID(text),
		clay.Layout({padding = {gaps, gaps, 2, 2}}),
		// clay.BorderOutsideRadius({2, COLOR_RED}, 10),
		clay.Rectangle(
			{
				color = clay.PointerOver(clay.GetElementId(clay.MakeString(text))) ? LIGHT_GRAY : MEDIUM_GRAY2,
				cornerRadius = clay.CornerRadiusAll(4),
			},
		),
	) {
		clay.Text(
			text,
			clay.TextConfig(
				{fontId = FONT_ID_BODY_18, fontSize = 18, textColor = SOFT_WHITE},
			),
		)
	}
}

header_vert_bar :: proc(color: clay.Color) {
	if clay.UI(
		clay.Layout(
			{sizing = {width = clay.SizingFixed(1), height = clay.SizingGrow({})}},
		),
		clay.Rectangle({color = color}),
	) {}
}


// :SYSTEM
system_new :: proc() -> (system: ast.AstroSystem) {
	system = ast.create_system_empty()
	return system
}
system_reset :: proc(dest, src: ^ast.AstroSystem) {ast.copy_system(dest, src)}
system_swap :: proc() {}
system_save :: proc() {}
