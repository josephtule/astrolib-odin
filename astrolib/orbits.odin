package astrolib

import "core:fmt"
import "core:os"


parse_tle_single :: proc(sat: ^Satellite, file: string) {
    f, err := os.open(file)
    if err != os.ERROR_NONE{
        fmt.println(f)
    }
    
    
}