package sandbox

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import rl "vendor:raylib"
import "core:mem"
import "core:mem/virtual"

import ast "../astrolib"

Context_Status :: enum u8 {
	RULES,
	VOLUME,
	CONNECTED,
}
Context_Statuses :: bit_set[Context_Status]

Context :: struct {
	ui_ctx:          UI_Context,
	// rule modification
	active_line_buf: [1024]u8,
	active_line_len: int,
	active_line:     int,
	volume:          f32,
	// rule creation
	new_rule_buf:    [1024]u8,
	new_rule_len:    int,
	// config state
	aux_rules:       [dynamic]string,
	config_file:     string,
	// inotify_fd:      linux.Fd,
	// inotify_wd:      linux.Wd,
	statuses:        Context_Statuses,
	// ipc
	// ipc:             IPC_Client_Context,
	// allocations
	arena:           virtual.Arena,
	allocator:       mem.Allocator,
}

clay_layout_grow := clay.Sizing {
	width  = clay.SizingGrow({}),
	height = clay.SizingGrow({}),
}

clay_rectangle_rounded :: proc(
	color: clay.Color,
) -> clay.RectangleElementConfig {
	rect := clay.RectangleElementConfig(
		{color = color, cornerRadius = clay.CornerRadiusAll(8)},
	)

	return rect
}

gaps :: 8
show_info := false


createLayout :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ^ast.AstroSystem,
	systems: ^[dynamic]ast.AstroSystem,
) -> clay.ClayArray(clay.RenderCommand) {
    ctx := context
	mobileScreen := windowWidth < 750
    handle_clay_input_clay()
	clay.BeginLayout()

	// :outer container
	if clay.UI(
		clay.ID("outer_container"),
		clay.Layout(
			{
				layoutDirection = .TOP_TO_BOTTOM,
				sizing = clay_layout_grow,
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
					childGap = gaps * 2,
					childAlignment = clay.ChildAlignment{y = .CENTER},
				},
			),
		) {
			clay.Text("AstroLib", &headerTextConfig)
			header_button("Simulate")
			header_button("Info")
			if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({})}})) {} 	// spacer
			if show_info {
				header_button("Edit System")
				header_button("Edit Satellites")
				header_button("Edit Bodies")
				header_button("Edit Camera")
			}
		}

		// :lower content
		// TODO: make infobar scrollable
		lower_dir: clay.LayoutDirection
		infobar_sizing: clay.Sizing
		if mobileScreen {
			lower_dir = .TOP_TO_BOTTOM
			infobar_sizing = {
				width  = clay.SizingGrow({}),
				height = clay.SizingFixed(0.25 * f32(rl.GetScreenHeight())),
			}
		} else {
			lower_dir = .LEFT_TO_RIGHT
			infobar_sizing = {
				width  = clay.SizingFixed(0.33 * f32(rl.GetScreenWidth())),
				height = clay.SizingGrow({}),
			}
		}
		if clay.UI(
			clay.ID("lower_content"),
			clay.Layout(
				{sizing = clay_layout_grow, childGap = gaps, layoutDirection = lower_dir},
			),
		) {
			// :viewport on left/top (transparent to display raylib camera below)
			if clay.UI(
				clay.ID("viewport"),
				clay.Layout({sizing = clay_layout_grow}),
				// clay.Rectangle(clay_rectangle_rounded(clay.COLOR)),
			) {
				// empty here
			}
			// :infobar on right/bottom TODO: draw only when button pressed
			if show_info {
				if clay.UI(
					clay.ID("infobar"),
					clay.Scroll({vertical = true}),
					clay.Layout({sizing = infobar_sizing, layoutDirection = .TOP_TO_BOTTOM}),
					clay.Rectangle(clay_rectangle_rounded(MEDIUM_GRAY)),
				) {
                    // UI_textbox(ctx,)
				}
			}

		}
	}


	return clay.EndLayout()
}


handle_clay_input_clay :: proc() {
	if clay.PointerOver(clay.GetElementId(clay.MakeString("Info"))) &&
	   rl.IsMouseButtonPressed(.LEFT) {
		show_info = !show_info
	}
}
handle_clay_input_simulation :: proc(
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
