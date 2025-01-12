package astrolib

import am "../astromath"
import "core:math"
import la "core:math/linalg"

coe_to_rv :: proc(
	a, ecc, inc, raan, aop, ta: f64,
	mu: f64,
	tol: f64 = 1.0e-12,
	units_in: am.UnitsAngle = .DEGREES,
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
	v_pqw: [3]f64 = {-math.sqrt(mu / p) * sa, math.sqrt(mu / p) * (ecc + ca), 0.}

	R := am.ea_to_dcm([3]f64{-aop, -inc, -raan}, {3, 1, 3})

	r_inertial := R * r_pqw
	v_inertial := R * v_pqw
	return r_inertial, v_inertial
}


