#!/usr/bin/julia

push!(LOAD_PATH, joinpath(@__DIR__, "../../lib"))

using NaCsCalc.Utils: interactive
using NaCsData
using NaCsPlot
using PyPlot
using DataStructures
using LsqFit
import NaCsCalc.Format: Unc, Sci

const iname_a = joinpath(@__DIR__, "data", "data_20171228_172950.mat")
const params_a, logicals_a = NaCsData.load_striped_mat(iname_a)

function gen_selector(site)
    function selector(logicals)
        @assert size(logicals, 2) >= site
        if logicals[1, site] == 0
            return Int[1, 0, 0]
        end
        return Int[1, 1, logicals[2, site]]
    end
end

data_50 = NaCsData.select_count(params_a, logicals_a, gen_selector(1))
data_62 = NaCsData.select_count(params_a, logicals_a, gen_selector(2))

data_50_mf3 = data_50[1:2:end]
data_50_mf4 = data_50[2:2:end]
data_62_mf3 = data_62[1:2:end]
data_62_mf4 = data_62[2:2:end]

const spec = ((linspace(-50, 100, 16) for _ in 1:13)...)

const split_50_mf3 = NaCsData.split_data(NaCsData.map_params((i, v)->i, data_50_mf3), spec)
const split_50_mf4 = NaCsData.split_data(NaCsData.map_params((i, v)->i, data_50_mf4), spec)
const split_62_mf3 = NaCsData.split_data(NaCsData.map_params((i, v)->i, data_62_mf3), spec)
const split_62_mf4 = NaCsData.split_data(NaCsData.map_params((i, v)->i, data_62_mf4), spec)

const prefix = joinpath(@__DIR__, "imgs", "data_20171228")

function rabiLine(det, t, Omega)
    Omega2 = Omega^2
    OmegaG2 = det^2 + Omega2
    return Omega2 / OmegaG2 * sin(√(OmegaG2) * t / 2)^2
end

function gen_model3(t)
    return (x, p) -> p[1] .* (1 .- p[2] .* rabiLine.(2π .* (x .- p[3]), t, p[4]))
end
function gen_model4(t)
    return (x, p) -> p[1] .* rabiLine.(2π .* (x .- p[2]), t, p[3])
end

const plotx = linspace(-60, 110, 10000)

function fit(model, data, p0, plotx; use_unc=false)
    params, ratios, uncs = NaCsData.get_values(data)
    if use_unc
        fit = curve_fit(model, params, ratios[:, 2], 1 ./ uncs[:, 2], p0)
    else
        fit = curve_fit(model, params, ratios[:, 2], p0)
    end
    return fit.param, estimate_errors(fit), model.(plotx, (fit.param,))
end

const res_50_mf3 = Float64[]
const res_50_mf3_unc = Float64[]
const res_50_mf4 = Float64[]
const res_50_mf4_unc = Float64[]
const res_62_mf3 = Float64[]
const res_62_mf3_unc = Float64[]
const res_62_mf4 = Float64[]
const res_62_mf4_unc = Float64[]

const n_trap_depths = 12

figure()
for i in 1:n_trap_depths
    yoffset = 0.16 * (i - 1) - 0.15
    fit_res = fit(gen_model3(15e-3), split_50_mf3[i], [0.8, 0.8, 30, 20], plotx)
    p = plot(plotx, fit_res[3] .+ yoffset)
    NaCsPlot.plot_survival_data(split_50_mf3[i], yoffset=yoffset,
                                color=p[1][:get_color](), fmt="o")
    push!(res_50_mf3, fit_res[1][end - 1])
    push!(res_50_mf3_unc, fit_res[2][end - 1])
end
title("\$50MHz\\  5mW\\  m_F=3\$")
xlabel("Detuning (kHz)")
ylabel("Survival (shifted)")
grid()
ylim([0, 2.7])
NaCsPlot.maybe_save("$(prefix)_50_mf3")

figure()
for i in 1:n_trap_depths
    yoffset = 0.16 * (i - 1)
    fit_res = fit(gen_model4(15e-3), split_50_mf4[i], [0.8, 30, 20], plotx)
    p = plot(plotx, fit_res[3] .+ yoffset)
    NaCsPlot.plot_survival_data(split_50_mf4[i], yoffset=yoffset,
                                color=p[1][:get_color](), fmt="o")
    push!(res_50_mf4, fit_res[1][end - 1])
    push!(res_50_mf4_unc, fit_res[2][end - 1])
end
title("\$50MHz\\  5mW\\  m_F=4\$")
xlabel("Detuning (kHz)")
ylabel("Survival (shifted)")
grid()
ylim([0, 2.9])
NaCsPlot.maybe_save("$(prefix)_50_mf4")

figure()
for i in 1:n_trap_depths
    yoffset = 0.16 * (i - 1) - 0.15
    fit_res = fit(gen_model3(15e-3), split_62_mf3[i], [0.8, 0.8, 30, 20], plotx)
    p = plot(plotx, fit_res[3] .+ yoffset)
    NaCsPlot.plot_survival_data(split_62_mf3[i], yoffset=yoffset,
                                color=p[1][:get_color](), fmt="o")
    push!(res_62_mf3, fit_res[1][end - 1])
    push!(res_62_mf3_unc, fit_res[2][end - 1])
end
title("\$62MHz\\  5mW\\  m_F=3\$")
xlabel("Detuning (kHz)")
ylabel("Survival (shifted)")
grid()
ylim([0, 2.7])
NaCsPlot.maybe_save("$(prefix)_62_mf3")

figure()
for i in 1:n_trap_depths
    yoffset = 0.16 * (i - 1)
    fit_res = fit(gen_model4(15e-3), split_62_mf4[i], [0.8, 30, 20], plotx)
    p = plot(plotx, fit_res[3] .+ yoffset)
    NaCsPlot.plot_survival_data(split_62_mf4[i], yoffset=yoffset,
                                color=p[1][:get_color](), fmt="o")
    push!(res_62_mf4, fit_res[1][end - 1])
    push!(res_62_mf4_unc, fit_res[2][end - 1])
end
title("\$62MHz\\  5mW\\  m_F=4\$")
xlabel("Detuning (kHz)")
ylabel("Survival (shifted)")
grid()
ylim([0, 2.9])
NaCsPlot.maybe_save("$(prefix)_62_mf4")

# leave out the last point
const TrapDepths = (3.5:1:15.5)[1:n_trap_depths]

trapdepths_plot = linspace(TrapDepths[1] - 0.5, TrapDepths[end] + 0.5, 10000)

trap_model(x::Number, p) = @evalpoly x p[1] p[2]
trap_model(x, p) = trap_model.(x, (p,))

trap_50_mf3_fit = curve_fit(trap_model, TrapDepths, res_50_mf3, 1 ./ res_50_mf3_unc,
                            [29.0, -1.7])
trap_50_mf4_fit = curve_fit(trap_model, TrapDepths, res_50_mf4, 1 ./ res_50_mf4_unc,
                            [29.0, -1.7])
trap_62_mf3_fit = curve_fit(trap_model, TrapDepths, res_62_mf3, 1 ./ res_62_mf3_unc,
                            [29.0, -1.7])
trap_62_mf4_fit = curve_fit(trap_model, TrapDepths, res_62_mf4, 1 ./ res_62_mf4_unc,
                            [29.0, -1.7])

# trap_model(x::Number, p) = @evalpoly x p[1] p[2] p[3]
# trap_model(x, p) = trap_model.(x, (p,))

# trap_50_mf3_fit = curve_fit(trap_model, TrapDepths, res_50_mf3, 1 ./ res_50_mf3_unc,
#                             [29.0, -1.7, -0.1])
# trap_50_mf4_fit = curve_fit(trap_model, TrapDepths, res_50_mf4, 1 ./ res_50_mf4_unc,
#                             [29.0, -1.7, -0.1])
# trap_62_mf3_fit = curve_fit(trap_model, TrapDepths, res_62_mf3, 1 ./ res_62_mf3_unc,
#                             [29.0, -1.7, -0.1])
# trap_62_mf4_fit = curve_fit(trap_model, TrapDepths, res_62_mf4, 1 ./ res_62_mf4_unc,
#                             [29.0, -1.7, -0.1])

@show Unc.(trap_50_mf3_fit.param, estimate_errors(trap_50_mf3_fit))
@show Unc.(trap_50_mf4_fit.param, estimate_errors(trap_50_mf4_fit))
@show Unc.(trap_62_mf3_fit.param, estimate_errors(trap_62_mf3_fit))
@show Unc.(trap_62_mf4_fit.param, estimate_errors(trap_62_mf4_fit))

figure()
p = errorbar(TrapDepths, res_50_mf3, res_50_mf3_unc, label="\$50MHz\\ m_F=3\$", fmt="o")
plot(trapdepths_plot, trap_model.(trapdepths_plot, (trap_50_mf3_fit.param,)),
     color=p[1][:get_color]())
p = errorbar(TrapDepths, res_50_mf4, res_50_mf4_unc, label="\$50MHz\\ m_F=4\$", fmt="o")
plot(trapdepths_plot, trap_model.(trapdepths_plot, (trap_50_mf4_fit.param,)),
     color=p[1][:get_color]())
p = errorbar(TrapDepths, res_62_mf3, res_62_mf3_unc, label="\$62MHz\\ m_F=3\$", fmt="o")
plot(trapdepths_plot, trap_model.(trapdepths_plot, (trap_62_mf3_fit.param,)),
     color=p[1][:get_color]())
p = errorbar(TrapDepths, res_62_mf4, res_62_mf4_unc, label="\$62MHz\\ m_F=4\$", fmt="o")
plot(trapdepths_plot, trap_model.(trapdepths_plot, (trap_62_mf4_fit.param,)),
     color=p[1][:get_color]())
title("Resonance")
xlabel("Trap depth (mW)")
ylabel("Frequency (kHz)")
legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.0)
grid()
NaCsPlot.maybe_save("$(prefix)_resonance")

NaCsPlot.maybe_show()
