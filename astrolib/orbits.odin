package astrolib

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:os"

import am "../astromath"

OrbitType :: enum {
	LEO,
	MEO,
	GEOsync,
	GEOstat,
	HEO,
	hyperbolic,
	high_hyperbolic,
}

gen_rand_coe_orientation :: proc(
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

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, cb.mu)
	pos = pos + cb.pos
	vel = vel + cb.vel
	return pos, vel
}

gen_rand_coe :: proc(
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
	for !rp_cond && iter < am.max_iter_small {
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

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, cb.mu)
	pos = pos + cb.pos
	vel = vel + cb.vel
	return pos, vel
}

gen_rand_coe_earth :: proc(
	earth: CelestialBody,
	orbit_type: OrbitType,
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

		inc := rand.float64_uniform(0, 180)
		raan := rand.float64_uniform(0, 180)
		aop := rand.float64_uniform(0, 360)
		ta := rand.float64_uniform(0, 360)
	case .GEOstat:
		sma = 35786
		ecc = 0

		inc = 0
		raan := rand.float64_uniform(0, 180)
		aop := rand.float64_uniform(0, 360)
		ta := rand.float64_uniform(0, 360)
	case .GEOsync:
		sma = 35786
		ecc = 0

		inc := rand.float64_uniform(0, 180)
		raan := rand.float64_uniform(0, 180)
		aop := rand.float64_uniform(0, 360)
		ta := rand.float64_uniform(0, 360)
	case .MEO:
		sma = earth.semimajor_axis + rand.float64_uniform(2000, 35786)
		ecc = rand.float64_uniform(0, 0.8)
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

	pos, vel = coe_to_rv(sma, ecc, inc, raan, aop, ta, earth.mu)
	pos = pos + earth.pos
	vel = vel + earth.vel
	return pos, vel
}
