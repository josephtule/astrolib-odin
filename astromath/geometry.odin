package astromath

import "core:math"
import la "core:math/linalg"

ecc_from_flat :: proc(flat: $T) -> T {
    ecc := math.sqrt(2*flat - flat*flat)
    return ecc
}