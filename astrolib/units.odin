package astrolib

import "base:intrinsics"
import "core:math"

UnitsAngle :: enum {
	DEGREES,
	RADIANS,
	ARCSEC,
	MINUTES,
}

UnitsLinear :: enum {
	MILLIMETER,
	METER,
	CENTIMETER,
	KILOMETER,
	FOOT,
	INCH,
	AU,
}

UnitsTime :: enum {
	YEAR,
	MONTH,
	DAY,
	HOUR,
	MINUTE,
	SECOND,
}


deg_to_rad :: math.PI / 180.
rad_to_deg :: 180. / math.PI


convert_angle :: #force_inline proc "contextless" (
	val: $T,
	units_in, units_out: UnitsAngle,
) -> T where intrinsics.type_is_float(T) #no_bounds_check {
	val := val
	// convert to radians 
	switch units_in {
	case .RADIANS:
	case .DEGREES: val *= deg_to_rad
	case .MINUTES: val *= deg_to_rad / 60.
	case .ARCSEC: val *= deg_to_rad / 3600.
	}

	// convert to output
	switch units_out {
	case .RADIANS:
	case .DEGREES: val *= rad_to_deg
	case .MINUTES: val *= rad_to_deg * 60.
	case .ARCSEC: val *= rad_to_deg * 3600
	}

	return val
}

convert_linear :: #force_inline proc "contextless" (
	val: $T,
	units_in, units_out: UnitsLinear,
) -> T where intrinsics.type_is_float(T) #no_bounds_check {
	val := val
	// convert to kilometer
	switch units_in {
	case .MILLIMETER: val *= 1.0e-6
	case .CENTIMETER: val *= 1.0e-5
	case .METER: val *= 1.0e-3
	case .KILOMETER:
	case .FOOT: val *= 0.3048 * 1.0e-3
	case .INCH: val *= 0.3048 * 1.0e-3 / 12.
	case .AU: val *= 149597870.691
	}

	switch units_out {
	case .MILLIMETER: val /= 1.0e-6
	case .CENTIMETER: val /= 1.0e-5
	case .METER: val /= 1.0e-3
	case .KILOMETER:
	case .FOOT: val /= 0.3048 * 1.0e-3
	case .INCH: val /= 0.3048 * 1.0e-3 / 12.
	case .AU: val /= 149597870.691
	}
	return val
}

// convert_time :: #force_inline proc "contextless" () #no_bounds_check
// convert_time_scale :: #force_inline proc "contextless" () #no_bounds_check
