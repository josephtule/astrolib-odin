package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

wgs84 :: #force_inline proc(
	units: UnitsLinear = .KILOMETER,
	max_degree: int = 0,
	max_order: int = 0,
	id: int = g_body_id,
) -> CelestialBody {
	earth: CelestialBody
	#partial switch units {
	case .METER:
		earth = CelestialBody {
			mu             = 3.986004418000000e+14,
			omega          = 7.292115000000000e-05,
			semimajor_axis = 6378137.,
			semiminor_axis = 6.356752314245179e+06,
			eccentricity   = 0.081819190842621,
			flattening     = 0.003352810664747,
			// inverse_flattening = 2.982572235630000e+02,
			// third_flattening   = 0.001679220386384,
			mean_radius    = 6.371008771415059e+06,
			// surface_area   = 5.100656217240886e+14,
			// volume         = 1.083207319801408e+21,
			J              = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit      = units,
		}
		earth.mass = earth.mu / G_m
	case .KILOMETER:
		earth = CelestialBody {
			mu             = 3.986004418000000e+05,
			omega          = 7.292115000000000e-05,
			semimajor_axis = 6378.137,
			semiminor_axis = 6.356752314245179e+03,
			eccentricity   = 0.081819190842621,
			flattening     = 0.003352810664747,
			// inverse_flattening = 2.982572235630000e+02,
			// third_flattening   = 0.001679220386384,
			mean_radius    = 6.371008771415059e+03,
			// surface_area   = 5.100656217240886e+08,
			// volume         = 1.083207319801408e+12,
			J              = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit      = units,
		}
		earth.mass = earth.mu / G_km
	case:
		panic("ERROR: units for wgs84 are incorrect")
	}

	// default orientation
	earth.ep = {0, 0, 0, 1}

	earth.name = "Earth"
	earth.id = id
	g_body_id += 1
	return earth
}

luna_params :: #force_inline proc(
	units: UnitsLinear = .KILOMETER,
	max_degree: int = 0,
	max_order: int = 0,
	id: int = g_body_id,
) -> CelestialBody {
	moon: CelestialBody
	#partial switch units {
	case .KILOMETER:
		moon = {
			mu             = 4902.800118,
			omega          = 2.6616995e-6,
			semimajor_axis = 1738.1,
			semiminor_axis = 1736.0,
			flattening     = 0.0012,
			mean_radius    = 1737.4,
			// volume         = 2.1958e10,
			// surface_area   = 3.793e7,
			J              = {0, 0, 202.7e-6, 0, 0, 0, 0},
			base_unit      = units,
		}
		moon.eccentricity = ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / G_km
	case .METER:
		moon = {
			mu             = 4902.800118 * 1000 * 1000 * 1000,
			omega          = 2.6616995e-6,
			semimajor_axis = 1738.1 * 1000,
			semiminor_axis = 1736.0 * 1000,
			flattening     = 0.0012,
			mean_radius    = 1737.4 * 1000,
			// volume         = 2.1958e10 * 1000 * 1000 * 1000,
			// surface_area   = 3.793e7 * 1000 * 1000,
			J              = {0, 0, 202.7e-6, 0, 0, 0, 0},
			base_unit      = units,
		}
		moon.eccentricity = ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / G_m
	case:
		panic("ERROR: incorrect units for the moon")
	}

	// default orientation
	moon.ep = {0, 0, 0, 1}

	moon.name = "Luna"
	moon.id = id
	g_body_id += 1
	return moon
}

moon_pos :: proc(JD: f64 = 2451545.0, earth: CelestialBody) -> (pos: [3]f64) {
	deg_to_rad :: math.PI / 180.0
	rad_to_deg :: 180.0 / math.PI
	century_to_day :: 36525.0

	cent_from_j2000 := (JD - 2451545.0) / century_to_day

	// Position terms
	eclplong_deg :=
		218.32 +
		481267.8813 * cent_from_j2000 +
		6.29 * math.sin((134.9 + 477198.85 * cent_from_j2000) * deg_to_rad) -
		1.27 * math.sin((259.2 - 413335.38 * cent_from_j2000) * deg_to_rad) +
		0.66 * math.sin((235.7 + 890534.23 * cent_from_j2000) * deg_to_rad) +
		0.21 * math.sin((269.9 + 954397.70 * cent_from_j2000) * deg_to_rad) -
		0.19 * math.sin((357.5 + 35999.05 * cent_from_j2000) * deg_to_rad) -
		0.11 * math.sin((186.6 + 966404.05 * cent_from_j2000) * deg_to_rad)

	eclplat_deg :=
		5.13 * math.sin((93.3 + 483202.03 * cent_from_j2000) * deg_to_rad) +
		0.28 * math.sin((228.2 + 960400.87 * cent_from_j2000) * deg_to_rad) -
		0.28 * math.sin((318.3 + 6003.18 * cent_from_j2000) * deg_to_rad) -
		0.17 * math.sin((217.6 - 407332.20 * cent_from_j2000) * deg_to_rad)

	hzparal_deg :=
		0.9508 +
		0.0518 * math.cos((134.9 + 477198.85 * cent_from_j2000) * deg_to_rad) +
		0.0095 * math.cos((259.2 - 413335.38 * cent_from_j2000) * deg_to_rad) +
		0.0078 * math.cos((235.7 + 890534.23 * cent_from_j2000) * deg_to_rad) +
		0.0028 * math.cos((269.9 + 954397.70 * cent_from_j2000) * deg_to_rad)

	// Velocity terms (derivatives in degrees/century)
	declplong_dT :=
		481267.8813 +
		6.29 *
			477198.85 *
			math.cos((134.9 + 477198.85 * cent_from_j2000) * deg_to_rad) -
		1.27 *
			(-413335.38) *
			math.cos((259.2 - 413335.38 * cent_from_j2000) * deg_to_rad) +
		0.66 *
			890534.23 *
			math.cos((235.7 + 890534.23 * cent_from_j2000) * deg_to_rad) +
		0.21 *
			954397.70 *
			math.cos((269.9 + 954397.70 * cent_from_j2000) * deg_to_rad) -
		0.19 *
			35999.05 *
			math.cos((357.5 + 35999.05 * cent_from_j2000) * deg_to_rad) -
		0.11 *
			966404.05 *
			math.cos((186.6 + 966404.05 * cent_from_j2000) * deg_to_rad)

	declplat_dT :=
		5.13 *
			483202.03 *
			math.cos((93.3 + 483202.03 * cent_from_j2000) * deg_to_rad) +
		0.28 *
			960400.87 *
			math.cos((228.2 + 960400.87 * cent_from_j2000) * deg_to_rad) -
		0.28 * 6003.18 * math.cos((318.3 + 6003.18 * cent_from_j2000) * deg_to_rad) -
		0.17 *
			(-407332.20) *
			math.cos((217.6 - 407332.20 * cent_from_j2000) * deg_to_rad)

	dhzparal_dT :=
		-0.0518 *
			477198.85 *
			math.sin((134.9 + 477198.85 * cent_from_j2000) * deg_to_rad) +
		0.0095 *
			413335.38 *
			math.sin((259.2 - 413335.38 * cent_from_j2000) * deg_to_rad) -
		0.0078 *
			890534.23 *
			math.sin((235.7 + 890534.23 * cent_from_j2000) * deg_to_rad) -
		0.0028 *
			954397.70 *
			math.sin((269.9 + 954397.70 * cent_from_j2000) * deg_to_rad)

	// Convert parameters to radians
	eclplong := math.remainder(eclplong_deg * deg_to_rad, 2 * math.PI)
	eclplat := math.remainder(eclplat_deg * deg_to_rad, 2 * math.PI)
	hzparal := math.remainder(hzparal_deg * deg_to_rad, 2 * math.PI)

	// Convert derivatives to radians/day
	declplong_dt := declplong_dT * deg_to_rad / century_to_day
	declplat_dt := declplat_dT * deg_to_rad / century_to_day
	dhzparal_dt := dhzparal_dT * deg_to_rad / century_to_day

	// Obliquity of the ecliptic
	obliquity := (23.439291 - 0.0130042 * cent_from_j2000) * deg_to_rad

	// Direction cosines
	l := math.cos(eclplat) * math.cos(eclplong)
	m :=
		math.cos(obliquity) * math.cos(eclplat) * math.sin(eclplong) -
		math.sin(obliquity) * math.sin(eclplat)
	n :=
		math.sin(obliquity) * math.cos(eclplat) * math.sin(eclplong) +
		math.cos(obliquity) * math.sin(eclplat)

	// Position calculation
	magr := (1.0 / math.sin(hzparal)) * earth.semimajor_axis
	pos = {magr * l, magr * m, magr * n}

	// Velocity calculation, TODO: this is not working right
	dl_dt :=
		-math.sin(eclplat) * math.cos(eclplong) * declplat_dt -
		math.cos(eclplat) * math.sin(eclplong) * declplong_dt
	dm_dt :=
		math.cos(obliquity) *
			(-math.sin(eclplat) * math.sin(eclplong) * declplat_dt +
					math.cos(eclplat) * math.cos(eclplong) * declplong_dt) -
		math.sin(obliquity) * math.cos(eclplat) * declplat_dt
	dn_dt :=
		math.sin(obliquity) *
			(-math.sin(eclplat) * math.sin(eclplong) * declplat_dt +
					math.cos(eclplat) * math.cos(eclplong) * declplong_dt) +
		math.cos(obliquity) * math.cos(eclplat) * declplat_dt

	dmagr_dt :=
		(-math.cos(hzparal) / math.pow(math.sin(hzparal), 2) * dhzparal_dt) *
		earth.semimajor_axis
	vel_kmday := [3]f64 {
		dmagr_dt * l + magr * dl_dt,
		dmagr_dt * m + magr * dm_dt,
		dmagr_dt * n + magr * dn_dt,
	}

	// Convert from km/day to km/s
	vel := vel_kmday / 86400.0

	return pos
}

moon_vel :: proc(
	JD: f64 = 2451545.0,
	earth: CelestialBody,
	delta_sec: f64 = 0,
) -> (
	vel: [3]f64,
) {
	delta_JD: f64
	if delta_sec == 0 {
		delta_JD = eps_f64(JD) * 100
	} else {
		delta_JD = delta_sec / 86400.
	}
	pos_prev := moon_pos(JD - delta_JD, earth)
	pos_next := moon_pos(JD + delta_JD, earth)
	vel = (pos_next - pos_prev) / (2 * delta_JD * 86400.0)

	return vel
}

sun_location :: proc(JD: f64 = 2451545.0) -> (pos, vel: [3]f64) {
	deg_to_rad :: math.PI / 180.0
	AU_to_km :: 149597870.7 // 1 AU in kilometers
	century_to_day :: 36525.0

	tut1 := (JD - 2451545.0) / century_to_day

	// Position calculations
	meanlong_deg := 280.460 + 36000.77 * tut1
	meanlong_deg = math.remainder(meanlong_deg, 360.0)

	meananomaly_deg := 357.5277233 + 35999.05034 * tut1
	meananomaly := math.remainder(meananomaly_deg * deg_to_rad, 2 * math.PI)

	eclplong_deg :=
		meanlong_deg +
		1.914666471 * math.sin(meananomaly) +
		0.019994643 * math.sin(2.0 * meananomaly)
	eclplong_deg = math.remainder(eclplong_deg, 360.0)

	obliquity_deg := 23.439291 - 0.0130042 * tut1

	// Convert to radians
	eclplong := eclplong_deg * deg_to_rad
	obliquity := obliquity_deg * deg_to_rad

	// Calculate position magnitude (AU)
	magr_AU :=
		1.000140612 -
		0.016708617 * math.cos(meananomaly) -
		0.000139589 * math.cos(2.0 * meananomaly)

	// Position components in AU
	pos_AU := [3]f64 {
		magr_AU * math.cos(eclplong),
		magr_AU * math.cos(obliquity) * math.sin(eclplong),
		magr_AU * math.sin(obliquity) * math.sin(eclplong),
	}

	// Convert position to kilometers
	pos = pos_AU * AU_to_km

	// Velocity calculations
	// Time derivatives (per century)
	d_meanlong_dt := 36000.77 // deg/century
	d_meananomaly_dt := 35999.05034 * deg_to_rad // rad/century
	d_eclplong_dt :=
		d_meanlong_dt +
		1.914666471 * math.cos(meananomaly) * d_meananomaly_dt +
		2 * 0.019994643 * math.cos(2 * meananomaly) * d_meananomaly_dt
	d_eclplong_dt *= deg_to_rad // Convert to rad/century

	d_obliquity_dt := -0.0130042 * deg_to_rad // rad/century

	// Derivative of magnitude (AU/century)
	d_magr_dt_AU :=
		0.016708617 * math.sin(meananomaly) * d_meananomaly_dt +
		2 * 0.000139589 * math.sin(2 * meananomaly) * d_meananomaly_dt

	// Velocity components in AU/century
	dpos_dt_AU := [3]f64 {
		d_magr_dt_AU * math.cos(eclplong) -
		magr_AU * math.sin(eclplong) * d_eclplong_dt,
		d_magr_dt_AU * math.cos(obliquity) * math.sin(eclplong) +
		magr_AU *
			(-math.sin(obliquity) * math.sin(eclplong) * d_obliquity_dt +
					math.cos(obliquity) * math.cos(eclplong) * d_eclplong_dt),
		d_magr_dt_AU * math.sin(obliquity) * math.sin(eclplong) +
		magr_AU *
			(math.cos(obliquity) * math.sin(eclplong) * d_obliquity_dt +
					math.sin(obliquity) * math.cos(eclplong) * d_eclplong_dt),
	}

	// Convert velocity to km/s
	// AU/century -> km/day: (AU/century) * AU_to_km / 36525
	// km/day -> km/s: / 86400
	vel_kmps := (dpos_dt_AU * AU_to_km) / (century_to_day * 86400.0)
	vel = vel_kmps

	return pos, vel
}
