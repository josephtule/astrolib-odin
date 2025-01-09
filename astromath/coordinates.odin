package astromath

import "core:math"
import la "core:math/linalg"

azzen_to_cart :: proc(azzen: [3]$T) -> (r: [3]T) {
	// spherical coordinates in the form of (range (rho), azimuth (theta), zenith (phi))
	rho := azzen.x
	theta := azzen.y
	phi := azzen.z

	r.x = math.sin(phi) * math.cos(theta)
	r.y = math.sin(phi) * math.sin(theta)
	r.z = math.cos(phi)
	r *= rho
	return r
}

azel_to_cart :: proc(azel: [3]$T) -> (r: [3]T) {
	// spherical coordinates in the form of (range (rho), azimuth (theta), elevation (phi))
	// angle units in radians
	rho := azel.x
	theta := azel.y
	phi := azel.z

	r.x = math.cos(phi) * math.cos(theta)
	r.y = math.cos(phi) * math.sin(theta)
	r.z = math.sin(phi)
	r *= rho
	return
}

cart_to_azzen :: proc(r: [3]$T) -> (azzen: [3]T) {
	// last coordinate measured from the z-axis
	azzen.x = la.vector_length(r)
	azzen.y = math.atan2(r[1], r[0])
	azzen.z = math.acos(r[2] / azzen.x)
	return
}

cart_to_azel :: proc(r: [3]$T) -> (azel: [3]T) {
	// last coordinate measured from the x-y plane
	azel.x = la.vector_length(r)
	azel.y = math.atan2(r[1], r[0])
	azel.z = math.asin(r[2] / azel.x)
	return azel
}
