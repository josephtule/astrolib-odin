package ui

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

import ast "../astrolib"

sat_index: int = 0
body_index: int = 0
stat_index: int = 0

editing_text := false

sys_menu_state :: enum {
	disp_sys,
	add_sys,
	edit_sys,
	// disp_ shows entities in current system
	// edit_ edits currently selected entity
	disp_sats,
	add_sat,
	edit_sat,
	disp_bodies,
	add_body,
	edit_body,
	disp_stats,
	add_stat,
	edit_stat,
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

disp_sys_menu :: proc(
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
			sys_button_medium("create_sys", "Create System")
			horizontal_bar(DARK_GRAY)
			display_systems(system, systems)
			ui_spacer()
		// reset system button
		// apply button | back button
		case .add_sys:
			add_sys_menu(system, systems, systems_reset)
		case .edit_sys:
			edit_sys_menu(system, systems_reset)
		case .disp_sats:
			disp_sats_menu(system)
		case .add_sat:
			add_sat_menu(system, systems_reset)
		case .edit_sat:
			if system.num_satellites > 0 {
				edit_sat_menu(system)
			}
		case .disp_bodies:
		case .add_body:
		case .edit_body:
			if system.num_bodies > 0 {
				// edit_body_menu(system)
			}
		case .disp_stats:
		case .add_stat:
		case .edit_stat:
			if system.num_stations > 0 {
				// edit_stat_menu(system)
			}
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


add_sat_menu :: proc(system: ^ast.AstroSystem, systems_reset: ^ast.Systems) {
	ui_spacer()
	side_by_side_buttons(
		"apply_back_add_sat",
		"apply_add_sat",
		"Apply",
		"back_add_sat",
		"Back",
	)

	// apply button pressed
	if button_clicked("apply_add_sat") {
		// TODO: remove this later
		// TODO: also when doing coe stuff and selecting bodies, camera should switch to said body
		#unroll for i in 0 ..< 100 {
			// orbittype := rand.choice_enum(ast.EarthOrbitType)
			orbittype := rand.choice(
				[]ast.EarthOrbitType{.LEO, .LEO, .LEO, .LEO, .MEO, .GEO, .GSO},
			)
			pos, vel := ast.gen_rand_coe_earth(system.bodies[0], orbittype)
			ep: [4]f64 = {0, 0, 0, 1}
			omega: [3]f64 = {0, 0, 0}
			cube_size: f32 = 50 / 1000. * u_to_rl
			model_size := [3]f32{cube_size, cube_size * 2, cube_size * 3}
			sat, sat_model := ast.gen_sat_and_model(pos, vel, ep, omega, model_size)
			ast.add_to_system(system, sat)
			ast.add_to_system(system, sat_model)
		}
		sys_state = .edit_sys
	}

	// back button pressed
	if button_clicked("back_add_sat") {
		sys_state = .edit_sys
	}

}

edit_sat_menu :: proc(system: ^ast.AstroSystem) {
	str_b := strings.builder_make()
	strings.write_string(&str_b, system.name)
	strings.write_string(&str_b, " > ")
	strings.write_string(&str_b, system.satellites[sat_index].info.name)
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
		clay.Text(strings.to_string(str_b), &text_config_16)
	}
	horizontal_bar(DARK_GRAY)
	ui_spacer()
	side_by_side_buttons(
		"apply_back_edit_sat",
		"apply_edit_sat",
		"Apply",
		"back_edit_sat",
		"Back",
	)

	// apply button pressed
	if button_clicked("apply_edit_sat") {
		// only apply changes
		// sys_state = .disp_sats
	}

	// back button pressed
	if button_clicked("back_edit_sat") {
		sys_state = .disp_sats
	}
}

disp_sats_menu :: proc(system: ^ast.AstroSystem) {
	num_pages: int =
		(system.num_satellites + max_entities_per_page - 1) / max_entities_per_page
	if clay.UI(
		clay.Layout(
			{
				childAlignment = {y = .CENTER},
				childGap = gaps / 2,
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
		// TODO: update less often, create update system text function or something
		num_buf: [8]byte
		num_sats_str := strconv.itoa(num_buf[:], system.num_satellites)
		sys_title, _ := strings.join(
			[]string{system.name, " [", num_sats_str, "]"},
			"",
		)
		clay.Text(sys_title, &text_config_16)
		vertical_bar(DARK_GRAY)

		// ui_spacer()

		if num_pages > 1 {
			if clay.UI(
				clay.Layout(
					{sizing = grow, childGap = gaps / 2, layoutDirection = .TOP_TO_BOTTOM},
				),
			) {
				// vertical_bar(DARK_GRAY)
				num_buf = [8]byte{}
				page_str := strings.clone(strconv.itoa(num_buf[:], sat_page + 1))
				num_buf = [8]byte{}
				num_pages_str := strings.clone(strconv.itoa(num_buf[:], num_pages))
				// fmt.println(num_pages_str, page_str)
				page, _ := strings.join(
					[]string{"Page: ", page_str, "/", num_pages_str},
					"",
				)


				clay.Text(page, &text_config_14)
				vertical_bar(DARK_GRAY)
				inc_button_size: f32 = 16
				if clay.UI(
					clay.Layout(
						{sizing = grow, childGap = gaps / 2, layoutDirection = .LEFT_TO_RIGHT},
					),
				) {
					sys_button_custom("prev_sat_page", "-", inc_button_size)
					sys_button_custom("next_sat_page", "+", inc_button_size)
					if button_clicked("prev_sat_page") {
						sat_page -= 1
					}
					if button_clicked("next_sat_page") {
						sat_page += 1
					}
				}
				if num_pages >= 10 {
					if clay.UI(
						clay.Layout(
							{sizing = grow, childGap = gaps / 2, layoutDirection = .LEFT_TO_RIGHT},
						),
					) {
						sys_button_custom("prev_sat_page10", "-10", inc_button_size)
						sys_button_custom("next_sat_page10", "+10", inc_button_size)
						if button_clicked("prev_sat_page10") {
							sat_page -= 10
						}
						if button_clicked("next_sat_page10") {
							sat_page += 10
						}
					}
				}
				if num_pages >= 25 {
					if clay.UI(
						clay.Layout(
							{sizing = grow, childGap = gaps / 2, layoutDirection = .LEFT_TO_RIGHT},
						),
					) {
						sys_button_custom("prev_sat_page25", "-25", inc_button_size)
						sys_button_custom("next_sat_page25", "+25", inc_button_size)
						if button_clicked("prev_sat_page25") {
							sat_page -= 25
						}
						if button_clicked("next_sat_page25") {
							sat_page += 10
						}
					}
				}

			}
		}
		vertical_bar(DARK_GRAY)
		sys_button_custom("back_disp_sats", "Back", 24)

		// back button pressed
		if button_clicked("back_disp_sats") {
			sys_state = .edit_sys
		}
	}
	horizontal_bar(DARK_GRAY)

	if system.num_satellites == 0 {
		clay.Text("There are no satellites", &text_config_16)
	} else {
		display_satellites(system, num_pages)
	}
}

sat_page: int = 0
max_entities_per_page := 50
display_satellites :: proc(system: ^ast.AstroSystem, num_pages: int) {
	sat_page = (sat_page + num_pages) % num_pages

	start_index := sat_page * max_entities_per_page
	end_index := start_index + max_entities_per_page
	if end_index > system.num_satellites {
		end_index = system.num_satellites
	}

	for i := start_index; i < end_index; i += 1 {
		str_b := strings.builder_make()
		strings.write_int(&str_b, i)
		strings.write_string(&str_b, ": ")
		strings.write_string(&str_b, system.satellites[i].info.name)
		id := strings.to_string(str_b)
		sys_button_small(id, id)

		if button_clicked(id) {
			sys_state = .edit_sat
			sat_index = i
		}
	}
}

edit_sys_menu :: proc(system: ^ast.AstroSystem, systems_reset: ^ast.Systems) {
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
		// TODO: reduce number of times this is called, update only when pages are switched
		num_buf: [8]byte
		num_sats_str := strconv.itoa(num_buf[:], system.num_satellites)
		sys_title, _ := strings.join(
			[]string{system.name, " [", num_sats_str, "]"},
			"",
		)
		clay.Text(sys_title, &text_config_16)
	}
	horizontal_bar(DARK_GRAY)

	// show system info
	// show time, jd
	// show number of satellites, bodies, stations

	horizontal_bar(DARK_GRAY)
	sys_button_medium("add_sat", "Add Satellite")
	sys_button_medium("add_body", "Add Celestial Body")
	sys_button_medium("add_stat", "Add Observation Station")

	horizontal_bar(DARK_GRAY)
	// TODO: implement entity search via id or name
	sys_button_medium("view_sats", "View Satellites")
	sys_button_medium("view_bodies", "View Celestial Bodies")
	sys_button_medium("view_stats", "View Observation Station")

	horizontal_bar(DARK_GRAY)
	sys_button_medium("toggle_sat_posvel", "Toggle Satellite Vectors")
	sys_button_medium("toggle_sat_trails", "Toggle Satellite Trails")
	sys_button_medium("toggle_sat_attitude", "Toggle Satellite Attitude")
	sys_button_medium("toggle_sat_axes", "Toggle Satellite Axes")

	horizontal_bar(DARK_GRAY)
	sys_button_medium("toggle_body_posvel", "Toggle Body Vectors")
	sys_button_medium("toggle_body_trails", "Toggle Body Trails")
	sys_button_medium("toggle_body_attitude", "Toggle Body Attitude")
	sys_button_medium("toggle_body_axes", "Toggle Body Axes")

	horizontal_bar(DARK_GRAY)
	sys_button_medium("reset_sys_state", "Reset System to save state")
	sys_button_medium("set_sys_state_save", "Set System save state")

	ui_spacer()
	side_by_side_buttons(
		"apply_back_edit_sys",
		"apply_edit_sys",
		"Apply",
		"back_edit_sys",
		"Back",
	)

	// handle input ------------------------------------------------------------
	// add satellite button pressed
	if button_clicked("add_sat") {
		sys_state = .add_sat
	}
	// view satellites button pressed
	if button_clicked("view_sats") {
		sys_state = .disp_sats
	}

	// satellite toggles
	if button_clicked("toggle_sat_posvel") {
		for &sat in system.satellite_models {
			sat.posvel.draw_pos = !sat.posvel.draw_pos
			sat.posvel.draw_vel = !sat.posvel.draw_vel
		}
	}
	if button_clicked("toggle_sat_trails") {
		for &sat in system.satellite_models {
			sat.trail.draw = !sat.trail.draw
		}
	}
	if button_clicked("toggle_sat_attitude") {
		for &sat in system.satellites {
			sat.update_attitude = !sat.update_attitude
		}
	}
	if button_clicked("toggle_sat_axes") {
		for &sat in system.satellite_models {
			sat.axes.draw = !sat.axes.draw
		}
	}
	// body toggles


	// save/states
	if button_clicked("reset_sys_state") {
		ast.copy_system(system, &systems_reset.systems[0])
	}
	if button_clicked("set_sys_state_save") {
		// FIXME: right now resetting does not reset the trails completely
		ast.copy_system(&systems_reset.systems[system.id], system)
	}


	// apply button pressed
	if button_clicked("apply_edit_sys") {
		// only apply changes
		// sys_state = .disp_sys
	}

	// back button pressed
	if button_clicked("back_edit_sys") {
		sys_state = .disp_sys
	}
}

display_systems :: proc(system: ^ast.AstroSystem, systems: ^ast.Systems) {

	// TODO: add pagination 
	for i := 0; i < systems.num_systems; i += 1 {
		str_b := strings.builder_make()
		strings.write_int(&str_b, i)
		strings.write_string(&str_b, ": ")
		strings.write_string(&str_b, systems.systems[i].name)
		if i == system.id {
			strings.write_string(&str_b, " <")
		}
		id := strings.to_string(str_b)
		sys_button_medium(id, id)

		if button_clicked(id) && i != system.id {
			swap_systems(&systems.systems[i], system, systems)
		} else if button_clicked(id) && i == system.id {
			sys_state = .edit_sys
		}
	}
}


swap_systems :: proc(
	system_new, system_current: ^ast.AstroSystem,
	systems: ^ast.Systems,
) {
	system_new.simulate = false
	system_current.simulate = false
	ast.copy_system(&systems.systems[system_current.id], system_current)
	ast.copy_system(system_current, system_new)
}

add_sys_menu :: proc(
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
	systems_reset: ^ast.Systems,
) {
	// TODO: fill this out
	// sys_button_medium("add_sat", "Add Satellite")
	// sys_button_medium("add_body", "Add Celestial Body")
	// sys_button_medium("add_station", "Add Observation Station")
	// name
	// substeps
	// time scale
	// pre-defined systems -> input time for certain systems
	//     solar system
	//     earth-moon system
	//     cr3bp?
	sys_button_medium("add_earth_moon", "Create Earth-Moon System")
	if button_clicked("add_earth_moon") {
		temp_sys := ast.earth_moon_system()
		ast.add_system(systems, systems_reset, &temp_sys)
		sys_state = .disp_sys
	}


	horizontal_bar(DARK_GRAY)

	ui_spacer()
	side_by_side_buttons(
		"apply_back_add_sys",
		"apply_add_sys",
		"Apply",
		"back_add_sys",
		"Back",
	)

	// apply button pressed
	if button_clicked("apply_add_sys") {
		system_temp := ast.create_system()
		ast.add_system(systems, systems_reset, &system_temp)
		sys_state = .disp_sys
	}

	// back button pressed
	if button_clicked("back_add_sys") {
		sys_state = .disp_sys
	}
}

handle_sys_input :: proc() {
	if clay.PointerOver(clay.GetElementId(clay.MakeString("create_sys"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		sys_state = .add_sys
	}
}


sys_dropdown :: proc(name: string, display_text: string) {

}


sys_button_layout :: proc(size: f32) -> (layout_config: clay.LayoutConfig) {
	pad_side: u16 = gaps
	pad_top: u16 = gaps
	if size >= 18 && size <= 24 {
		pad_side = 4
		pad_top = 2
	} else if size >= 14 && size < 18 {
		pad_side = 2
		pad_top = 1
	}
	layout_config = clay.LayoutConfig {
		sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(size)},
		padding = {
			top = pad_top,
			bottom = pad_top,
			left = pad_side,
			right = pad_side,
		},
		childAlignment = clay.ChildAlignment{y = .CENTER},
	}
	return layout_config
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
sys_button_custom :: proc(name: string, display_text: string, size: f32) {
	text_config := &text_config_16
	if size >= 16 && size < 20 {
		text_config = &text_config_14
	} else if size >= 14 && size < 16 {
		text_config = &text_config_12
	}
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY
	sys_button_rectangle := sys_button_rect(color)
	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout(size)),
		clay.Rectangle(sys_button_rectangle),
	) {
		clay.Text(display_text, text_config)
	}
}
sys_button_small :: proc(name: string, display_text: string) {
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY
	sys_button_rectangle := sys_button_rect(color)
	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout(32)),
		clay.Rectangle(sys_button_rectangle),
	) {
		clay.Text(display_text, &text_config_16)
	}
}
sys_button_medium :: proc(name: string, display_text: string) {
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY
	sys_button_rectangle := sys_button_rect(color)
	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout(48)),
		clay.Rectangle(sys_button_rectangle),
	) {
		clay.Text(display_text, &text_config_16)
	}
}
sys_button_large :: proc(name: string, display_text: string) {
	color :=
		clay.PointerOver(clay.GetElementId(clay.MakeString(name))) ? MEDIUM_GRAY2 : LIGHT_GRAY
	sys_button_rectangle := sys_button_rect(color)
	if clay.UI(
		clay.ID(name),
		clay.Layout(sys_button_layout(64)),
		clay.Rectangle(sys_button_rectangle),
	) {
		clay.Text(display_text, &text_config_16)
	}
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
			clay.Text("X position:", &text_config_16)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "x_box_text", f64)
	}
	if clay.UI(clay.ID("y_box"), clay.Layout(layout), clay.Rectangle(rectangle)) {
		if clay.UI(clay.ID("y_title")) {
			clay.Text("Y position:", &text_config_16)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "y_box_text", f64)
	}
	if clay.UI(clay.ID("z_box"), clay.Layout(layout), clay.Rectangle(rectangle)) {
		if clay.UI(clay.ID("z_title")) {
			clay.Text("Z position:", &text_config_16)
		}
		// TODO: this is a placeholder for text input
		clay_textinput_box(ctx, "z_box_text", f64)
	}
}
