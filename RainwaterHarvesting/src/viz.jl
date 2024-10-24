using Plots

Plots.default(margin=5Plots.mm)

function Plots.plot(annual_data::AnnualRainfallData; label=string(year(annual_data.dates[1])), yaxis="Daily Rainfall [mm]", kwargs...)
    p = plot(annual_data.dates, annual_data.precipitation, label=label, yaxis=yaxis, kwargs...)
    return p
end

function Plots.plot(rainfall_data::RainfallData, label=rainfall_data.station_info["name"], yaxis="Daily Rainfall [mm]", kwargs...)
    # Sort the annual data by year and concatenate dates and precip
    sorted_years = sort(collect(keys(rainfall_data.annual_data)))
    dates = vcat([rainfall_data.annual_data[year].dates for year in sorted_years]...)
    precip = vcat([rainfall_data.annual_data[year].precipitation for year in sorted_years]...)

    p = plot(dates, precip, label=label, yaxis=yaxis, kwargs...)
    return p
end

function Plots.plot(sim_output::SimulationOutput;
    volume_label="Tank Volume",
    failure_label="Failures",
    yaxis="Tank Volume [L]",
    kwargs...)
    p = plot(sim_output.dates, sim_output.volumes,
        label=volume_label,
        yaxis=yaxis,
        linewidth=2,
        kwargs...)

    if !isempty(sim_output.failure_dates)
        scatter!(p, sim_output.failure_dates, zeros(length(sim_output.failure_dates)),
            label=failure_label,
            markersize=6,
            markershape=:x,
            markercolor=:red)
    end

    return p
end
