package astrolib


import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"


earth_moon_system :: proc(
	JD: f64 = 2451545.0, // defaults// default to J2000 TT
) -> (
	system: AstroSystem,
) {
	system = create_system()
	system.time_scale = 8
	id_buf: [8]byte
	id_str: string = strconv.itoa(id_buf[:], system.id)
	system.name, _ = strings.join(
		[]string{"Earth-Moon System", " (ID: ", id_str, ")"},
		"",
	)

	model_size: [3]f32

	// earth 
	earth := wgs84()
	earth.fixed = false
	earth.update_attitude = true
	model_size =
		[3]f32 {
			f32(earth.semimajor_axis),
			f32(earth.semiminor_axis),
			f32(earth.semiminor_axis),
		} *
		u_to_rl
	earth_model := gen_celestialbody_model(
		earth,
		model_size = model_size,
		faces = 128,
	)
	earth_model.axes.draw = true

	// moon
	moon := luna_params()
	// NOTE: this is an inaccurate way to get position/velocity, use SPICE for high accuracy
	moon.pos = moon_pos(JD, earth)
	moon.vel = moon_vel(JD, earth)
	model_size =
		[3]f32 {
			f32(moon.semimajor_axis),
			f32(moon.semiminor_axis),
			f32(moon.semiminor_axis),
		} *
		u_to_rl
	moon_model := gen_celestialbody_model(
		moon,
		model_size,
		tint = rl.Color{150, 150, 150, 255},
	)

	moon_model.posvel.draw_pos = true
	moon_model.posvel.draw_vel = true
	moon_model.posvel.target_id = earth.id
	moon_model.posvel.pos_tint = rl.PURPLE
	moon_model.posvel.vel_tint = rl.MAROON
	moon_model.posvel.vel_scale = 5000

	// add to system
	add_to_system(&system, earth)
	add_to_system(&system, earth_model)

	add_to_system(&system, moon)
	add_to_system(&system, moon_model)

	return system
}

earth_moon_tle_system :: proc(
	JD: f64 = 2451545.0, // defaults// default to J2000 TT
	millenium: Millenium = .two_thousand,
	num_to_read: int = -1,
	start_sat: int = 0,
) -> (
	system: AstroSystem,
) {
	system = earth_moon_system(JD)
	

	return system
}
