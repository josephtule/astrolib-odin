package sandbox

test :: proc() {
    a:f32= 1;
    b:= double(a)
}

double :: proc(a: f64) -> f64 {
	return a + a
}
