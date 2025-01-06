package integator

import "core:math"
import la "core:math/linalg"
import am "../astromath"


rk4_step :: proc(
	f: proc(t: $T, x: [$N]T, params: rawptr) -> [N]T,
	t: T,
	x: [N]T,
	dt: T,
	params: rawptr,
) -> (
	T,
	[N]T,
) {
	k1 := f(t, x, params)
	k2 := f(t + dt / 2., x + dt * k1 / 2.,params)
	k3 := f(t + dt / 2., x + dt * k2 / 2.,params)
	k4 := f(t + dt, x + dt * k3,params)
	x_new := x + dt / 6. * (k1 + 2 * k2 + 2 * k3 + k4)
	t_new := t + dt
	return t_new, x_new
}

