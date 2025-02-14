package ui

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import rl "vendor:raylib"

import ast "../astrolib"

Context_Status :: enum u8 {
	RULES,
	VOLUME,
	CONNECTED,
}
Context_Statuses :: bit_set[Context_Status]

Context :: struct {
	// ui_ctx:         UI_Context,
	// active buffer
	active_val_buf: [1024]u8,
	active_val_len: int,
	active_line:    int,
	volume:         f32,
	// rule creation
	val_buf:        [1024]u8,
	val_len:        int,
	// config state
	aux_rules:      [dynamic]string,
	config_file:    string,
	// inotify_fd:      linux.Fd,
	// inotify_wd:      linux.Wd,
	statuses:       Context_Statuses,
	// ipc
	// ipc:             IPC_Client_Context,
	// allocations
	arena:          virtual.Arena,
	allocator:      mem.Allocator,
}

show_info := false
show_sys := false

grow := clay.Sizing {
	width  = clay.SizingGrow({}),
	height = clay.SizingGrow({}),
}

rectangle_rounded :: proc(color: clay.Color) -> clay.RectangleElementConfig {
	rect := clay.RectangleElementConfig({color = color})
	return rect
}

gaps :: 8
header_size :: 32

createLayout :: proc(
	ctx: ^Context,
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
	systems_reset: ^ast.Systems,
) -> clay.ClayArray(clay.RenderCommand) {
	// ui_ctx: UI_Context
	mobileScreen := rl.GetScreenWidth() < 750
	handle_input_header(camera, camera_params, system, systems)
	clay.BeginLayout()

	// :outer container
	if clay.UI().configure(
	{
		id = clay.ID("outer_container"),
		layout = {
			layoutDirection = .TopToBottom,
			sizing = grow,
			padding = clay.PaddingAll(gaps),
			childGap = gaps,
		},
	},
	) {
		// :header
		if clay.UI().configure(
		{
			id = clay.ID("header"),
			// rectangle =
			// 	{color = MEDIUM_GRAY, cornerRadius = clay.CornerRadiusAll(8)},
			backgroundColor = MEDIUM_GRAY,
			layout = {
				sizing = {clay.SizingGrow({}), clay.SizingFixed(header_size)},
				padding = clay.Padding {
					left = gaps,
					right = gaps,
					top = gaps / 2,
					bottom = gaps / 2,
				},
				childGap = gaps,
				childAlignment = clay.ChildAlignment{y = .Center},
			},
		},
		) {
			clay.Text("AstroLib", &text_config_16)
			if clay.UI().configure(
			{layout = {sizing = {width = clay.SizingGrow({})}}},
			) {} 	// spacer
			if show_info {
				header_button("header_system", "System")
				// header_button("Satellites")
				// header_button("Bodies")
				// header_button("Station")
				// header_button("Camera")
			}
			vertical_bar(DARK_GRAY)
			header_button("header_info", "Info")
			header_button("header_simulate", "Simulate")
		}

		// :lower content
		lower_dir: clay.LayoutDirection
		info_menu_sizing: clay.Sizing
		if mobileScreen {
			// mobile width
			lower_dir = .TopToBottom
			info_menu_sizing = {
				width  = clay.SizingGrow({}),
				height = clay.SizingFixed(0.3333 * f32(rl.GetScreenHeight())),
			}
		} else {
			// desktop width
			height := f32(rl.GetScreenHeight() - gaps * 3) - header_size
			width: f32 = min(0.3333 * f32(rl.GetScreenWidth()), 450.)
			lower_dir = .LeftToRight
			info_menu_sizing = {
				width  = clay.SizingFixed(width),
				height = clay.SizingFixed(height),
			}
		}


		if clay.UI().configure(
		{
			id = clay.ID("lower_content"),
			layout = {sizing = grow, childGap = gaps, layoutDirection = lower_dir},
		},
		) {
			// :viewport on left/top (transparent to display raylib camera below)
			if clay.UI().configure(
			{
				id = clay.ID("viewport"),
				layout = {sizing = grow},
				// clay.Rectangle(rectangle_rounded(clay.COLOR)),
			},
			) {
				// empty here
			}
			// :info_menu on right/bottom TODO: draw only when button pressed
			if show_info {
				if clay.UI().configure(
				{
					id = clay.ID("info_menu"),
					scroll = {vertical = true},
					layout = {
						padding = clay.Padding {
							left = gaps,
							right = gaps,
							top = gaps,
							bottom = gaps,
						},
						sizing = info_menu_sizing,
						layoutDirection = .TopToBottom,
						childGap = gaps,
					},
					backgroundColor = MEDIUM_GRAY
					// clay.Rectangle(rectangle_rounded(MEDIUM_GRAY)),
				},
				) {
					// info container children
					if show_sys {
						// input_posvel(ctx)
						disp_sys_menu(ctx, camera, camera_params, system, systems, systems_reset)
					}

					// UI_textbox(ui_ctx)
				}
			}

		}
	}


	return clay.EndLayout()
}


handle_input_header :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
) {
	if clay.PointerOver(clay.GetElementId(clay.MakeString("header_info"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		show_info = !show_info
	}
	if clay.PointerOver(clay.GetElementId(clay.MakeString("header_system"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		show_sys = !show_sys
	}
	if button_clicked("header_simulate") ||
	   (rl.IsKeyPressed(.SPACE) && !editing_text) {
		system.simulate = !system.simulate
	}

}


handle_input_simulation :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^[dynamic]ast.AstroSystem,
) {

	if clay.PointerOver(clay.GetElementId(clay.MakeString(""))) {

	}

}


// edit_system_input :: proc() {}
// edit_satellite_input :: proc() {}
// edit_bodies_input :: proc() {}
// edit_camera_input :: proc() {}
