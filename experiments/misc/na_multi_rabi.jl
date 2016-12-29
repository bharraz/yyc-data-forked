#!/usr/bin/julia

push!(LOAD_PATH, joinpath(@__DIR__, "../../lib"))

using NaCsData
using PyPlot
matplotlib["rcParams"][:update](Dict("font.size" => 20,
                                     "font.weight" => "bold"))
matplotlib[:rc]("xtick", labelsize=15)
matplotlib[:rc]("ytick", labelsize=15)

const all_times = linspace(0, 150, 26)
const ntimes = length(all_times)

params, ratios, uncs = NaCsData.calc_survival(ARGS[1])
params_total, ratios_total, uncs_total = NaCsData.calc_survival(ARGS[2])
prefix = ARGS[3]

ratios = ratios[:, 2]
uncs = uncs[:, 2]
ratios_total = ratios_total[:, 2]
uncs_total = uncs_total[:, 2]

function plot_data(times, ratios, uncs, rng, scale; kws...)
    errorbar(times, ratios[rng] ./ scale, uncs[rng] ./ scale; kws...)
end
figure()
plot_data(all_times, ratios, uncs, 1:ntimes, ratios_total[1],
          label="0th", fmt="bo-")
plot_data(all_times, ratios, uncs, (ntimes + 1):(2ntimes), ratios_total[1],
          label="1st", fmt="yo-")
plot_data(all_times, ratios, uncs, (2ntimes + 1):(3ntimes), ratios_total[1],
          label="2nd", fmt="go-")
title("Rabi flopping without cooling")
xlabel("\$t/\\mu s\$")
ylabel("Normalized probability")
grid()
legend()
ylim([0, 1])
savefig("$(prefix)_without_cool.png", bbox_inches="tight", transparent=true)
close()

figure()
plot_data(all_times, ratios, uncs, (3ntimes + 1):(4ntimes), ratios_total[1],
          label="0th", fmt="bo-")
plot_data(all_times, ratios, uncs, (4ntimes + 1):(5ntimes), ratios_total[1],
          label="1st", fmt="yo-")
plot_data(all_times, ratios, uncs, (5ntimes + 1):(6ntimes), ratios_total[1],
          label="2nd", fmt="go-")
title("Rabi flopping with cooling")
xlabel("\$t/\\mu s\$")
ylabel("Normalized probability")
grid()
legend()
ylim([0, 1])
savefig("$(prefix)_with_cool.png", bbox_inches="tight", transparent=true)
close()

figure()
plot_data(all_times, ratios, uncs, 1:ntimes, ratios_total[1],
          label="Without cooling", fmt="ro-")
plot_data(all_times, ratios, uncs, (3ntimes + 1):(4ntimes), ratios_total[1],
          label="With cooling", fmt="bo-")
title("Rabi flopping on carrier")
xlabel("\$t/\\mu s\$")
ylabel("Normalized probability")
grid()
legend()
ylim([0, 1])
savefig("$(prefix)_0th.png", bbox_inches="tight", transparent=true)
close()

figure()
plot_data(all_times, ratios, uncs, (ntimes + 1):(2ntimes), ratios_total[1],
          label="Without cooling", fmt="ro-")
plot_data(all_times, ratios, uncs, (4ntimes + 1):(5ntimes), ratios_total[1],
          label="With cooling", fmt="bo-")
title("Rabi flopping on 1st order sideband")
xlabel("\$t/\\mu s\$")
ylabel("Normalized probability")
grid()
legend()
ylim([0, 1])
savefig("$(prefix)_1st.png", bbox_inches="tight", transparent=true)
close()

figure()
plot_data(all_times, ratios, uncs, (2ntimes + 1):(3ntimes), ratios_total[1],
          label="Without cooling", fmt="ro-")
plot_data(all_times, ratios, uncs, (5ntimes + 1):(6ntimes), ratios_total[1],
          label="With cooling", fmt="bo-")
title("Rabi flopping on 2nd order sideband")
xlabel("\$t/\\mu s\$")
ylabel("Normalized probability")
grid()
legend()
ylim([0, 1])
savefig("$(prefix)_2nd.png", bbox_inches="tight", transparent=true)
close()

# show()
