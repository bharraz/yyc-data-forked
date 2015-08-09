#!/usr/bin/julia -f

# Measure in a (Monte Carlo) simulation

module Measure

using ..Utils
using ..Propagate
using ..System
import ..Propagate: measure_init, measure_finalize, measure_snapshot, setup_init

export WaveFuncMeasure, EnergyMeasure
export WaveFuncMonteCarloMeasure, EnergyMonteCarloMeasure

immutable WaveFuncMeasure{ST,T} <: AbstractMeasure
    ψs::SoCArray{T,3} # nele x nstates x (nstep + 1)
    WaveFuncMeasure(ψs) = new(ψs)
end

function call{Sys,T,ST}(::Type{WaveFuncMeasure{ST}}, P::SystemPropagator{Sys,T})
    nstates = System.num_states(Sys)
    WaveFuncMeasure{ST,T}(StructOfArrays(Complex{T}, P.nele, nstates,
                                         P.nstep + 1))
end

function measure_snapshot(r::WaveFuncMeasure{SnapshotX},
                          P::SystemPropagator, t_i, ψ,
                          shot_type::SnapshotType, decay)
    @inbounds if shot_type == SnapshotX
        nstates = System.num_states(Sys)
        nele = P.nele
        ψs = r.ψs
        for i in 1:nstates
            @simd for j in 1:nele
                ψs[j, i, t_i] = ψ[j, i]
            end
        end
    end
    nothing
end

function measure_snapshot(r::WaveFuncMeasure{SnapshotK},
                          P::SystemPropagator, t_i, ψ,
                          shot_type::SnapshotType, decay)
    @inbounds if accum_type == AccumK
        nstates = System.num_states(Sys)
        nele = P.nele
        ψs = r.ψs
        n_half = nele ÷ 2
        for i in 1:nstates
            @simd for j in 1:n_half
                r.ψs[j + n_half, i, t_i] = ψ[j, i]
            end
            @simd for j in (n_half + 1):nele
                r.ψs[j - (nele - n_half), i, t_i] = ψ[j, i]
            end
        end
    end
    nothing
end

immutable EnergyMeasure{T} <: AbstractMeasure
    Es::Vector{T}
    e_thresh::T
    dt::T
    pot_id::Int
    t_esc::Base.RefValue{T}
    pcount::Base.RefValue{T}
end

function call{Sys,T}(::Type{EnergyMeasure}, P::SystemPropagator{Sys,T},
                     base_state, e_thresh)
    state_id = System.get_state_id(base_state)
    pot_idxs = System.get_potential_idxs(Sys)
    pot_id = pot_ids[state_id]
    EnergyMeasure{T}(Array{T}(P.nstep + 1), e_thresh, P.dt, pot_id,
                     Ref(T(0)), Ref(T(0)))
end

function measure_init{T}(r::EnergyMeasure{T}, P::SystemPropagator)
    r.t_esc[] = 0
    r.pcount[] = 0
    nothing
end

@inline function measure_snapshot{T}(r::EnergyMeasure{T},
                                     P::SystemPropagator, t_i, ψ,
                                     shot_type::SnapshotType, decay)
    Es = r.Es
    nele = P.nele
    nstates = System.num_states(Sys)
    E_curr::T = 0
    @inbounds if shot_type == SnapshotK
        E_k = P.motion.E_k
        for i in 1:nstates
            @simd for j in 1:nele
                E_curr += abs2(ψ[j, i]) * E_k[j]
            end
        end
    else
        E_x = P.motion.E_x[r.pot_id]
        for i in 1:nstates
            @simd for j in 1:nele
                E_curr += abs2(ψ[j, i]) * E_x[j]
            end
        end
    end
    Es[t_i] += E_curr
    if r.t_esc[] == 0
        if decay != DecayNone && shot_type == SnapshotK
            # Don't double count...
            r.pcount[] += 1
        end
        if Es[t_i] > r.e_thresh
            r.t_esc[] = t_i * P.dt
        end
    end
    nothing
end

function measure_finalize(r::EnergyMeasure, P::SystemPropagator)
    if r.t_esc[] == 0
        r.t_esc[] = P.dt * (P.nstep + 1)
    end
    nothing
end

immutable WaveFuncMonteCarloMeasure{ST,T} <: MonteCarloMeasure
    ψs2::Array{T,3}
    sub_accum::WaveFuncMeasure{ST,T}
    count::Base.RefValue{Int}
    ncycle::Int
end

function call{ST,T}(::Type{WaveFuncMonteCarloMeasure},
                    sub_accum::WaveFuncMeasure{ST,T}, n)
    WaveFuncMonteCarloMeasure{Acc, T}(Array{T}(size(sub_accum.ψs)...),
                                      sub_accum, Ref(0), n)
end

function measure_init(r::WaveFuncMonteCarloMeasure, P)
    fill!(r.ψs2, 0)
    r.count[] = 0
    r.sub_accum, r.ncycle
end

function measure_snapshot(r::WaveFuncMonteCarloMeasure,
                          P::SystemPropagator, sub_accum)
    @inbounds @simd for i in eachindex(sub_accum.ψs)
        r.ψs2[i] += abs2(sub_accum.ψs[i])
    end
    r.count[] += 1
    nothing
end

function measure_finalize(r::WaveFuncMonteCarloMeasure, P)
    @inbounds for i in eachindex(r.ψs2)
        r.ψs2[i] /= r.count[]
    end
    r.count[] = 1
    nothing
end

type UncVal{T}
    v::T
    v2::T
    UncVal(v=0, v2=0) = new(v, v2)
end

sum2average!(u::UncVal, count) =
    u.v, u.v2 = sum2average(u.v, u.v2, count)

Base.fill!(u::UncVal, v) = (u.v = u.v2 = v)

function add_value!(u::UncVal, v)
    u.v += v
    u.v2 += v^2
    nothing
end

immutable EnergyMonteCarloMeasure{T} <: MonteCarloMeasure
    Es::Vector{T} # Σ(E) / average
    Es2::Vector{T} # Σ(E^2) / uncertainty
    t_esc::UncVal{T}
    pcount::UncVal{T}
    count::Base.RefValue{Int}
    sub_accum::EnergyMeasure{T}
    ncycle::Int
end

function call{T}(::Type{EnergyMonteCarloMeasure},
                 sub_accum::EnergyMeasure{T}, n)
    EnergyMonteCarloMeasure{T}(Array{T}(size(sub_accum.Es)),
                               Array{T}(size(sub_accum.Es)),
                               UncVal{T}(), UncVal{T}(), Ref(-1),
                               sub_accum, n)
end

function measure_init{T}(r::EnergyMonteCarloMeasure{T}, P)
    fill!(r.Es, 0)
    fill!(r.Es2, 0)
    fill!(r.t_esc, 0)
    fill!(r.pcount, 0)
    r.count[] = 0
    r.sub_accum, r.ncycle
end

function measure_snapshot(r::EnergyMonteCarloMeasure, P::SystemPropagator,
                          sub_accum)
    sub_Es = sub_accum.Es
    r_Es = r.Es
    r_Es2 = r.Es2
    @inbounds @simd for i in eachindex(sub_Es)
        Es = sub_Es[i]
        r_Es[i] += Es
        r_Es2[i] += Es^2
    end
    add_value!(r.t_esc, sub_accum.t_esc[])
    add_value!(r.pcount, sub_accum.pcount[])
    r.count[] += 1
    nothing
end

function measure_finalize(r::EnergyMonteCarloMeasure, P)
    @inbounds for i in eachindex(r.Es)
        r.Es[i], r.Es2[i] = sum2average(r.Es[i], r.Es2[i], r.count)
    end
    sum2average!(r.t_esc)
    sum2average!(r.pcount)
    r.count[] = -1
    nothing
end

call(::Type{MonteCarloMeasure}, sub_accum::EnergyMeasure, n) =
    EnergyMonteCarloMeasure(sub_accum, n)

call(::Type{MonteCarloMeasure}, sub_accum::WaveFuncMeasure, n) =
    WaveFuncMonteCarloMeasure(sub_accum, n)

end
