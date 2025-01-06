package astrolib


CelestialBody :: struct($T: typeid) {
	mu:                 T,
	omega:              T,
	semimajor_axis:     T,
	semiminor_axis:     T,
	eccentricity:       T,
	flattening:         T,
	inverse_flattening: T,
	third_flattening:   T,
	mean_radius:        T,
	surface_area:       T,
	volume:             T,
	pos, vel:           [3]T,
	// orientation:        quaternion,
	base_unit:          UnitsLinear,
}


wgs84 :: proc(
	units: UnitsLinear = .KILOMETER,
	$T: typeid,
) -> CelestialBody(T) {
	earth: CelestialBody(T)
	#partial switch units {
	case .METER: earth = CelestialBody(T) {
			mu                 = 3.986004418000000e+14,
			omega              = 7.292115000000000e-05,
			semimajor_axis     = 6378137.,
			semiminor_axis     = 6.356752314245179e+06,
			eccentricity       = 0.081819190842621,
			flattening         = 0.003352810664747,
			inverse_flattening = 2.982572235630000e+02,
			third_flattening   = 0.001679220386384,
			mean_radius        = 6.371008771415059e+06,
			surface_area       = 5.100656217240886e+14,
			volume             = 1.083207319801408e+21,
			base_unit          = units,
		}
	case .KILOMETER: earth = CelestialBody(T) {
			mu                 = 3.986004418000000e+05,
			omega              = 7.292115000000000e-05,
			semimajor_axis     = 6378.137,
			semiminor_axis     = 6.356752314245179e+03,
			eccentricity       = 0.081819190842621,
			flattening         = 0.003352810664747,
			inverse_flattening = 2.982572235630000e+02,
			third_flattening   = 0.001679220386384,
			mean_radius        = 6.371008771415059e+03,
			surface_area       = 5.100656217240886e+08,
			volume             = 1.083207319801408e+12,
			base_unit          = units,
		}
	case:
		panic("ERROR: units for wgs84 are incorrect")
	}
	return earth
}
