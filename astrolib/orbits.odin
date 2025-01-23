package astrolib

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:os"

import am "../astromath"

orbital_energy :: proc {
	orbital_energy_posvel,
	orbital_energy_sma,
	orbital_energy_angecc,
}

orbital_energy_posvel :: proc(pos, vel: [3]f64, mu: f64) -> f64 {
	return 0.5 * am.mag2(vel) - mu / am.mag(pos)
}

orbital_energy_sma :: proc(a, mu: f64) -> f64 {
	return -mu / (2. * a)
}

orbital_energy_angecc :: proc(h: [3]f64, ecc, mu: f64) -> f64 {
	return -0.5 * (mu * mu / am.mag2(h) * (1 - ecc * ecc))
}
