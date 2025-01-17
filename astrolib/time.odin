package astrolib


import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:time/datetime"

import am "../astromath"

TimeScale :: enum {
	TT,
	TAI,
	UTC,
	UT1,
}

Date :: struct {
	year:  int,
	month: int,
	day:   int,
	hour:  f64,
}


time_converter :: proc(
	time_in: f64,
	scale_in: TimeScale,
	scale_out: TimeScale,
	units_in: am.UnitsTime = .SECOND,
	units_out: am.UnitsTime = .SECOND,
) -> (
	time_out: f64,
) {
	time_in := time_in

	// convert to correct units
	#partial switch units_in {
	case .DAY: time_in *= 86400
	case .HOUR: time_in *= 3600
	case .MINUTE: time_in *= 60
	}

	// FIXME: time scale conversion is not entirely correct 
	// convert all to TT
	switch scale_in {
	case .TT: time_out = time_in
	case .TAI: time_out = time_in + 32.184
	case .UTC: time_out = time_in + 64.184
	case .UT1:
		time_out = time_in - 0.649232
		time_out += 64.184
	}

	// convert to target time scale
	switch scale_out {
	case .TT:
	case .TAI: time_out = time_out - 32.184
	case .UTC: time_out = time_out - 64.184
	case .UT1: time_out = time_out - 64.184 + 0.649232
	}


	// convert to correct units
	#partial switch units_out {
	case .DAY: time_out /= 86400
	case .HOUR: time_out /= 3600
	case .MINUTE: time_out /= 60
	}
	return time_out
}

date_to_jd :: proc {
	date_to_jd_sep,
	date_to_jd_struct,
}

date_to_jd_struct :: proc(date: Date) -> f64 {
	return date_to_jd_sep(date.year, date.month, date.day, date.hour)
}

date_to_jd_sep :: proc(year: int, month: int, day: int, hour: f64) -> f64 {
	y: int
	m: int
	if month <= 2 {
		y = year - 1
		m = month + 12
	} else if month > 2 {
		y = year
		m = month
	} else {
		fmt.eprintfln("ERROR: incorrect format for month")
	}

	B_year := 1582
	B_month := 10
	B_day := 15

	B_conditional :=
		(year > B_year) ||
		(year == B_year && month > B_month) ||
		(year == B_year && month == B_month && day >= B_day)

	B: int
	if B_conditional {
		B = int(f64(y) / 400.) - int(f64(y) / 100.)
	} else {
		B = -2
	}

	JD :=
		math.floor(365.24 * f64(y)) +
		math.floor(30.6001 * f64(m + 1)) +
		f64(B) +
		1720996.5 +
		f64(day) +
		hour / 24.

	return JD
}


jd_to_cal :: proc(jd: f64) -> (year, month, day, hour: f64) {
	// TODO: check if this is right
	a := math.floor(jd + 0.5)
	b := math.floor((a - 1867216.25) / 36524.25)

	c: f64
	if a < 2299161. {
		c = a + 1524.
	} else if a >= 2299161. {
		c = a + b - math.floor(b / 4.) + 1525.
	}

	d := math.floor((c - 122.1) / 365.25)
	e := math.floor(365.25 * d)
	f := math.floor((c - e) / 30.6001)

	day = c - e - math.floor(30.6001 * f) + math.floor(jd + 0.5 - a)
	month = f - 1 - 12 * math.floor(f / 14.)
	year = d - 4715. - math.floor((7. + month) / 10.)
	hour = math.remainder(jd - 0.5, 1) * 24

	return year, month, day, hour
}


d_to_mjd :: proc(jd: f64) -> f64 {
	return jd - 2400000.5
}

mjd_to_jd :: proc(mjd: f64) -> f64 {
	return mjd + 2400000.5
}

dayofyear_to_monthdayhr :: proc(
	year: int,
	dayofyear: f64,
) -> (
	month, day: int,
	hour: f64,
) {
	days_in_month: [12]int = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	if is_leap_year(year) {
		days_in_month[1] = 29
	}
	month = 0
	dayofyear := dayofyear
	for int(dayofyear) > days_in_month[month] {
		dayofyear -= f64(days_in_month[month])
		month += 1
	}

	month += 1
	day = int(dayofyear)
	hour = math.remainder(dayofyear, 1) * 24 // TODO: figure out which type of day this

	return month, day, hour
}


is_leap_year :: proc(year: int) -> bool {
	if (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) {
		return true
	} else {
		return false
	}
}


meananom_to_eccenanom :: proc(
	mean_anom, ecc: f64,
	tol: f64 = am.small9,
) -> (
	eccen_anom: f64,
) {
	f := proc(eccen_anom, mean_anom, ecc: f64) -> f64 {
		return eccen_anom - ecc * math.sin(eccen_anom) - mean_anom
	}
	df := proc(eccen_anom, mean_anom, ecc: f64) -> f64 {
		return 1 - ecc * math.cos(eccen_anom)
	}
	err := 1.
	iter := 1
	eccen_anom = mean_anom // initial guess
	for err > tol && iter < am.max_iter_small {
		fprime := df(eccen_anom, mean_anom, ecc)
		if fprime == am.small16 {
			panic("ERROR: cannot solve for eccentric anomaly")
		}
		eccenanom_new := eccen_anom - f(eccen_anom, mean_anom, ecc) / fprime
		err = math.abs(eccen_anom - eccenanom_new)
		eccen_anom = eccenanom_new
	}

	return eccen_anom
}
