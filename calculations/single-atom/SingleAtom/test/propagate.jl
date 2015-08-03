#!/usr/bin/julia -f

module TestPropagate

using Base.Test
using SingleAtom
using SingleAtom.System
using SingleAtom.Optical
using SingleAtom.Propagate

let
    builder = SystemBuilder{Float32}()
    add_state!(builder, :(G, 0, 0), 0)
    add_state!(builder, :(E, 1, -1), -1)
    add_state!(builder, :(E, 1, 0), 0)
    add_state!(builder, :(E, 1, 1), 1)

    add_transition!(builder, :(G, 0, 0), :(E, 1, -1),
                    Transition{Trans_σ⁻}(0.5f0, 10f0, 1f0))
    add_transition!(builder, :(G, 0, 0), :(E, 1, 0),
                    Transition{Trans_π}(0.5f0, 10f0, 1f0))
    add_transition!(builder, :(G, 0, 0), :(E, 1, 1),
                    Transition{Trans_σ⁺}(0.5f0, 10f0, 1f0))

    add_potential!(builder, HarmonicPotential{Float32}(2π * 2))
    add_potential!(builder, HarmonicPotential{Float32}(2π * 1), :(E, 1, 1))

    # Deterministic phase tracker
    add_drive!(builder, Drive{Vec3D{Complex64}(1, 2, 3im)}(0.5, 1, 0, Inf))

    atom = MotionSystem(Vec3D(1f0, 0f0, 0f0), 10, builder)

    motion_cache = Propagate.HMotionCache(atom, 1f-1, 1f-1, 8)
    optical_cache = Propagate.OpticalCache(atom, 1f-1, 1f-1, 8)
end

end
