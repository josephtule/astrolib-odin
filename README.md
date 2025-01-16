# astrolib-odin

## Library for orbital mechanics and attitude dynamics for spacecraft

## Example

<img src="assets/example.gif" width="512">

## Controls (subject to change)

Camera Switching (satellite target, body target, origin): c
Camera Lock: Ctrl+c
Cycle Target: n/Ctrl+n
Zoom into target: Mousewheel up/down
Camera Azimuth/Elevation: w/a/s/d
Increment Substeps (physics iterations per frame): up/down
Increment Time Scale (delta time scaling): left/right
Toggle Trails: t
Toggle Wireframes: tbd
Toggle Axes: o
Toggle Position Vectors: p

## How to Build

1. Install [Odin-lang](https://odin-lang.org/docs/install/)
2. Copy myrlgl.odin into `<path_to_odin>/vendor/raylib/rlgl`
3. Create a `build` directory in the project root
4. Build and run with
   1. Mac/Linux: `<path_to_odin_binary> run . -out:build/out -o:speed`
   2. Windows: `<path_to_odin_binary> run . -out:build/out.exe -o:speed`
