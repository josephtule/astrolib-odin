package astromath

import "core:math"

eps :: proc{eps_f64,eps_f32, eps_f16}

eps_f64 :: proc(x: f64) -> f64 {
	if x == 0.0 {
		return 2.2250738585072014e-308
	} else if math.is_nan(x) || math.is_inf(x) {
		return math.nan_f64()
	} else {
		// extract exponent
		exponent := math.floor(math.log2(math.abs(x)))
		return math.pow_f64(2.0, exponent - 52) // 52 is the mantissa bit count in double precision
	}
}

eps_f32 :: proc(x: f32) -> f32 {
	if x == 0.0 {
		return 1.1754943508222875e-38
	} else if math.is_nan(x) || math.is_inf(x) {
		return math.nan_f32()
	} else {
		// extract exponent
		exponent := math.floor(math.log2(math.abs(x)))
		return math.pow(2.0, exponent - 23) // 52 is the mantissa bit count in double precision
	}
}
eps_f16 :: proc(x: f16) -> f16 {
	if x == 0.0 {
		return 6.103515625e-5
	} else if math.is_nan(x) || math.is_inf(x) {
		return math.nan_f16()
	} else {
		// extract exponent
		exponent := math.floor(math.log2(math.abs(x)))
		return math.pow_f16(2.0, exponent - 10) // 52 is the mantissa bit count in double precision
	}
}
	// case f64:
	// 	fmin = 2.2250738585072014e-308
	// 	mantissa_bits = 52
	// case f32:
	// 	fmin = 1.1754943508222875e-38
	// 	mantissa_bits = 23
	// case f16:
	// 	fmin = 6.103515625e-5
	// 	mantissa_bits = 10