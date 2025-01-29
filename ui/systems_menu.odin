package ui

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

import ast "../astrolib"


sys_menu_state :: enum {
	disp_sys,
	add_sys,
	edit_sys,
	disp_sat,
	add_sat,
	edit_sat,
	disp_body,
	add_body,
	edit_body,
}

info_menu_state :: enum {
	system,
	satellite,
	body,
	station,
	camera,
}


sys_state: sys_menu_state = .disp_sys

ui_spacer :: proc() {if clay.UI(
		clay.Layout(
			{sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})}},
		),
	) {}
}

sys_menu :: proc(
	ctx: ^Context,
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
	systems_reset: ^ast.Systems,
) {
	handle_sys_input()
	if show_sys {
		#partial switch sys_state {
		case .disp_sys:
			// system drop down -> swap system
			sys_button("create_sys", "Create System")
			horizontal_bar(DARK_GRAY)
			display_systems(system, systems)
			ui_spacer()
		// reset system button
		// apply button | back button
		case .add_sys:
			add_sys_menu(system, systems, systems_reset)

		case .edit_sys:
			edit_sys_menu(system)
		// edit system
		// substeps +/-
		// time scale +/-
		// camera sub-menu
		// add sat button
		// add body button
		// add station button
		// back button

		}
	}
}

side_by_side_buttons :: proc(
	block_name, id1, display1, id2, display2: string,
) {
	if clay.UI(
		clay.ID(block_name),
		clay.Layout(
			{
				childGap = gaps,
				layoutDirection = clay.LayoutDirection.LEFT_TO_RIGHT,
				sizing = {width = clay.SizingGrow({})},
			},
		),
	) {
		sys_button(id1, display1)
		sys_button(id2, display2)
	}
}

display_systems :: proc(system: ^ast.AstroSystem, systems: ^ast.Systems) {
	for i := 0; i < systems.num_systems; i += 1 {
		str_b := strings.builder_make()
		strings.write_int(&str_b, i)
		strings.write_string(&str_b, ": ")
		strings.write_string(&str_b, systems.systems[i].name)
		if i == system.id {
			strings.write_string(&str_b, " <")
		}
		name := strings.to_string(str_b)
		sys_button(name, name)

		if clay.PointerOver(clay.GetElementId(clay.MakeString(name))) &&
		   rl.IsMouseButtonPressed(.LEFT) &&
		   i != system.id {
			swap_systems(&systems.systems[i], system, systems)
		} else if clay.PointerOver(clay.GetElementId(clay.MakeString(name))) &&
		   rl.IsMouseButtonPressed(.LEFT) &&
		   i == system.id {
			sys_state = .edit_sys
		}

	}
}

swap_systems :: proc(
	system_new, system_current: ^ast.AstroSystem,
	systems: ^ast.Systems,
) {
	ast.copy_system(&systems.systems[system_current.id], system_current)
	ast.copy_system(system_current, system_new)
}

edit_sys_menu :: proc(system: ^ast.AstroSystem) {
	if clay.UI(
		clay.Layout(
			{
				sizing = {width = clay.SizingGrow({})},
				padding = clay.Padding {
					top = gaps / 2,
					bottom = gaps / 2,
					right = gaps,
					left = gaps,
				},
			},
		),
	) {
		clay.Text(system.name, &button_text_config)
	}
	horizontal_bar(DARK_GRAY)
	// show system menus
	ui_spacer()
	side_by_side_buttons(
		"apply_back_edit_sys",
		"apply_edit_sys",
		"Apply",
		"back_edit_sys",
		"Back",
	)

	// apply button pressed
	if clay.PointerOver(clay.GetElementId(clay.MakeString("apply_edit_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		sys_state = .disp_sys
	}

	// back button pressed
	if clay.PointerOver(clay.GetElementId(clay.MakeString("back_edit_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		sys_state = .disp_sys
	}
}

add_sys_menu :: proc(
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
	systems_reset: ^ast.Systems,
) {

	ui_spacer()
	side_by_side_buttons(
		"apply_back_add_sys",
		"apply_add_sys",
		"Apply",
		"back_add_sys",
		"Back",
	)
	// append(systems, system_temp)


	// apply button pressed
	if clay.PointerOver(clay.GetElementId(clay.MakeString("apply_add_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		system_temp := ast.create_system()
		ast.add_system(systems, systems_reset, system_temp)
		sys_state = .disp_sys
	}

	// back button pressed
	if clay.PointerOver(clay.GetElementId(clay.MakeString("back_add_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		sys_state = .disp_sys
	}
}

handle_sys_input :: proc() {
	if clay.PointerOver(clay.GetElementId(clay.MakeString("create_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		sys_state = .add_sys
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
