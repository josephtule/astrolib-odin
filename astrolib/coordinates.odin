package astrolib

import "core:math"
import la "core:math/linalg"

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
	if units == .DEGREES {
		az *= deg_to_rad
		zen *= deg_to_rad
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
	if units == .DEGREES {
		az *= deg_to_rad
		el *= deg_to_rad
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
	if units == .DEGREES {
		az *= rad_to_deg
		zen *= rad_to_deg
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

	if units == .DEGREES {
		az *= deg_to_rad
		el *= deg_to_rad
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

	if units == .DEGREES {
		ra *= rad_to_deg
		dec *= rad_to_deg
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
	if units == .DEGREES {
		ra *= deg_to_rad
		dec *= deg_to_rad
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
	if units == .DEGREES {
		lat *= deg_to_rad
		lon *= deg_to_rad
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
	if units == .DEGREES {
		lat *= deg_to_rad
		lon *= deg_to_rad
	}

	r = radec_to_cart([3]T{lon, lat, r_mag}, units = units)

	return r
}


eqfixed_to_geod :: #force_inline proc "contextless" (
	r: [3]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	latlonh: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {


	return latlonh
}
eqfixed_to_geoc :: #force_inline proc "contextless" (
	r: [3]$T,
) -> (
	latlonr: [3]T,
) where intrinsics.type_is_float(T) #no_bounds_check {


	return latlonr
}
