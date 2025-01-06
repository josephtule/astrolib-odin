package astromath

set_vector_slice :: proc {
	set_vector_slice_1,
	set_vector_slice_2,
	set_vector_slice_3,
	set_vector_slice_4,
}

set_vector_slice_1 :: proc(
	vout: ^[$N]$T,
	v1: [$M]T,
	#any_int offset: int = 0,
	#any_int l1: int = 0,
) {
	l1 := l1
	assert(N >= l1 + offset) // Ensure vout has enough space for vin
	if l1 == 0 {l1 = len(v1)}
	for i := 0; i < l1; i += 1 {
		vout[i + offset] = v1[i]
	}
}

set_vector_slice_2 :: proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	#any_int offset: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
) {
	l1 := l1
	l2 := l2
	assert(N >= l1 + l2 + offset)
	if l1 == 0 {l1 = len(v1)}
	if l2 == 0 {l2 = len(v2)}
	for i := 0; i < l1; i += 1 {
		vout[i + offset] = v1[i]
	}
	for i := 0; i < l2; i += 1 {
		vout[i + offset + l1] = v2[i]
	}
}

set_vector_slice_3 :: proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	v3: [$M3]T,
	#any_int offset: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
	#any_int l3: int = 0,
) {
	l1 := l1
	l2 := l2
	l3 := l3

	assert(N >= l1 + l2 + l3 + offset)
	if l1 == 0 {l1 = len(v1)}
	if l2 == 0 {l2 = len(v2)}
	if l3 == 0 {l3 = len(v3)}
	for i := 0; i < l1; i += 1 {
		vout[i + offset] = v1[i]
	}
	for i := 0; i < l2; i += 1 {
		vout[i + offset + l1] = v2[i]
	}
	for i := 0; i < l3; i += 1 {
		vout[i + offset + l1 + l2] = v3[i]
	}
}

set_vector_slice_4 :: proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	v3: [$M3]T,
	v4: [$M4]T,
	#any_int offset: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
	#any_int l3: int = 0,
	#any_int l4: int = 0,
) {
	l1 := l1
	l2 := l2
	l3 := l3
	l4 := l4
	assert(N >= l1 + l2 + l3 + l4 + offset)
	if l1 == 0 {l1 = len(v1)}
	if l2 == 0 {l2 = len(v2)}
	if l3 == 0 {l3 = len(v3)}
	if l4 == 0 {l4 = len(v4)}
	for i := 0; i < l1; i += 1 {
		vout[i + offset] = v1[i]
	}
	for i := 0; i < l2; i += 1 {
		vout[i + offset + l1] = v2[i]
	}
	for i := 0; i < l3; i += 1 {
		vout[i + offset + l1 + l2] = v3[i]
	}
	for i := 0; i < l4; i += 1 {
		vout[i + offset + l1 + l2 + M3] = v4[i]
	}
}
