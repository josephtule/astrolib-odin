---
header_includes: -\newcommand{\vecb}[1]{\boldsymbol{#1}}
---

# astrolib-odin

## Library for orbital mechanics and attitude dynamics for spacecraft

## Example

<img src="assets/orbit_example.gif" width="512">
<img src="assets/attitude_example.gif" width="512">

## Controls (subject to change)

- Start Simulation: space
- Reset Simulation: shift+r
- Toggle Attitude Dynamics: i
- Camera Switching (satellite target, body target, origin): c
- Cycle Camera Target: n/shift+n
- Camera Lock: shift+c
- Cycle Target: n/shift+n
- Zoom into target: Mousewheel up/down
- Camera Azimuth/Elevation: w/a/s/d
- Reset Time Scale/Substeps: r
- Increment Substeps (physics iterations per frame): up/down
- Increment Time Scale (delta time scaling): left/right
- Toggle Trails: t
- Adjust trail length: [ or ]
- Toggle Wireframes: tbd
- Toggle Axes: o
- Toggle Position Vectors: p
- Spawn Satellite: . (period)
- Print FPS to Console: f
- Print Simulation Delta Time to Console: g

## Math and Equations of Motion

### Translational

$$
\boldsymbol a_i = \sum_j \frac{G m_i m_j}{||\boldsymbol r||_2^3} \boldsymbol r
$$

### Rotational

#### Kinematics

$$
\dot{\boldsymbol{q}} = \frac{1}{2}  \boldsymbol{\Omega}  \boldsymbol{q}
$$

where

$$
\boldsymbol{\Omega} =
\begin{bmatrix}
0 & -\omega_x & -\omega_y & -\omega_z \\
\omega_x & 0 & \omega_z & -\omega_y \\
\omega_y & -\omega_z & 0 & \omega_x \\
\omega_z & \omega_y & -\omega_x & 0
\end{bmatrix}
$$

#### Dynamics

$$
\dot{\boldsymbol{\omega}} = \boldsymbol{I}^{-1} \left( \boldsymbol{\tau} - \boldsymbol{\omega} \times (\boldsymbol{I} \boldsymbol{\omega}) \right)
$$

### Integration

#### Ralston Integrator

#### Runge-Kutta 4th Order

$$
\begin{aligned}
    k_1 &= f\left(t,x \right) \\
    k_2 &= f\left(t+\frac{\Delta t}{2},x + \frac{\Delta t}{2} k_1 \right) \\
    k_3 &= f\left(t+\frac{\Delta t}{2},x + \frac{\Delta t}{2} k_2 \right) \\
    k_4 &= f\left(t+ \Delta t, x + \Delta t k_3 \right) \\
    t^+ &= t + \Delta t \\
    x^+ &= x + \frac{\Delta t}{6} \left(k_1 + 2 k_2 + 2 k_3 + k_4 \right)
\end{aligned}
$$

## How to Build

1. Install [Odin-lang](https://odin-lang.org/docs/install/)
2. Copy myrlgl.odin into `<path_to_odin>/vendor/raylib/rlgl`
3. Download [clay](https://github.com/nicbarker/clay)
4. Create an `external` directory
5. Copy clay-odin bindings into external or
6. Simlink into external with `ln -s  <path_to_clay_odin> <path_to_external>`
7. Create a `build` directory in the project root
8. Build and run with
9. Mac/Linux: `<path_to_odin_binary> run . -out:build/out -o:speed`
10. Windows: `<path_to_odin_binary> run . -out:build/out.exe -o:speed`

## Sources

TLE Data: [celestrak](https://celestrak.org/NORAD/elements/) or [space-track](https://www.space-track.org/auth/login)
Algorithms: Vallado
