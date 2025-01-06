package astrolib


Satellite :: struct {
	mass:            f64,
	radius:          f64,
	pos, vel, omega: [3]f64,
	ep:              [4]f64,
	linear_units:    UnitsLinear,
	angular_units:   UnitsAngle,
}
