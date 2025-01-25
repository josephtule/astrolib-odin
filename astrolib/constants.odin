package astrolib

rl_to_u :: 1000.
u_to_rl :: 1. / rl_to_u

// speed of light
light_speed_m :: 299792458.
light_speed_km :: 29979.2458

// gravitational constant
G_m :: 6.6743e-11
G_km :: 6.6743e-20

// tolarances
small6 :: 1.0e-6
small9 :: 1.0e-9
small12 :: 1.0e-12
small14 :: 1.0e-14
small16 :: 1.0e-16


// max iterations
max_iter_vsmall :: 1000
max_iter_small :: 10000
max_iter_medium :: 100000
max_iter_large :: 1000000

max_iter_1000 :: max_iter_vsmall
max_iter_10000 :: max_iter_small
max_iter_100000 :: max_iter_medium
max_iter_1000000 :: max_iter_large
