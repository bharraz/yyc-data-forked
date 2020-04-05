#!/usr/bin/julia

push!(LOAD_PATH, joinpath(@__DIR__, "../../lib"))

import NaCsCalc.Format: Unc, Sci
using NaCsCalc.Utils: interactive
using NaCsData
using NaCsPlot
using PyPlot
using DataStructures
using LsqFit

const inames = ["data_20200402_101532.mat"]
const datas = [NaCsData.load_striped_mat(joinpath(@__DIR__, "data", iname)) for iname in inames]
const maxcnts = [typemax(Int)]
const specs = [(593.0 .+ [-30; -7.5:1.5:7.5; 30], # 15 mW, 0.14 ms
                369.5 .+ [-10; -2.5:0.5:2.5; 10], # 6 mW, 0.48 ms
                )]

select_datas(datas, selector, maxcnts, specs) =
    [NaCsData.split_data(NaCsData.select_count(data..., selector, maxcnt), spec)
     for (data, maxcnt, spec) in zip(datas, maxcnts, specs)]

fit_data(model, x, y, p0; kws...) =
    fit_data(model, x, y, nothing, p0; kws...)

function fit_data(model, params, ratios, uncs, p0;
                  plotx=nothing, plot_lo=nothing, plot_hi=nothing, plot_scale=1.1)
    use_unc = uncs !== nothing
    if plotx === nothing
        lo = minimum(params)
        hi = maximum(params)
        span = hi - lo
        mid = (hi + lo) / 2
        if plot_lo === nothing
            plot_lo = mid - span * plot_scale / 2
            if plot_lo * lo <= 0
                plot_lo = 0
            end
        end
        if plot_hi === nothing
            plot_hi = mid + span * plot_scale / 2
            if plot_hi * hi <= 0
                plot_hi = 0
            end
        end
        plotx = linspace(plot_lo, plot_hi, 10000)
    end
    if use_unc
        fit = curve_fit(model, params, ratios, uncs.^-(2/3), p0)
    else
        fit = curve_fit(model, params, ratios, p0)
    end
    param = fit.param
    unc = estimate_errors(fit)
    return (param=param, unc=unc,
            uncs=Unc.(param, unc, Sci),
            plotx=plotx, ploty=model.(plotx, (fit.param,)))
end

function fit_survival(model, data, p0; use_unc=true, kws...)
    if use_unc
        params, ratios, uncs = NaCsData.get_values(data)
        return fit_data(model, params, ratios[:, 2], uncs[:, 2], p0; kws...)
    else
        params, ratios, uncs = NaCsData.get_values(data, 0.0)
        return fit_data(model, params, ratios[:, 2], p0; kws...)
    end
end

const datas_nacs = select_datas(datas, NaCsData.select_single((1, 2), (3, 4,)), maxcnts, specs)

const prefix = joinpath(@__DIR__, "imgs", "data_20200402_101532_raman_det_3322")

function model_lorentzian(x, p)
    p[1] .- p[2] ./ (1 .+ ((x .- p[3]) ./ (p[4] / 2)).^2)
end
function model_gaussian(x, p)
    p[1] .- p[2] ./ exp.(((x .- p[3]) ./ p[4]).^2)
end
fit15 = fit_survival(model_lorentzian, datas_nacs[1][1], [0.4, 0.3, 593, 0.02])
fit6 = fit_survival(model_lorentzian, datas_nacs[1][2], [0.4, 0.3, 369.5, 0.02])

figure(figsize=[12.6, 5.6])

subplot(1, 2, 1)
NaCsPlot.plot_survival_data(datas_nacs[1][1], fmt="C0.")
plot(fit15.plotx, fit15.ploty, "C0")
text(575, 0.39, "\$f=$(770 + fit15.uncs[3] / 1000)\\ MHz\$")
title("288560 GHz, 15 mW, 0.13 ms")
grid()
xlabel("2-Photon Detuning (770XXX kHz)")
ylabel("Two-body survival")

subplot(1, 2, 2)
NaCsPlot.plot_survival_data(datas_nacs[1][2], fmt="C0.")
plot(fit6.plotx, fit6.ploty, "C0")
text(362, 0.37, "\$f=$(770 + fit6.uncs[3] / 1000)\\ MHz\$")
title("288560 GHz, 6 mW, 0.47 ms")
grid()
xlabel("2-Photon Detuning (770XXX kHz)")
ylabel("Two-body survival")

tight_layout(pad=0.6)
NaCsPlot.maybe_save("$(prefix)")

NaCsPlot.maybe_show()
