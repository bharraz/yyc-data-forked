#!/usr/bin/julia

push!(LOAD_PATH, joinpath(@__DIR__, "../../lib"))

using NaCsData
using PyPlot
matplotlib["rcParams"][:update](Dict("font.size" => 20,
                                     "font.weight" => "bold"))
matplotlib[:rc]("xtick", labelsize=15)
matplotlib[:rc]("ytick", labelsize=15)

const iname = joinpath(@__DIR__, "data", "data_20170402_205344.csv")
const params, ratios, uncs = NaCsData.calc_survival(iname)

# With cooling +-1
Params1_1 = [linspace(-18.985, -18.785, 11);]
Params1_2 = [linspace(-18.15, -17.95, 11);]
Params2_1 = [linspace(-18.945, -19.145, 11);]
Params2_2 = [linspace(-18.00, -17.75, 11);]
Params3_1 = [linspace(-18.545, -18.585, 11);]
Params3_2 = [linspace(-18.415, -18.455, 11);]

# Without cooling +-1, -2
Params4_1 = [linspace(-18.985, -18.785, 11);]
Params4_2 = [linspace(-18.15, -17.95, 11);]
Params4_3 = [linspace(-17.53, -17.745, 11);]
Params5_1 = [linspace(-18.945, -19.145, 11);]
Params5_2 = [linspace(-18.00, -17.75, 11);]
Params5_3 = [linspace(-17.14, -17.44, 11);]
Params6_1 = [linspace(-18.545, -18.585, 11);]
Params6_2 = [linspace(-18.415, -18.455, 11);]
Params6_3 = [linspace(-18.35, -18.39, 11);]

# Without cooling carrier
Params7 = [linspace(-18.335, -18.58, 11);]
Params8 = [linspace(-18.31, -18.61, 11);]
Params9 = [linspace(-18.47, -18.53, 11);]

# Without cooling axial high orders
Params10 = [linspace(-18.35, -17.90, 91);]
Params11_1 = [linspace(-18.985, -18.785, 11);]
Params11_2 = [linspace(-18.15, -17.95, 11);]
Params12 = [linspace(-18.945, -19.145, 11); linspace(-18.00, -17.75, 11)]
Params13 = [linspace(-18.545, -18.585, 11); linspace(-18.415, -18.455, 11)]
Params14 = [linspace(-18.985, -18.785, 11); linspace(-18.15, -17.95, 11)]
Params15 = [linspace(-18.945, -19.145, 11); linspace(-18.00, -17.75, 11)]
Params16 = [linspace(-18.545, -18.585, 11); linspace(-18.415, -18.455, 11)]

offset1_1 = length(Params1_1)
offset1_2 = offset1_1 + length(Params1_2)
offset2_1 = offset1_2 + length(Params2_1)
offset2_2 = offset2_1 + length(Params2_2)
offset3_1 = offset2_2 + length(Params3_1)
offset3_2 = offset3_1 + length(Params3_2)
offset4_1 = offset3_2 + length(Params4_1)
offset4_2 = offset4_1 + length(Params4_2)
offset4_3 = offset4_2 + length(Params4_3)
offset5_1 = offset4_3 + length(Params5_1)
offset5_2 = offset5_1 + length(Params5_2)
offset5_3 = offset5_2 + length(Params5_3)
offset6_1 = offset5_3 + length(Params6_1)
offset6_2 = offset6_1 + length(Params6_2)
offset6_3 = offset6_2 + length(Params6_3)
offset7 = offset6_3 + length(Params7)
offset8 = offset7 + length(Params8)
offset9 = offset8 + length(Params9)
offset10 = offset9 + length(Params10)
offset11_1 = offset10 + length(Params11_1)
offset11_2 = offset11_1 + length(Params11_2)
offset12 = offset11_2 + length(Params12)
offset13 = offset12 + length(Params13)
offset14 = offset13 + length(Params14)
offset15 = offset14 + length(Params15)
offset16 = offset15 + length(Params16)

Idx1_1 = [1:offset1_1;]
Idx1_2 = [(offset1_1 + 1):offset1_2;]
Idx2_1 = [(offset1_2 + 1):offset2_1;]
Idx2_2 = [(offset2_1 + 1):offset2_2;]
Idx3_1 = [(offset2_2 + 1):offset3_1;]
Idx3_2 = [(offset3_1 + 1):offset3_2;]
Idx4_1 = [(offset3_2 + 1):offset4_1;]
Idx4_2 = [(offset4_1 + 1):offset4_2;]
Idx4_3 = [(offset4_2 + 1):offset4_3;]
Idx5_1 = [(offset4_3 + 1):offset5_1;]
Idx5_2 = [(offset5_1 + 1):offset5_2;]
Idx5_3 = [(offset5_2 + 1):offset5_3;]
Idx6_1 = [(offset5_3 + 1):offset6_1;]
Idx6_2 = [(offset5_1 + 1):offset6_2;]
Idx6_3 = [(offset5_2 + 1):offset6_3;]
Idx7 = [(offset6_3 + 1):offset7;]
Idx8 = [(offset7 + 1):offset8;]
Idx9 = [(offset8 + 1):offset9;]
Idx10 = [(offset9 + 1):offset10;]
Idx11_1 = [(offset10 + 1):offset11_1;]
Idx11_2 = [(offset11_1 + 1):offset11_2;]
Idx12 = [(offset11_2 + 1):offset12;]
Idx13 = [(offset12 + 1):offset13;]
Idx14 = [(offset13 + 1):offset14;]
Idx15 = [(offset14 + 1):offset15;]
Idx16 = [(offset15 + 1):offset16;]

function plot_params(Params, Idx; kws...)
    perm = sortperm(Params)
    Params = Params[perm]
    Idx = Idx[perm]
    Ratios = ratios[Idx, 2]
    Uncs = uncs[Idx, 2]
    errorbar(Params, Ratios, Uncs; kws...)
end

const save_fig = get(ENV, "NACS_SAVE_FIG", "true") == "true"

function maybe_save(name)
    if save_fig
        savefig("$name.png"; bbox_inches="tight", transparent=true)
        savefig("$name.svg", bbox_inches="tight", transparent=true)
        close()
    end
end

function maybe_show()
    if !save_fig
        show()
    end
end

const prefix = joinpath(@__DIR__, "imgs", "data_20170402_205344")

figure()
# Without cooling
plot_params(Params4_1, Idx4_1, fmt="ro-", label="Before")
plot_params(Params4_2, Idx4_2, fmt="ro-")
plot_params(Params4_3, Idx4_3, fmt="ro-")
plot_params(Params7, Idx7, fmt="ro-")
# With cooling
plot_params(Params1_1, Idx1_1, fmt="bo-", label="After")
plot_params(Params1_2, Idx1_2, fmt="bo-")
grid()
ylim([0, 0.9])
title("Radial 2")
xlabel("\$\\delta\$/MHz")
legend()
maybe_save("$(prefix)_r2")

figure()
# Without cooling
plot_params(Params5_1, Idx5_1, fmt="ro-", label="Before")
plot_params(Params5_2, Idx5_2, fmt="ro-")
plot_params(Params5_3, Idx5_3, fmt="ro-")
plot_params(Params8, Idx8, fmt="ro-")
# With cooling
plot_params(Params2_1, Idx2_1, fmt="bo-", label="After")
plot_params(Params2_2, Idx2_2, fmt="bo-")
grid()
ylim([0, 0.8])
title("Radial 3")
xlabel("\$\\delta\$/MHz")
legend()
maybe_save("$(prefix)_r3")

figure()
# Without cooling
plot_params(Params6_1, Idx6_1, fmt="ro-", label="Before")
plot_params(Params6_2, Idx6_2, fmt="ro-")
plot_params(Params6_3, Idx6_3, fmt="ro-")
plot_params(Params9, Idx9, fmt="ro-")
plot_params(Params10, Idx10, fmt="o-", color="orange", label="Before")
# With cooling
plot_params(Params3_1, Idx3_1, fmt="bo-", label="After")
plot_params(Params3_2, Idx3_2, fmt="bo-")
grid()
ylim([0, 0.7])
title("Axial 1")
xlabel("\$\\delta\$/MHz")
legend()
maybe_save("$(prefix)_a1")

# figure()
# plot_params(Params11_1, Idx11_1, fmt="bo-")
# plot_params(Params11_2, Idx11_2, fmt="bo-")
# grid()
# ylim([0, ylim()[2]])
# title("Radial 2")
# xlabel("\$\\delta\$/MHz")
# maybe_save("$(prefix)_r2")

maybe_show()
