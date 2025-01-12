package astromath

import am "../astromath"
import "core:math"
import la "core:math/linalg"

IntegratorType :: enum {
	rk1, // same as euler 
	rk2, // same as midpoint
	rk4,
	// velocity_verlet, // TODO: add?
}

integrate :: proc(
	f: proc(t: $T, x: [$N]T, params: rawptr) -> [N]T,
	t: T,
	x: [N]T,
	dt: T,
	params: rawptr,
	integrator: IntegratorType = .rk4,
) -> (
	T,
	[N]T,
) {
	time: T
	state: [N]T
	switch integrator {
	case .rk1: time, state = rk1_step(f, t, x, dt, params)
	case .rk2: time, state = rk2_step(f, t, x, dt, params)
	case .rk4: time, state = rk4_step(f, t, x, dt, params)
	}
	return time, state
}

rk1_step :: proc(
	f: proc(t: $T, x: [$N]T, params: rawptr) -> [N]T,
	t: T,
	x: [N]T,
	dt: T,
	params: rawptr,
) -> (
	T,
	[N]T,
) {
	dx := f(t, x, params)
	x_new := x + dt * dx
	t_new := t + dt
	return t_new, x_new
}

rk2_step :: proc(
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
	k2 := f(t + dt / 2., x + dt * k1 / 2., params)
	x_new := x + dt * k2
	t_new := t + dt
	return t_new, x_new
}

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
	k2 := f(t + dt / 2., x + dt * k1 / 2., params)
	k3 := f(t + dt / 2., x + dt * k2 / 2., params)
	k4 := f(t + dt, x + dt * k3, params)
	x_new := x + dt / 6. * (k1 + 2 * k2 + 2 * k3 + k4)
	t_new := t + dt
	return t_new, x_new
}
