package astromath

import "core:math"
import la "core:math/linalg"

deg_to_rad :: math.PI / 180.
rad_to_deg :: 180. / math.PI


ecc_from_flat :: #force_inline proc(flat: $T) -> T {
	ecc := math.sqrt(2 * flat - flat * flat)
	return ecc
}

dms_to_deg :: #force_inline proc(
	deg: $T,
	min: T,
	sec: T,
) -> T where intrinsics.type_is_numeric(T) {
	degs := abs(deg) + min / T(60) + sec / T(3600)
	if deg < 0 {
		degs = -degs
	}
	return degs
}

acos_complex :: proc(x: f64) -> complex128 {
	if math.abs(x) <= 1 {
		return complex(math.acos(x), 0)
	} else {
		imag_part: f64 = math.ln(abs(x) + math.sqrt(x * x - 1))
		if x < -1 {
			return complex(math.PI, -imag_part) // Negative x adds a phase shift
		} else {
			return complex(0, imag_part)
		}
	}
}
