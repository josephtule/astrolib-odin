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
	ui_ctx:         UI_Context,
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

layout_grow := clay.Sizing {
	width  = clay.SizingGrow({}),
	height = clay.SizingGrow({}),
}

rectangle_rounded :: proc(color: clay.Color) -> clay.RectangleElementConfig {
	rect := clay.RectangleElementConfig(
		{color = color, cornerRadius = clay.CornerRadiusAll(8)},
	)

	return rect
}

gaps :: 8


createLayout :: proc(
	ctx: ^Context,
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^ast.Systems,
	systems_reset: ^ast.Systems,
) -> clay.ClayArray(clay.RenderCommand) {
	ui_ctx: UI_Context
	mobileScreen := rl.GetScreenWidth() < 750
	handle_input_clay()
	clay.BeginLayout()

	// :outer container
	if clay.UI(
		clay.ID("outer_container"),
		clay.Layout(
			{
				layoutDirection = .TOP_TO_BOTTOM,
				sizing = layout_grow,
				padding = clay.PaddingAll(gaps),
				childGap = gaps,
			},
		),
	) {
		// :header
		if clay.UI(
			clay.ID("header"),
			clay.Rectangle(
				{color = MEDIUM_GRAY, cornerRadius = clay.CornerRadiusAll(8)},
			),
			clay.Layout(
				{
					sizing = {clay.SizingGrow({}), clay.SizingFixed(32)},
					padding = clay.Padding {
						left = gaps,
						right = gaps,
						top = gaps / 2,
						bottom = gaps / 2,
					},
					childGap = gaps,
					childAlignment = clay.ChildAlignment{y = .CENTER},
				},
			),
		) {
			clay.Text("AstroLib", &button_text_config)
			if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({})}})) {} 	// spacer
			if show_info {
				header_button("System")
				// header_button("Satellites")
				// header_button("Bodies")
				// header_button("Station")
				// header_button("Camera")
			}
			vertical_bar(DARK_GRAY)
			header_button("Info")
			header_button("Simulate")
		}

		// :lower content
		lower_dir: clay.LayoutDirection
		info_container_sizing: clay.Sizing
		if mobileScreen {
			lower_dir = .TOP_TO_BOTTOM
			info_container_sizing = {
				width  = clay.SizingGrow({}),
				height = clay.SizingFixed(0.25 * f32(rl.GetScreenHeight())),
			}
		} else {
			lower_dir = .LEFT_TO_RIGHT
			info_container_sizing = {
				width  = clay.SizingFixed(0.33 * f32(rl.GetScreenWidth())),
				height = clay.SizingGrow({}),
			}
		}
		if clay.UI(
			clay.ID("lower_content"),
			clay.Layout(
				{sizing = layout_grow, childGap = gaps, layoutDirection = lower_dir},
			),
		) {
			// :viewport on left/top (transparent to display raylib camera below)
			if clay.UI(
				clay.ID("viewport"),
				clay.Layout({sizing = layout_grow}),
				// clay.Rectangle(rectangle_rounded(clay.COLOR)),
			) {
				// empty here
			}
			// :info_container on right/bottom TODO: draw only when button pressed
			if show_info {
				if clay.UI(
					clay.ID("info_container"),
					clay.Scroll({vertical = true}),
					clay.Layout(
						{
							padding = clay.Padding {
								left = gaps,
								right = gaps,
								top = gaps,
								bottom = gaps,
							},
							sizing = info_container_sizing,
							layoutDirection = .TOP_TO_BOTTOM,
							childGap = gaps,
						},
					),
					clay.Rectangle(rectangle_rounded(MEDIUM_GRAY)),
				) {
					// info container children
					if show_sys {
						// input_posvel(ctx)
						sys_menu(ctx, camera, camera_params, system, systems, systems_reset)
					}

					// UI_textbox(ui_ctx)
				}
			}

		}
	}


	return clay.EndLayout()
}


handle_input_clay :: proc() {
	if clay.PointerOver(clay.GetElementId(clay.MakeString("Info"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		show_info = !show_info
	}
	if clay.PointerOver(clay.GetElementId(clay.MakeString("System"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		show_sys = !show_sys
	}
}


handle_input_simulation :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^[dynamic]ast.AstroSystem,
) {

	// if 

}


// edit_system_input :: proc() {}
// edit_satellite_input :: proc() {}
// edit_bodies_input :: proc() {}
// edit_camera_input :: proc() {}
