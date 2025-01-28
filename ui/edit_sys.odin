package ui

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import rl "vendor:raylib"

import ast "../astrolib"

// show_edit_sys := false
// show_sys
// show_add_sat_opts := false

info_sys_state :: enum {
	add_sys,
	edit_sys,
}

sys_state: info_sys_state = .add_sys

sys_menu :: proc(
	ctx: ^Context,
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^[dynamic]ast.AstroSystem,
) {
	handle_sys_input()
	if show_sys {
		switch sys_state {
		case .add_sys:
			// system drop down -> swap system
			sys_button("swap_sys", "Swap System")
			sys_button("create_sys", "Create System")
			sys_button("reset_sys", "Reset System")
			sys_button("edit_sys", "Edit Current System")
			if clay.UI(clay.Layout({sizing = {height = clay.SizingGrow({})}})) {}
			sys_button("back_sys", "Back")
		// reset system button
		// apply button | back button

		case .edit_sys:

		// edit system
		// substeps, time scale, camera sub-menu
		// add sat button
		// add body button
		// add station button
		// back button

		}


	}


}

handle_sys_input :: proc() {
	if clay.PointerOver(clay.GetElementId(clay.MakeString(""))) {

	}
}

sys_button_layout := clay.LayoutConfig {
	sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(48)},
	padding = clay.PaddingAll(gaps),
	childAlignment = clay.ChildAlignment{y = .CENTER},
	childGap = gaps,
}

sys_button_rect :: proc(
	color: clay.Color,
) -> (
	rect_config: clay.RectangleElementConfig,
) {
	rect_config.color = color
	rect_config.cornerRadius = clay.CornerRadiusAll(4)

	return rect_config
}

sys_dropdown :: proc(name: string, display_text: string) {

}


sys_button :: proc(name: string, display_text: string) {
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY


	sys_button_rectangle := sys_button_rect(color)
	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout),
		clay.Rectangle(sys_button_rectangle),
	) {
		clay.Text(display_text, &button_text_config)
	}
}

add_sat_button :: proc() -> (sat: ast.Satellite) {
	name := "add_sat"
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY

	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout),
		clay.Rectangle(sys_button_rect(color)),
	) {

	}

	return sat
}


add_body_button :: proc() -> (body: ast.CelestialBody) {

	return body
}


input_posvel :: proc(ctx: ^Context) {
	fieldname: string

	layout := clay.LayoutConfig {
		sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(48)},
		padding = clay.PaddingAll(gaps),
		childAlignment = clay.ChildAlignment{y = .CENTER},
		childGap = gaps,
	}
	rectangle := clay.RectangleElementConfig {
		color        = LIGHT_GRAY,
		cornerRadius = clay.CornerRadiusAll(4),
	}

	if clay.UI(clay.ID("x_box"), clay.Layout(layout), clay.Rectangle(rectangle)) {
		if clay.UI(clay.ID("x_title")) {
			clay.Text("X position:", &button_text_config)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "x_box_text", f64)
	}
	if clay.UI(clay.ID("y_box"), clay.Layout(layout), clay.Rectangle(rectangle)) {
		if clay.UI(clay.ID("y_title")) {
			clay.Text("Y position:", &button_text_config)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "y_box_text", f64)
	}
	if clay.UI(clay.ID("z_box"), clay.Layout(layout), clay.Rectangle(rectangle)) {
		if clay.UI(clay.ID("z_title")) {
			clay.Text("Z position:", &button_text_config)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "z_box_text", f64)
	}
}
