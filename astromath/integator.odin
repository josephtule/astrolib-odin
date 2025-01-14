package astromath

import am "../astromath"
import "core:math"
import la "core:math/linalg"

IntegratorType :: enum {
	rk1, // same as euler 
	rk2, // same as midpoint
	rk3,
	rk4,
	rk5,
	rk6,
	heun,
	ralston,
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
	case .rk3: time, state = rk3_step(f, t, x, dt, params)
	case .rk2: time, state = rk2_step(f, t, x, dt, params)
	case .rk4: time, state = rk4_step(f, t, x, dt, params)
	case .rk5: time, state = rk5_step(f, t, x, dt, params)
	case .rk6: time, state = rk6_step(f, t, x, dt, params)
	case .heun: time, state = heun_step(f, t, x, dt, params)
	case .ralston: time, state = ralston_step(f, t, x, dt, params)
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

rk3_step :: proc(
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
	k3 := f(t + dt, x - dt * k1 + 2. * dt * k2, params)
	x_new := x + dt * (k1 + 4. * k2 + k3) / 6.
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

rk5_step :: proc(
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
    k2 := f(t + dt / 4., x + dt * k1 / 4., params)
    k3 := f(t + dt / 4., x + dt * (k1 / 8. + k2 / 8.), params)
    k4 := f(t + dt / 2., x + dt * (-k2 / 2. + k3), params)
    k5 := f(t + 3. * dt / 4., x + dt * (3. * k1 / 16. + 9. * k4 / 16.), params)
    k6 := f(t + dt, x + dt * (-3. * k1 / 7. + 2. * k2 / 7. + 12. * k3 / 7. - 12. * k4 / 7. + 8. * k5 / 7.), params)
    x_new := x + dt * (7. * k1 / 90. + 32. * k3 / 90. + 12. * k4 / 90. + 32. * k5 / 90. + 7. * k6 / 90.)
    t_new := t + dt
    return t_new, x_new
}

rk6_step :: proc(
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
    k2 := f(t + dt / 5., x + dt * k1 / 5., params)
    k3 := f(t + dt / 5., x + dt * (3. * k1 / 40. + 9. * k2 / 40.), params)
    k4 := f(t + dt / 2., x + dt * (3. * k1 / 10. - 9. * k2 / 10. + 6. * k3 / 10.), params)
    k5 := f(t + 3. * dt / 4., x + dt * (-11. * k1 / 54. + 5. * k2 / 2. - 70. * k3 / 27. + 35. * k4 / 27.), params)
    k6 := f(t + dt, x + dt * (1631. * k1 / 55296. + 175. * k2 / 512. + 575. * k3 / 13824. + 44275. * k4 / 110592. + 253. * k5 / 4096.), params)
    k7 := f(t + dt, x + dt * (37. * k1 / 378. + 0. * k2 + 250. * k3 / 621. + 125. * k4 / 594. + 0. * k5 + 512. * k6 / 1771.), params)
    x_new := x + dt * (37. * k1 / 378. + 0. * k2 + 250. * k3 / 621. + 125. * k4 / 594. + 0. * k5 + 512. * k6 / 1771.)
    t_new := t + dt
    return t_new, x_new
}

heun_step :: proc(
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
	k2 := f(t + dt, x + dt * k1, params)
	x_new := x + dt * (k1 + k2) / 2.
	t_new := t + dt
	return t_new, x_new
}

ralston_step :: proc(
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
	k2 := f(t + 3. * dt / 4., x + 3. * dt * k1 / 4., params)
	x_new := x + dt * (k1 / 3. + 2. * k2 / 3.)
	t_new := t + dt
	return t_new, x_new
}
