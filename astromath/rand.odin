package astromath

import "core:math"
import la "core:math/linalg"
import "core:math/rand"

// rand_vec :: proc {
//     // rand_vec_size,
//     rand_vec_like,
// }

RandType :: enum {
    normal,
    uniform
}

// rand_vec_like :: proc(vec: $T/[$N]$E, generator: RandType = .uniform) -> T {
//     vec_new : T 

//     for i := 0; i < N; i += 1 {
//         vec_new[i] = gen_rand()
//     }
    
//     return vec_new
// }

// gen_rand:: proc()