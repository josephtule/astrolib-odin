package sandbox

import "core:fmt"
import "core:math"
import la "core:math/linalg"

import ast "../astrolib"
import am "../astromath"

main :: proc() {
	a, e, i, raan, aop, ta := ast.rv_to_coe(
		[3]f64{32, 432, 123},
		[3]f64{532, 1234, 5321},
		3243,
	)
	fmt.println(a, e, i, raan, aop, ta)
}
