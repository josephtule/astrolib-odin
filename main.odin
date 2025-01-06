package main

import "base:intrinsics"
import "core:fmt"

import "core:math"
import la "core:math/linalg"

import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import ode "ODE"
import ma "astromath"

main :: proc() {
	dt := 0.1
	x0 := [2]f64{0., 0.}
	N := 100
	x: [dynamic][2]f64
	t: [dynamic]f64


	xk := x0
	tk := 0.


	params := ode.Params_MSD {
		m = 2.5,
		c = 0.8,
		k = 10.,
	}

	append(&x, xk)
	append(&t, tk)
	for i := 0; i < N; i += 1 {
		tk, xk = ode.rk4_step(ode.mass_spring_damper_ode, tk, xk, dt, &params)
		append(&x, xk)
		append(&t, tk)
	}

	fmt.println(x)


	r: [3]f64
	ma.set_vector_slice_3(
		&r,
		[1]f64{0.1},
		[6]f64{0.2, .3, .4, .5, .6, .7},
		[1]f64{0.67},
		l2 = 1,
	)
	v: [3]f64
	ma.set_vector_slice_2(&v, [2]f64{0.1, 0.2}, [1]f64{0.1})

	fmt.println("vector slice test")
	fmt.println(r, v)
}
