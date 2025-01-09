package sandbox

import ma "../astromath"
import "core:fmt"
import "core:time"

main :: proc() {
	x := 7000
	fmt.println(ma.eps(f64(x)))
	fmt.println(ma.eps(f32(x)))
	fmt.println(ma.eps(f16(x)))
	last_time := time.tick_now()
	deltatime: f64
	for i := 0; i < 100_000_000; i += 1 {
        deltatime = get_delta_time(time.tick_now(), &last_time)
        if i % 1000 == 0 {
            fmt.println(deltatime)
        }
	}

}

get_delta_time :: proc(current: time.Tick, last: ^time.Tick) -> (dt: f64) {
	dt = f64(current._nsec - last._nsec) * 1.0e-9
	last^ = current
	return dt
}
