package sandbox

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

import ast "../astrolib"

windowWidth: i32 = 1024
windowHeight: i32 = 768


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
		{handler = errorHandler},
	)
	clay.SetMeasureTextFunction(measureText, 0)

	rl.SetConfigFlags(
		{.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI, .MSAA_4X_HINT},
	)
	rl.InitWindow(windowWidth, windowHeight, "AstroLib")
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))

	loadFont(FONT_ID_BODY_12, 12, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_14, 14, "assets/CascadiaMono.ttf") 
    loadFont(FONT_ID_BODY_16, 16, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_18, 18, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_20, 20, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_24, 24, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_28, 28, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_30, 30, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_32, 32, "assets/CascadiaMono.ttf")
    loadFont(FONT_ID_BODY_36, 36, "assets/CascadiaMono.ttf")

	// raylib 3d camera default
	camera: rl.Camera3D
	camera.target = ast.origin_f32
	camera.position = ast.azel_to_cart(
		[3]f32{math.PI / 4, math.PI / 4, 10},
		.RADIANS,
	)
	camera.up = {0.0, 0.0, 1.0}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE
	camera_params := CameraParams {
		azel  = ast.cart_to_azel(ast.cast_f64(camera.position), .RADIANS),
		frame = .origin,
	}

	// set up system/systems
	system := ast.create_system() // current system
	systems: [dynamic]ast.AstroSystem // dynamic array of system (used to copy system config to current)

	debugModeEnabled: bool = false

	for !rl.WindowShouldClose() {
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


		renderCommands: clay.ClayArray(clay.RenderCommand) = createLayout(
			&camera,
			&camera_params,
			&system,
			&systems,
		)


		rl.BeginDrawing()
		rl.ClearBackground(rl.Color({35, 35, 35, 255}))
		rl.BeginMode3D(camera)


		rl.DrawLine3D(origin, x_axis * 25, rl.RED)
		rl.DrawLine3D(origin, y_axis * 25, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 25, rl.DARKBLUE)
		rl.EndMode3D()
		clayRaylibRender(&renderCommands)
		rl.EndDrawing()
	}
}
origin: [3]f32 = {0, 0, 0}
x_axis: [3]f32 : {1, 0, 0}
y_axis: [3]f32 : {0, 1, 0}
z_axis: [3]f32 : {0, 0, 1}
