package ui

import "core:c"
import "core:fmt"
import "core:math"
import str "core:strings"
import rl "vendor:raylib"

import ast "../astrolib"
import clay "../external/clay-odin"

u_to_rl :: ast.u_to_rl


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
		fontId = fontId,
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
	if clay.UI().configure(
	{
		id = clay.ID(fieldname),
		layout = {
			padding = clay.Padding {
				left = gaps,
				right = gaps,
				top = gaps,
				bottom = gaps,
			},
			sizing = {width = clay.SizingGrow({})},
		},
		backgroundColor = MEDIUM_GRAY,
		cornerRadius = clay.CornerRadiusAll(4),
	},
	) {
		clay.Text("Enter value...", &text_config_16)
	}
	return val
}


back_button :: proc(name: string) {}


header_button :: proc(name, display_text: string) {
	if clay.UI().configure(
	{
		id = clay.ID(name),
		layout = {padding = {gaps, gaps, 2, 2}},
		backgroundColor = clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? LIGHT_GRAY : MEDIUM_GRAY2,
		cornerRadius = clay.CornerRadiusAll((4)),
	},
	) {
		clay.Text(
			display_text,
			clay.TextConfig(
				{fontId = FONT_ID_BODY_18, fontSize = 18, textColor = SOFT_WHITE},
			),
		)
	}
}

side_by_side_buttons :: proc(
	block_name, id1, display1, id2, display2: string,
) {
	if clay.UI().configure(
	{
		id = clay.ID(block_name),
		layout = {
			childGap = gaps,
			layoutDirection = clay.LayoutDirection.LeftToRight,
			sizing = {width = clay.SizingGrow({})},
		},
	},
	) {
		sys_button_medium(id1, display1)
		sys_button_medium(id2, display2)
	}
}

button_clicked :: proc(id: string) -> bool {
	return(
		clay.PointerOver(clay.GetElementId(clay.MakeString(id))) &&
		rl.IsMouseButtonPressed(.LEFT) \
	)
}

pointer_in :: proc(id: string) -> bool {
	return clay.PointerOver(clay.GetElementId(clay.MakeString(id)))
}

vertical_bar :: proc(color: clay.Color, thickness: f32 = 1) {
	if clay.UI().configure(
	{
		layout = {
			sizing = {
				width = clay.SizingFixed(thickness),
				height = clay.SizingGrow({}),
			},
		},
		backgroundColor = color,
	},
	) {}
}

horizontal_bar :: proc(color: clay.Color, thickness: f32 = 1) {
	if clay.UI().configure(
	{
		layout = {
			sizing = {
				height = clay.SizingFixed(thickness),
				width = clay.SizingGrow({}),
			},
		},
		backgroundColor = color,
	},
	) {

	}
}
