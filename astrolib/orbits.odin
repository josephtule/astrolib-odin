package astrolib

import "core:math"
import la "core:math/linalg"
import "core:math/rand"

EarthOrbitType :: enum {
	LEO = 0,
	MEO,
	GEO, // geostationary
	GSO, // geosynchronous
	HEO, // high earth orbit
	HECCO, // highly eccentric orbits
	hyperbolic,
	high_hyperbolic,
}


coe_to_rv :: #force_inline proc(
	a, ecc, inc, raan, aop, ta: f64,
	cb: CelestialBody,
	tol: f64 = 1.0e-12,
	units_in: UnitsAngle = .DEGREES,
) -> (
	pos, vel: [3]f64,
) {
	inc := inc
	ta := ta
	aop := aop
	raan := raan
	if units_in == .DEGREES {
		inc = math.to_radians(inc)
		ta = math.to_radians(ta)
		aop = math.to_radians(aop)
		raan = math.to_radians(raan)
	}

	anom: f64
	if (ecc < tol) && (inc < tol) {
		anom = ta + raan + aop
		aop = 0
		raan = 0
	} else if (ecc < tol) && (inc > tol) {
		anom = ta + aop
		aop = 0
	} else if (ecc > tol) && (inc < tol) {
		anom = raan + aop
		raan = 0
	} else {
		anom = ta
	}

	// semi latus rectum
	p: f64
	if ecc != 1 {
		p = a * (1. - ecc * ecc)

	} else {
		p = math.nan_f64()
	}

	ca := math.cos(anom)
	sa := math.sin(anom)

	r_pqw: [3]f64 = {p * ca / (1 + ecc * ca), p * sa / (1 + ecc * ca), 0.}
	v_pqw: [3]f64 = {
		-math.sqrt(cb.mu / p) * sa,
		math.sqrt(cb.mu / p) * (ecc + ca),
		0.,
	}

	// rotate into equatorial frame (body fixed)
	seq := [3]RotAxis{.z,.x,.z}
	R := ea_to_dcm([3]f64{-aop, -inc, -raan}, seq)
	pos = R * r_pqw
	vel = R * v_pqw

	// rotate into inertial frame
	R = la.matrix3_from_quaternion(euler_param_to_quaternion(cb.ep)) // rotation to equatorial plane
	pos = R * pos + cb.pos
	vel = R * vel + cb.vel
	return pos, vel
}


rv_to_coe :: #force_inline proc(
	pos, vel: [3]f64, // inertial input
	cb: CelestialBody,
	units_out: UnitsAngle = .DEGREES,
	tol: f64 = 1.0e-12,
) -> (
	sma, ecc, inc, raan, aop, ta: f64,
) {
	// FIXME: not sure if this is right
	// rotate into equatorial frame (body fixed)
	R := la.transpose(
		la.matrix3_from_quaternion(euler_param_to_quaternion(cb.ep)),
	)
	pos := R * (pos - cb.pos)
	vel := R * (vel - cb.vel)

	r_mag := mag(pos)
	v_mag := mag(vel)

	h := la.cross(pos, vel)
	h_mag := mag(h)

	inc = la.acos(h[2] / h_mag)

	N := la.cross([3]f64{0, 0, 1}, h)
	N_mag := mag(N)

	raan = la.acos(N[0] / N_mag)
	if N[1] < 0 {
		raan = 2 * math.PI - raan
	}

	v_r := la.dot(pos, vel) / r_mag
	e :=
		1. / cb.mu * ((v_mag * v_mag - cb.mu / r_mag) * pos - la.dot(pos, vel) * vel)
	e_mag := mag(e)
	ecc = e_mag

	aop = la.acos(la.dot(N, e) / N_mag / e_mag)
	if e[2] < 0 {
		aop = 2 * math.PI - aop
	}

	ta = real(acos_complex(la.dot(e, pos) / e_mag / r_mag))
	if v_r < 0 {
		ta = 2 * math.PI - ta
	}

	E := v_mag * v_mag / 2 - cb.mu / r_mag
	sma = -cb.mu / 2 / E

	if math.abs(raan - 2 * math.PI) < tol {
		raan = 0
	}
	if math.abs(aop - 2 * math.PI) < tol {
		aop = 0
	}

	if units_out == .DEGREES {
		inc = rad_to_deg * inc
		raan = rad_to_deg * raan
		aop = rad_to_deg * aop
		ta = rad_to_deg * ta
	}


	return sma, ecc, inc, raan, aop, ta
}

gen_rand_coe_orientation :: #force_inline proc(
	sma: f64,
	ecc: f64,
	cb: CelestialBody,
) -> (
	pos, vel: [3]f64,
) {
	inc := rand.float64_uniform(0, 180)
	raan := rand.float64_uniform(0, 180)
	aop := rand.float64_uniform(0, 360)
	ta := rand.float64_uniform(0, 360)

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, cb)
	return pos, vel
}

gen_rand_coe :: #force_inline proc(
	cb: CelestialBody,
	sma_max: f64 = -1,
	ecc_max: f64 = -1,
	closed: bool = true,
	high_hyper: bool = false,
) -> (
	pos, vel: [3]f64,
) {
	sma, ecc: f64
	sma_max := sma_max
	ecc_max := ecc_max
	rp_cond: bool = false
	iter := 0
	for !rp_cond && iter < max_iter_small {
		if sma_max == -1 {
			sma_max = 100 * cb.semimajor_axis
		}
		sma := rand.float64_uniform(cb.semimajor_axis, sma_max)
		if closed {
			if ecc_max == -1 {
				ecc_max = 0.9999
			}
			ecc = rand.float64_uniform(0, ecc_max)
		} else {
			if high_hyper {
				ecc = rand.float64_uniform(5, 10)
			} else {
				ecc = rand.float64_uniform(1.01, 5)
			}
		}
		rp := sma * (1 - ecc)
		if rp > sma + 1 { 	// minimum altitude of 1km
			rp_cond = true
		}
	}

	inc := rand.float64_uniform(0, 180)
	raan := rand.float64_uniform(0, 180)
	aop := rand.float64_uniform(0, 360)
	ta := rand.float64_uniform(0, 360)

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, cb)
	return pos, vel
}

gen_rand_coe_earth :: #force_inline proc(
	earth: CelestialBody,
	orbit_type: EarthOrbitType,
) -> (
	pos, vel: [3]f64,
) {
	// NOTE: values for different orbits subject to change 
	sma: f64
	ecc: f64
	inc: f64
	raan: f64
	aop: f64
	ta: f64

	switch orbit_type {
	case .LEO:
		sma = earth.semimajor_axis + rand.float64_uniform(100, 2000)
		ecc = rand.float64_uniform(0, 0.25)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 180)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .GEO:
		sma = 35786
		ecc = 0

		inc = rand.float64_uniform(0., 5.)
		raan = 0
		aop = 0
		ta = rand.float64_uniform(0., 360.)
	case .GSO:
		sma = 35786
		ecc = rand.float64_uniform(0., 0.05)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 180)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .MEO:
		sma = earth.semimajor_axis + rand.float64_uniform(2000, 35786)
		ecc = rand.float64_uniform(0, 0.25)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 360)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .HEO:
		sma = earth.semimajor_axis + rand.float64_uniform(35786, 384000)
		ecc = rand.float64_uniform(0, 0.5)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 360)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .HECCO:
		sma = earth.semimajor_axis + rand.float64_uniform(35786, 384000)
		ecc = rand.float64_uniform(0.5, 0.85)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 360)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .hyperbolic:
		sma = -rand.float64_uniform(
			earth.semimajor_axis + 10000,
			earth.semimajor_axis + 100000,
		)
		ecc = rand.float64_uniform(1.01, 5.0)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 360)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	case .high_hyperbolic:
		sma = -rand.float64_uniform(
			earth.semimajor_axis + 100000,
			earth.semimajor_axis + 1000000,
		)
		ecc = rand.float64_uniform(3.0, 10.0)

		inc = rand.float64_uniform(0, 180)
		raan = rand.float64_uniform(0, 360)
		aop = rand.float64_uniform(0, 360)
		ta = rand.float64_uniform(0, 360)
	}

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, earth)
	return pos, vel
}


orbital_energy :: proc {
	orbital_energy_posvel,
	orbital_energy_sma,
	orbital_energy_angecc,
}

orbital_energy_posvel :: #force_inline proc(pos, vel: [3]f64, mu: f64) -> f64 {
	return 0.5 * mag2(vel) - mu / mag(pos)
}

orbital_energy_sma :: #force_inline proc(a, mu: f64) -> f64 {
	return -mu / (2. * a)
}

orbital_energy_angecc :: #force_inline proc(h: [3]f64, ecc, mu: f64) -> f64 {
	return -0.5 * (mu * mu / mag2(h) * (1 - ecc * ecc))
}


