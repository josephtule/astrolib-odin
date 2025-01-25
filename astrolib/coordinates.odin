package astrolib

import "core:math"
// import la "core:math/linalg"

azzen_to_cart :: #force_inline proc "contextless" (
	azzen: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	r: [3]T,
) #no_bounds_check {
	// spherical coordinates in the form of (range (rho), azimuth (theta), zenith (phi))
	az := azzen.x
	zen := azzen.y
	rho := azzen.z
	if units != .RADIANS {
		az = convert_angle(az, units, .RADIANS)
		zen = convert_angle(zen, units, .RADIANS)
	}

	r.x = math.sin(zen) * math.cos(az)
	r.y = math.sin(zen) * math.sin(az)
	r.z = math.cos(zen)
	r *= rho
	return r
}

azel_to_cart :: #force_inline proc "contextless" (
	azel: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	r: [3]T,
) #no_bounds_check {
	// spherical coordinates in the form of (range (rho), azimuth (theta), elevation (phi))
	// angle units in radians
	az := azel.x
	el := azel.y
	rho := azel.z
	if units != .RADIANS {
		az = convert_angle(az, units, .RADIANS)
		el = convert_angle(el, units, .RADIANS)
	}

	r.x = math.cos(el) * math.cos(az)
	r.y = math.cos(el) * math.sin(az)
	r.z = math.sin(el)
	r *= rho
	return
}

cart_to_azzen :: #force_inline proc "contextless" (
	r: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	azzen: [3]T,
) #no_bounds_check {
	// zen coordinate measured from the z-axis
	rho := mag(r)
	az := math.atan2(r[1], r[0])
	zen := math.acos(r[2] / rho)
	if units != .RADIANS {
		az = convert_angle(az, .RADIANS, units)
		zen = convert_angle(zen, .RADIANS, units)
	}

	azzen = {az, zen, rho}

	return azzen
}

cart_to_azel :: #force_inline proc "contextless" (
	r: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	azel: [3]T,
) #no_bounds_check {
	// el coordinate measured from the x-y plane
	rho := mag(r)
	az := math.atan2(r[1], r[0])
	el := math.asin(r[2] / rho)

	if units != .RADIANS {
		az = convert_angle(az, .RADIANS, units)
		el = convert_angle(el, .RADIANS, units)
	}

	azel = {az, el, rho}

	return azel
}

cart_to_radec :: #force_inline proc "contextless" (
	r: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	radec: [3]T,
) #no_bounds_check {
	r_mag := mag(r)
	ra := math.atan2(r[1], r[0])
	dec := math.atan2(r[2], math.sqrt(r[0] * r[0] + r[1] * r[1]))

	if units != .RADIANS {
		ra = convert_angle(ra, .RADIANS, units)
		dec = convert_angle(dec, .RADIANS, units)
	}
	radec = {ra, dec, r_mag}

	return radec
}

radec_to_cart :: #force_inline proc "contextless" (
	radec: [3]$T, // radec = {right ascension, declination, radius}
	units: UnitsAngle = .DEGREES,
) -> (
	r: [3]T,
) where intrinsics.type_is_float(t) {
	ra := radec[0]
	dec := radec[1]
	r_mag := radec[2]

	if units != .RADIANS {
		ra = convert_angle(ra, units, .RADIANS)
		dec = convert_angle(dec, units, .RADIANS)
	}

	cra := math.cos(ra)
	sra := math.sin(ra)
	cdec := math.cos(dec)
	sdec := math.sin(dec)

	r.x = r_mag * cra * cdec
	r.y = r_mag * sra * cdec
	r.z = r_mag * sdec

	return r
}

geod_to_eqfixed :: #force_inline proc "contextless" (
	latlonh: [3]$T,
	cb: CelestialBody,
	units: UnitsAngle,
) -> (
	r: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {
	// will inherit the units of input height
	lat := latlonh.x
	lon := latlonh.y
	h := latlonh.z

	if units != .RADIANS {
		lat = convert_angle(lat, units, .RADIANS)
		lon = convert_angle(lon, units, .RADIANS)
	}

	f := cb.flattening
	e2 := 2 * f - f * f
	a := cb.semimajor_axis

	slat = math.sin(lat)
	clat = math.cos(lat)

	N = a / math.sqrt(1. - e2 * slat * slat)

	r.x = (N + h) * clat * math.cos(lon)
	r.y = (N + h) * clat * math.sin(lon)
	r.z = (N * (1 - e2) + h) * slat

	return r
}

geoc_to_eqfixed :: #force_inline proc "contextless" (
	latlonr: [3]$T, // geocentric = {geocentric lat, longitude, radius}
	cb: CelestialBody,
	units: UnitsAngle,
) -> (
	r: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {
	lat := latlonr.x
	lon := latlonr.y
	r_mag := latlonr.z

	if units != .RADIANS {
		lat = convert_angle(lat, units, .RADIANS)
		lon = convert_angle(lat, units, .RADIANS)
	}

	r = radec_to_cart([3]T{lon, lat, r_mag}, units = units)

	return r
}

// TODO: finish these two
eqfixed_to_geod :: #force_inline proc "contextless" (
	r: [3]$T,
	cb: CelestialBody,
	units: UnitsAngle = .DEGREES,
) -> (
	latlonh: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {
	r_mag := mag(r)
	r_tilde_mag2 := r.x * r.x + r.y * r.y
	r_tilde_mag := math.sqrt(r_tilde_mag2)

	z2 := z * z

	a := cb.semimajor_axis
	b := a * (1. - cb.flattening)
	a2 := a * a
	b2 := b * b

	e2 := (a2 - b2) / a2
	ep2 := (a2 - b2) / b2
	F := 54. * b2 * z2
	G := r_tilde_mag2 + (1. - e2) * z2 - e2 * (a2 - b2)
	c := e2 * e2 * F * r_tilde_mag2 / (G * G * G)
	s := math.pow(1 + c + math.sqrt(c * c + 2 * c), 1. / 3.)
	P := F / (3. * (s + (1. / s) + 1.) * (s + (1. / s) + 1) * G * G)
	Q := math.sqrt(1. + 2. * e2 * e2 * P)
	r0 :=
		-P * e2 * r_tilde_mag / (1. / +Q) +
		math.sqrt(
			a2 / 2. * (1. + 1. / Q) -
			P * (1. - e2) * z2 / (Q * (1. + Q)) -
			P * r_tilde_mag2 / 2.,
		)
	U := math.sqrt(math.pow(r_tilde - e2 * r0, 2) + z2)
	V := math.sqrt(math.pow(r_tilde - e2 * r0, 2) + (1. - e2) * z2)
	z0 := b2 * z / (a * V)

	h = U * (1. - b2 / (a * V))
	lat = math.atan2((r.z + ep2 * z0), r_tilde)
	lon = math.atan2(r.y, r.x)
    
    if units != .DEGREES {
        lat = convert_angle(lat, .RADIANS, units)
        lon = convert_angle(lon, .RADIANS, units)
    }
    latlonh = {lat, lon, h}

	return latlonh
}
eqfixed_to_geoc :: #force_inline proc "contextless" (
	r: [3]$T,
) -> (
	latlonr: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {


	return latlonr
}
