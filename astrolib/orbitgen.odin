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


rv_to_coe :: proc(
	pos, vel: [3]f64,
	mu: f64,
	units_out: am.UnitsAngle = .DEGREES,
	tol: f64 = 1.0e-12,
) -> (
	sma, ecc, inc, raan, aop, ta: f64,
) {
	r_mag := am.mag(pos)
	v_mag := am.mag(vel)

	h := la.cross(pos, vel)
	h_mag := am.mag(h)

	inc = la.acos(h[2] / h_mag)

	N := la.cross([3]f64{0, 0, 1}, h)
	N_mag := am.mag(N)

	raan = la.acos(N[0] / N_mag)
	if N[1] < 0 {
		raan = 2 * math.PI - raan
	}

	v_r := la.dot(pos, vel) / r_mag
	e := 1. / mu * ((v_mag * v_mag - mu / r_mag) * pos - la.dot(pos, vel) * vel)
	e_mag := am.mag(e)
	ecc = e_mag

	aop = la.acos(la.dot(N, e) / N_mag / e_mag)
	if e[2] < 0 {
		aop = 2 * math.PI - aop
	}

	ta = real(am.acos_complex(la.dot(e, pos) / e_mag / r_mag))
	if v_r < 0 {
		ta = 2 * math.PI - ta
	}

	E := v_mag * v_mag / 2 - mu / r_mag
	sma = -mu / 2 / E

	if math.abs(raan - 2 * math.PI) < tol {
		raan = 0
	}
	if math.abs(aop - 2 * math.PI) < tol {
		aop = 0
	}


	if units_out == .DEGREES {
		inc = am.rad_to_deg * inc
		raan = am.rad_to_deg * raan
		aop = am.rad_to_deg * aop
		ta = am.rad_to_deg * ta
	}


	return sma, ecc, inc, raan, aop, ta
}
