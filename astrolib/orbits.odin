package astrolib

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:os"


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
