package sandbox

import clay "../external/clay-odin"
import "../ui"
import "core:c"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

import ast "../astrolib"

windowWidth: i32 = 1024
windowHeight: i32 = 768

u_to_rl :: ast.u_to_rl

main :: proc() {

	minMemorySize: u32 = clay.MinMemorySize()
	memory := make([^]u8, minMemorySize)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(
		minMemorySize,
		memory,
	)
	clay.Initialize(
		arena,
		{cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()},
		{handler = ui.errorHandler},
	)
	clay.SetMeasureTextFunction(ui.measureText, 0)

	rl.SetConfigFlags(
		{ .WINDOW_RESIZABLE, .WINDOW_HIGHDPI, .MSAA_4X_HINT},
	)
	rl.InitWindow(windowWidth, windowHeight, "AstroLib")
	// rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))

	ui.loadFont(ui.FONT_ID_BODY_12, 12, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_14, 14, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_16, 16, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_18, 18, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_20, 20, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_24, 24, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_28, 28, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_30, 30, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_32, 32, "assets/CascadiaMono.ttf")
	ui.loadFont(ui.FONT_ID_BODY_36, 36, "assets/CascadiaMono.ttf")

	ctx: ui.Context

	// raylib 3d camera default
	camera: rl.Camera3D
	camera.target = ast.origin_f32
	camera.position = ast.azel_to_cart(
		[3]f32{math.PI / 4, math.PI / 4, 15000 * u_to_rl},
		.RADIANS,
	)
	camera.up = {0.0, 0.0, 1.0}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE
	camera_params := ui.CameraParams {
		azel  = ast.cart_to_azel(ast.cast_f64(camera.position), .RADIANS),
		frame = .origin,
	}

	// set up system/systems
	systems, systems_reset := ast.create_systems()
	system := ast.create_system()
	ast.add_system(&systems, &systems_reset, system)

	// TODO: remove this later
	earth := ast.wgs84()
	earth.gravity_model = .pointmass
	earth.max_degree = 2
	earth.fixed = true
	q := la.quaternion_from_euler_angle_x(math.to_radians(f64(23.5)))
	earth.ep = ast.quaternion_to_euler_param(q)
	earth.update_attitude = true
	model_size :=
		[3]f32 {
			f32(earth.semimajor_axis),
			f32(earth.semiminor_axis),
			f32(earth.semiminor_axis),
		} *
		u_to_rl
	earth_model := ast.gen_celestialbody_model(
		earth,
		model_size = model_size,
		faces = 128,
	)
	earth_model.axes.draw = true
	ast.add_to_system(&system, earth)
	ast.add_to_system(&system, earth_model)

	debugModeEnabled: bool = false
	// :TIME
	dt: f64
	cum_time: f64
	sim_time: f64
	fps: f64
	dt_max: f64 : 1. / 30.

show_fps := false

	for !rl.WindowShouldClose() {

		dt = f64(rl.GetFrameTime())
		dt = dt < dt_max ? dt : dt_max // set dt max
		fps = 1. / dt
		cum_time += dt
		sim_time += dt * system.time_scale

		if rl.IsKeyPressed(.F) {
			show_fps = !show_fps
		}
		if show_fps {
			fmt.println(fps)
		}

		if system.simulate {
			for k := 0; k < system.substeps; k += 1 {
				sim_time += dt
				ast.update_system(&system, dt, sim_time)
			}
		}

		defer free_all(context.temp_allocator)

		animationLerpValue := rl.GetFrameTime()
		if animationLerpValue > 1 {
			animationLerpValue = animationLerpValue - 2
		}
		windowWidth = rl.GetScreenWidth()
		windowHeight = rl.GetScreenHeight()

		if rl.IsKeyPressed(.GRAVE) {
			debugModeEnabled = !debugModeEnabled
			clay.SetDebugModeEnabled(debugModeEnabled)
		}

		clay.SetPointerState(
			transmute(clay.Vector2)rl.GetMousePosition(),
			rl.IsMouseButtonDown(.LEFT),
		)
		clay.UpdateScrollContainers(
			false,
			transmute(clay.Vector2)rl.GetMouseWheelMoveV(),
			rl.GetFrameTime(),
		)
		clay.SetLayoutDimensions(
			{cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()},
		)


		renderCommands: clay.ClayArray(clay.RenderCommand) = ui.createLayout(
			&ctx,
			&camera,
			&camera_params,
			&system,
			&systems,
			&systems_reset,
		)


		rl.BeginDrawing()
		rl.ClearBackground(rl.Color({35, 35, 35, 255}))

		rl.BeginMode3D(camera)

		// draw system
		ast.draw_system(&system)
		rl.DrawLine3D(origin, x_axis * 25, rl.RED)
		rl.DrawLine3D(origin, y_axis * 25, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 25, rl.DARKBLUE)

		rl.EndMode3D()
		ui.clayRaylibRender(&renderCommands)
		rl.EndDrawing()
	}
}
origin: [3]f32 = {0, 0, 0}
x_axis: [3]f32 : {1, 0, 0}
y_axis: [3]f32 : {0, 1, 0}
z_axis: [3]f32 : {0, 0, 1}
