package sandbox

import ast "../astrolib"
import am "../astromath"
import ode "../ode"

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


	p1 := ode.Params_Gravity_Pointmass {
		mu = 1.4332,
	}
	p2 := ode.Params_Gravity_Zonal {
		mu         = 3.4321432,
		R_cb       = 201,
		max_degree = 2,
		J          = {0., 0., 0., 0., 0., 0., 0.},
	}
	fmt.println(p1)
	fmt.println(cast(^ode.Params_Gravity_Pointmass)&p2)
}

get_delta_time :: proc(current: time.Tick, last: ^time.Tick) -> (dt: f64) {
	dt = f64(current._nsec - last._nsec) * 1.0e-9
	last^ = current
	return dt
}
