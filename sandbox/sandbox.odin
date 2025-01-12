package sandbox

import ast "../astrolib"
import am "../astromath"

import "core:fmt"
import "core:time"

main :: proc() {
	// x := 7000
	// fmt.println(am.eps(f64(x)))
	// fmt.println(am.eps(f32(x)))
	// fmt.println(am.eps(f16(x)))
	// last_time := time.tick_now()
	// deltatime: f64
	// for i := 0; i < 100_000_000; i += 1 {
	// 	deltatime = get_delta_time(time.tick_now(), &last_time)
	// 	if i % 1000 == 0 {
	// 		fmt.println(deltatime)
	// 	}
	// }
	earth := ast.wgs84(.KILOMETER)
	R := am.ea_to_dcm([3]f64{5., 10., 15.}, {3, 2, 3}, .DEGREES)
	fmt.println(R)
	r, v := ast.coe_to_rv(
		3.612664283480516e+04,
		0.83285,
		87.87,
		227.89,
		53.38,
		92.335,
		earth.mu,
	)
    fmt.println(r)
}

get_delta_time :: proc(current: time.Tick, last: ^time.Tick) -> (dt: f64) {
	dt = f64(current._nsec - last._nsec) * 1.0e-9
	last^ = current
	return dt
}
