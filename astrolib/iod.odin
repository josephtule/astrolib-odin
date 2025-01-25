package astrolib

import "core:math"
import la "core:math/linalg"


pos_iod_topoeq :: #force_inline proc(
	r1, r2, r3: [3]f64, // positions are topocentric equatorial
	t1, t2, t3: f64, // times in JD
	latlonh: [3]f64, // geodetic coordinates of the observation origin
	units_station: UnitsAngle = .DEGREES, // units for the station coordinates
	time_ind: int = 1,
	cb: CelestialBody,
	tol: f64 = 1.0e-6,
) -> (
	pos, vel: [3]f64,
) #no_bounds_check {
	r_station_eq := geod_to_eqfixed(latlonh, cb, units_station) // equatorial coordinates, origin is cb.pos

	// compute position vectors in inertial frame
	r1_inertial := eq_to_inertial(r1 + r_station_eq, cb)
	r2_inertial := eq_to_inertial(r2 + r_station_eq, cb)
	r3_inertial := eq_to_inertial(r3 + r_station_eq, cb)

	pos, vel = pos_iod_inertial(
		r1_inertial,
		r2_inertial,
		r3_inertial,
		t1,
		t2,
		t3,
		time_ind,
		cb,
	)

	return pos, vel
}

pos_iod_inertial :: #force_inline proc(
	r1, r2, r3: [3]f64, // positions are inertial
	t1, t2, t3: f64, // times in JD
	time_ind: int = 1,
	cb: CelestialBody,
	tol: f64 = 1.0e-6,
) -> (
	pos, vel: [3]f64,
) #no_bounds_check {

	a1 := vector_angle(r1, r2, .DEGREES)
	a2 := vector_angle(r2, r3, .DEGREES)
	a := max(a1, a2)

	if a > 20 {
		pos, vel = iod_gibbs(r1, r2, r3, t1, t2, t3, time_ind, cb)
	} else {
		pos, vel = iod_herrickgibbs(r1, r2, r3, t1, t2, t3, time_ind, cb)
	}

	return pos, vel
}

iod_gibbs :: #force_inline proc(
	r1, r2, r3: [3]f64, // positions in inertial frame
	t1, t2, t3: f64, // times are in JD
	time_ind: int = 1,
	cb: CelestialBody,
	tol: f64 = 1.0e-6,
) -> (
	pos, vel: [3]f64,
) #no_bounds_check {
	desired_time: f64
	switch desired_time {
	case 1: desired_time = t1
	case 2: desired_time = t2
	case 3: desired_time = t3
	case: desired_time = t1
	}
	r1_mag := mag(r1)
	r2_mag := mag(r2)
	r3_mag := mag(r3)

	r1_hat := r1 / r1_mag
	r23 := la.cross(r2, r3)
	r23_hat := r23 / mag(r23)
	if la.dot(r1_hat, r23_hat) > tol * r2_mag {
		panic(
			"ERROR: the three observation vectors are not in the same plane within tolerance",
		)
	}

	n :=
		r1_mag * la.cross(r2, r3) +
		r2_mag * la.cross(r3, r1) +
		r3_mag * la.cross(r1, r2)

	d := la.cross(r1, r2) + la.cross(r2, r3) + la.cross(r3, r1)

	s := r1 * (r2_mag - r3_mag) + r2 * (r3_mag - r1_mag) + r3 * (r1_mag - r2_mag)

	v2 := math.sqrt(cb.mu / (mag(n) * mag(d))) * (la.cross(d, r2) / r2_mag + s)

	// propagate to desired time
	total_time := desired_time - t2
	dt := compute_dt_inrange(total_time, N_max = 1000, dt_max = 50)
	params := Params_Gravity_Onebody {
		body          = cb,
		self_mass     = 0,
		self_radius   = 0,
		gravity_model = cb.gravity_model,
	}
	state := posvel_to_state(r2, v2)
	_, state = integrate_single_fixed(
		gravity_onebody,
		0,
		total_time,
		state,
		dt,
		&params,
		integrator = .ralston,
	)
	pos, vel = state_to_posvel(state)

	return pos, vel
}


iod_herrickgibbs :: #force_inline proc(
	r1, r2, r3: [3]f64, // positions in inertial frame
	t1, t2, t3: f64, // times are in JD
	time_ind: int = 1,
	cb: CelestialBody,
	tol: f64 = 1.0e-6,
) -> (
	pos, vel: [3]f64,
) #no_bounds_check {
	desired_time: f64
	switch desired_time {
	case 1: desired_time = t1
	case 2: desired_time = t2
	case 3: desired_time = t3
	case: desired_time = t1
	}
	r1_mag := mag(r1)
	r2_mag := mag(r2)
	r3_mag := mag(r3)

	r1_hat := r1 / r1_mag
	r23 := la.cross(r2, r3)
	r23_hat := r23 / mag(r23)
	if la.dot(r1_hat, r23_hat) > tol * r2_mag {
		panic(
			"ERROR: the three observation vectors are not in the same plane within tolerance",
		)
	}

	dt31 := t3 - t1
	dt21 := t2 - t1
	dt32 := t3 - t2
	v2 :=
		-dt32 * (1. / (dt21 * dt31) + cb.mu / (12 * r1_mag * r1_mag * r1_mag)) * r1 +
		(dt32 - dt21) *
			(1. / (dt21 * dt32) + cb.mu / (12 * r2_mag * r2_mag * r2_mag)) *
			r2 +
		dt21 * (1. / (dt32 * dt31) + cb.mu / (12 * r3_mag * r3_mag * r3_mag)) * r3

	// propagate to desired time
	total_time := desired_time - t2
	dt := compute_dt_inrange(total_time, N_max = 1000, dt_max = 50)
	params := Params_Gravity_Onebody {
		body          = cb,
		self_mass     = 0,
		self_radius   = 0,
		gravity_model = cb.gravity_model,
	}
	state := posvel_to_state(r2, v2)
	_, state = integrate_single_fixed(
		gravity_onebody,
		0,
		total_time,
		state,
		dt,
		&params,
		integrator = .ralston,
	)
	pos, vel = state_to_posvel(state)

	return pos, vel
}
