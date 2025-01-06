package astrolib


Satellite :: struct {
	mass:      f64,
	radius:    f64,
	pos, vel:  [3]f64,
	base_unit: UnitsLinear,
}
