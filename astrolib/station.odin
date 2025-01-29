package astrolib

import la "core:math/linalg"
import "core:strconv"
import str "core:strings"
import rl "vendor:raylib"

g_station_id_base: int : 0
g_station_id: int = g_station_id_base


Station :: struct {
	id:           int,
	pos_body:     [3]f64, // equatorial spherical coordinates (lat, lon, h) (constant)
	pos_inertial: [3]f64,
	body_id:      int, // stations will stick to the surface of their respective bodies
}

StationInfo :: struct {
	name: string,
}

gen_station :: proc(
	pos_body: [3]f64,
	body_id: int,
	name: string = "",
	id: int = g_station_id,
) -> (
	station: Station,
) {
	info: StationInfo
	name := name
	if name == "" {
		name_str: string = "STATID"
		id_buf: [8]byte
		id_str: string = strconv.itoa(id_buf[:], id)
		name_temp, err := str.join([]string{name_str, id_str}, " ")
		name = name_temp
	}
	info.name = name

	station = Station {
		id       = id,
		pos_body = pos_body,
		body_id  = body_id,
	}

	if id == g_station_id {
		g_station_id += 1
	}

	return station
}

update_station :: #force_inline proc(
	station: ^Station,
	system: AstroSystem,
) #no_bounds_check {
	body := system.bodies[system.entity[station.body_id]]
	pos_eq := geod_to_eqfixed(station.pos_body, body, .DEGREES)
	station.pos_inertial = eq_to_inertial(pos_eq, body)
}

update_station_model :: #force_inline proc(
	model: ^Model,
	station: Station,
) #no_bounds_check {
	using model

	model.transform = scale * la.MATRIX4F32_IDENTITY
	SetTranslation(&model.transform, cast_f32(station.pos_inertial) * u_to_rl)
}

draw_station :: #force_inline proc(
	model: ^Model,
	station: Station,
) #no_bounds_check {
	update_station_model(model, station)

	rl.DrawModel(model.model, origin_f32, 1, model.tint)
}

gen_station_model :: #force_inline proc(
	station: Station,
	model_size: [3]f32,
	faces: i32 = 64,
	scale: f32 = 1,
	tint: rl.Color = rl.Color({50, 50, 50, 255}),
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
) -> (
	model: Model,
) #no_bounds_check {

	model.id = station.id
	model.type = .station

	model.draw_model = true
	model.tint = tint
	model.scale = scale
	model.model_size = model_size

	// turn off all options
	model.trail.draw = false
	model.axes.draw = false
	model.posvel.draw_pos = false
	model.posvel.draw_vel = false

	image_checker := rl.GenImageChecked(
		2,
		2,
		1,
		1,
		primary_color,
		secondary_color,
	)
	texture := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)

	// TODO: figure out how to create ellipsoid with model_size = [a,b,c]
	// a = semimajor axis, b = semiminor axis, c = secondary semiminor axis (usually b = c)
	model.model = rl.LoadModelFromMesh(
		rl.GenMeshSphere(model_size[0], faces, faces),
	)
	model.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture

	return model
}


add_station :: proc {
	add_station_ptr,
	add_station_copy,
}
add_station_ptr :: #force_inline proc(
	stations: ^[dynamic]Station,
	station: ^Station,
) {
	append_elem(stations, station^)
}
add_station_copy :: #force_inline proc(
	stations: ^[dynamic]Station,
	station: Station,
) {
	append_elem(stations, station)
}
