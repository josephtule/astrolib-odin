package sandbox

import ma "../astromath"
import "core:fmt"

main :: proc() {
	x := 7000
	fmt.println(ma.eps(f64(x)))
	fmt.println(ma.eps(f32(x)))
	fmt.println(ma.eps(f16(x)))
}
