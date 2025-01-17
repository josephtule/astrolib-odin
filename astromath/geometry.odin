package astromath

import "core:math"
import la "core:math/linalg"

ecc_from_flat :: proc(flat: $T) -> T {
	ecc := math.sqrt(2 * flat - flat * flat)
	return ecc
}

dms_to_deg :: proc(
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
