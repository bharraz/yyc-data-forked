#!/usr/bin/julia -f

using ODE
using PyPlot

function vector_hcat{T}(V::Vector{Vector{T}})
    height = length(V[1])
    T[V[j][i] for j in 1:length(V), i in 1:height]
end

# Array only for now
function solve_ode(t0, y0, f, t1, h)
    if t1 <= t0
        error("End time should be after start time.")
    end
    ts = t0:h:t1
    nele = length(y0)
    nstep = length(ts)
    ys = Array{eltype(y0), 2}(nele, nstep)
    ys[:, 1] = y0
    h2 = h / 2
    h3 = h / 3
    h6 = h / 6
    k1 = similar(y0)
    k2 = similar(y0)
    k3 = similar(y0)
    k4 = similar(y0)
    tmp = similar(y0)
    for i in 2:nstep
        t = ts[i]
        prev = sub(ys, (:, i - 1))
        f(t, prev, k1)
        @inbounds for j in 1:nele
            tmp[j] = ys[j, i - 1] + h2 * k1[j]
        end
        f(t + h2, tmp, k2)
        @inbounds for j in 1:nele
            tmp[j] = ys[j, i - 1] + h2 * k2[j]
        end
        f(t + h2, tmp, k3)
        @inbounds for j in 1:nele
            tmp[j] = ys[j, i - 1] + h * k3[j]
        end
        f(t + h, tmp, k4)
        @inbounds for j in 1:nele
            ys[j, i] = ys[j, i - 1] + (h6 * k1[j] + h3 * k2[j] +
                                       h3 * k3[j] + h6 * k4[j])
        end
    end
    collect(ts), ys
end

abstract ODEKernel

function call(k::ODEKernel, t, y)
    ydot = similar(y)
    k(t, y, ydot)
    ydot
end

immutable ExtendedArray{Ary} <: AbstractArray
    ary::Ary
end

getindex{Ary}(ary::ExtendedArray{Ary}, i) = if i <= 0 || i > length(ary.ary)
    return eltype(Ary)(0)
else
    @inbounds return ary.ary[i]
end

function diff2(ary, i)
    len = length(ary)
    # @assert len >= 10 # Too lazy to support len < 9
    @inbounds if 5 <= i <= len - 4
        # 8th order
        return (-1 / 560 * (ary[i - 4] + ary[i + 4])
                + 8 / 315 * (ary[i - 3] + ary[i + 3])
                - 1 / 5 * (ary[i - 2] + ary[i + 2])
                + 8 / 5 * (ary[i - 1] + ary[i + 1])
                - 205 / 72 * ary[i])
    elseif i == 4 || i == len - 3
        # 6th order
        return (1 / 90 * (ary[i - 3] + ary[i + 3])
                - 3 / 20 * (ary[i - 2] + ary[i + 2])
                + 3 / 2 * (ary[i - 1] + ary[i + 1])
                - 49 / 18 * ary[i])
    elseif i == 3 || i == len - 2
        # 4th order
        return (-1 / 12 * (ary[i - 2] + ary[i + 2])
                + 4 / 3 * (ary[i - 1] + ary[i + 1])
                - 5 / 2 * ary[i])
    elseif i == 2 || i == len - 1
        # 2th order
        return ary[i - 1] + ary[i + 1] - 2 * ary[i]
    else
        return 0.0 * ary[i]
    # elseif i < 4
    #     # 6th order single side
    #     return (469 / 90 * ary[i] - 223 / 10 * ary[i + 1]
    #             + 879 / 20 * ary[i + 2] - 949 / 18 * ary[i + 3]
    #             + 41 * ary[i + 4] - 201 / 10 * ary[i + 5]
    #             + 1019 / 180 * ary[i + 6] - 7 / 10 * ary[i + 7])
    # else
    #     # 6th order single side
    #     return (469 / 90 * ary[i] - 223 / 10 * ary[i - 1]
    #             + 879 / 20 * ary[i - 2] - 949 / 18 * ary[i - 3]
    #             + 41 * ary[i - 4] - 201 / 10 * ary[i - 5]
    #             + 1019 / 180 * ary[i - 6] - 7 / 10 * ary[i - 7])
    end
end

println("Import done.")
