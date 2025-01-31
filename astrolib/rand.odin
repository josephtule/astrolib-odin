package astrolib

import "core:math"
import la "core:math/linalg"
import "core:math/rand"

randn_vf64 :: proc(mean, std: f64, $N: int) -> (vec: [N]f64) {
	for &elem in vec {
		elem = rand.float64_normal(mean, std)
	}
	return vec
}

randu_vf64 :: proc(low, high: f64, $N: int) -> (vec: [N]f64) {
	for &elem in vec {
		elem = rand.float64_uniform(low, high)
	}
	return vec
}
