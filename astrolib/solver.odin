package astrolib


newton_iteration :: proc(
	f: proc(x: [$N]$T) -> [$M]T,
	df: proc(x: [N]T) -> [N][N]T,
	x0: [N]T,
	tol: f64 = small9,
) -> (
	x: [N]T,
) {
    // TODO: do this later

}
