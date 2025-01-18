package astrolib

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:os"
import "core:strconv"
import str "core:strings"

import am "../astromath"


Millenium :: enum (int) {
	one_thousand = 1000,
	two_thousand = 2000,
}


tle_read :: proc(file: string) -> []string {
	// open/read file
	f, err := os.open(file)
	if err != os.ERROR_NONE {
		panic("ERROR: TLE file does not exist or could not be found")
	}
	data: []byte
	ok: bool
	data, ok = os.read_entire_file(f)
	if !ok {
		panic("ERROR: TLE data could not be read")
	}
	defer os.close(f)
	// defer delete(data, context.allocator)
	it := string(data)
	lines := str.split_lines(it)
	return lines
}

tle_read_extract :: proc(
	file: string,
	cb_id: int = -1,
	system: ^AstroSystem,
	millenium: Millenium = .two_thousand,
	time_only: bool = false,
	num_to_read: int = -1, // number of satellites to read
	start_sat: int = 0, // starting satellite index in file
	gen_model: bool = true,
) -> int {
	cb: ^CelestialBody
	if cb_id == -1 {
		e := wgs84() // default to earth (km) at origin if no central body input
		cb = &e
	} else {
		cb = &system.bodies[system.id[cb_id]]
	}
	prev_len := len(system.satellites)
	num_read := 0

	lines: []string = tle_read(file)
	defer delete(lines)

	// loop through all strings
	for i := 0; i < len(lines); i += 1 {
		if (num_to_read != -1) && (num_read >= (num_to_read + start_sat)) {
			break
		}
		if len(lines[i]) == 0 {
			continue // skip blank lines
		} else if lines[i][0] == 2 {
			panic("ERROR: problem in reading TLE data")
		}
		if lines[i][0] == '0' {
			lines_temp: []string = {lines[i], lines[i + 1], lines[i + 2]}
			if num_read >= start_sat {
				extract_tle(lines_temp, cb, system, millenium, time_only, gen_model)
			}
			i = i + 2
		} else {
			lines_temp: []string = {lines[i], lines[i + 1]}
			if num_read >= start_sat {
				extract_tle(lines_temp, cb, system, millenium, time_only, gen_model)
			}
			i += 1
		}
		num_read += 1
	}
	return len(system.satellites) - prev_len
}


extract_tle :: proc(
	lines: []string,
	cb: ^CelestialBody,
	system: ^AstroSystem,
	millenium: Millenium = .two_thousand,
	time_only: bool = false,
	gen_model: bool = false,
) {
	// parse line 0
	name: string
	line0, line1, line2: string
	if len(lines) == 3 {
		line0 = lines[0]
		line1 = lines[1]
		line2 = lines[2]
		name = str.clone(line0[2:])
	} else if len(lines) == 2 {
		line1 = lines[0]
		line2 = lines[1]
		name = str.clone(line1[2:8])
	} else {
		panic(
			"ERROR: TLE file contains multiple satellites, use parse_tle_multiple instead",
		)
	}

	// parse line 1
	catalog_number := strconv.atoi(line1[2:7])
	intl_designator := str.clone(line1[9:17])
	date: Date
	date.year = int(millenium) + strconv.atoi(line1[18:20])
	date.month, date.day, date.hour = dayofyear_to_monthdayhr(
		date.year,
		strconv.atof(line1[20:32]),
	)
	if time_only {
		system.JD0 = date_to_jd(date)
		return
	}

	// parse line 2
	inc: f64 = strconv.atof(line2[9:16])
	raan: f64 = strconv.atof(line2[17:25])
	eccen_str, _ := str.replace(line2[26:33], " ", "", -1)
	ecc: f64 = strconv.atof(eccen_str) * 1.0e-7
	aop: f64 = strconv.atof(line2[34:42])
	mean_anom_str, _ := str.replace(line2[43:51], " ", "", -1)
	mean_anom: f64 = strconv.atof(mean_anom_str)
	mean_motion: f64 = strconv.atof(line2[52:63])
	eccen_anom := math.to_degrees(
		meananom_to_eccenanom(math.to_radians(mean_anom), ecc),
	)
	true_anom: f64 = math.to_degrees(
		2. *
		math.atan(
			math.sqrt((1. + ecc) / (1. - ecc)) *
			math.tan(math.to_radians(eccen_anom) / 2.),
		),
	)
	semimajor_axis: f64 = math.pow(
		cb.mu * math.pow(86400 / mean_motion / (2 * math.PI), 2),
		1. / 3.,
	)


	pos, vel := coe_to_rv(semimajor_axis, ecc, inc, raan, aop, true_anom, cb.mu)
	pos = pos + cb.pos
	vel = vel + cb.vel
	ep: [4]f64 = {0., 0., 0., 1.}
	omega: [3]f64 = {0., 0., 0.}
	// TODO: change this later
	cube_size: f32 = 500 / 1000. * am.u_to_rl
	sat, model := gen_sat_and_model(
		pos,
		vel,
		ep,
		omega,
		[3]f32{cube_size, cube_size, cube_size}, // default to cube
	)
	sat.name = name
	sat.info.name = name
	sat.info.intl_designator = intl_designator
	sat.info.tle_index = catalog_number

	// propagate to target time
	JD := date_to_jd(date)
	if JD != system.JD0 {
		// if time does not align, propagate
		// TODO: finish this part
	}

	// copy satellite into system
	add_to_system(system, sat)
	add_to_system(system, model)
}
