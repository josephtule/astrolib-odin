package sandbox
import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import rl "vendor:raylib"

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

	loadFont(FONT_ID_TITLE_56, 56, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_TITLE_52, 52, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_TITLE_48, 48, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_TITLE_36, 36, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_TITLE_32, 32, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_BODY_36, 36, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_BODY_30, 30, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_BODY_28, 28, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_BODY_24, 24, "assets/CascadiaMono.ttf")
	loadFont(FONT_ID_BODY_16, 16, "assets/CascadiaMono.ttf")


	debugModeEnabled: bool = false

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		animationLerpValue := rl.GetFrameTime()
		if animationLerpValue > 1 {
			animationLerpValue = animationLerpValue - 2
		}
		windowWidth = rl.GetScreenWidth()
		windowHeight = rl.GetScreenHeight()

		if rl.IsKeyPressed(.D) {
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
			animationLerpValue < 0 ? (animationLerpValue + 1) : (1 - animationLerpValue),
		)
		rl.BeginDrawing()
		clayRaylibRender(&renderCommands)
		rl.EndDrawing()
	}
}


