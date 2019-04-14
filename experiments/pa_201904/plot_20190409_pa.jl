#!/usr/bin/julia

push!(LOAD_PATH, joinpath(@__DIR__, "../../lib"))

import NaCsCalc.Format: Unc, Sci
using NaCsCalc.Utils: interactive
using NaCsData
using NaCsPlot
using PyPlot
using DataStructures
using LsqFit
using MAT

function load_data(names, selector)
    local datas
    for name in names
        param, counts = matopen(joinpath(@__DIR__, "data", "data_$name.mat")) do fd
            sg = read(fd, "ScanGroup")
            f = sg["base"]["params"]["fWavemeter"]
            c = read(fd, "SingleAtomLogical") .!= 0
            return [f for _ in 1:size(c, 3)], c
        end
        data = NaCsData.select_count(param, counts, selector)
        if !@isdefined datas
            datas = data
        else
            datas = [datas; data]
        end
    end
    return datas
end

const names_files = ["data_20190409_pa_names1.mat",
                     "data_20190409_pa_names2.mat",
                     "data_20190410_pa_names.mat"]
const datas = [load_data(matopen(fd->read(fd, "names"), joinpath(@__DIR__, "data", names_file)),
                         NaCsData.select_single((1, 2,), (3, 4,)))
               for names_file in names_files]

const datas2 = [[NaCsData.map_params((i, v)->(v ÷ 0.1) * 0.1, data);] for data in datas]

const prefix = joinpath(@__DIR__, "imgs", "data_20190409_pa")

figure()
NaCsPlot.plot_survival_data(datas[1], fmt="C0.-")
NaCsPlot.plot_survival_data(datas[2], fmt="C0.-")
NaCsPlot.plot_survival_data(datas[3], fmt="C0.-")
grid()
title("PA spectrum")
xlabel("288XXX GHz")
ylabel("Two-body survival")
NaCsPlot.maybe_save("$(prefix)")

figure()
NaCsPlot.plot_survival_data(datas2[1], fmt="C0.-")
NaCsPlot.plot_survival_data(datas2[2], fmt="C0.-")
NaCsPlot.plot_survival_data(datas2[3], fmt="C0.-")
grid()
title("PA spectrum (averaged)")
xlabel("288XXX GHz")
ylabel("Two-body survival")
NaCsPlot.maybe_save("$(prefix)_avg")

NaCsPlot.maybe_show()
