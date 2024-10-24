function get_inflow(precip_mm, param::ModelParameters)
    return max(0.0, param.runoff_coefficient * param.roof_area_m2 * (precip_mm - param.first_flush_mm))
end

function get_consumption(date)
    doy = dayofyear(date)
    return doy > 150 ? 74.1 : 0.0
end

function run_timestep!(tank::Tank, date, precip_mm, param::ModelParameters)
    consumption = get_consumption(date) # in liters
    inflow = get_inflow(precip_mm, param) # in liters
    tank.volume += inflow - consumption # in liters
    failure = tank.volume < 0.0
    if failure
        tank.volume = 0.0
    else
        tank.volume = min(tank.volume, param.tank_capacity_L)
    end
    return failure
end

struct SimulationOutput
    dates::Vector{Date}
    volumes::Vector{Float64}
    failure_dates::Vector{Date}
end

function run_timesteps(tank::Tank, annual_data::AnnualRainfallData, param::ModelParameters)
    volumes = zeros(Float64, length(annual_data.dates))
    failure_dates = Date[]

    for (i, (date, precip)) in enumerate(zip(annual_data.dates, annual_data.precipitation))
        failure = run_timestep!(tank, date, precip, param)
        volumes[i] = tank.volume
        if failure
            push!(failure_dates, date)
        end
    end

    return SimulationOutput(annual_data.dates, volumes, failure_dates)
end

function run_timesteps(annual_data::AnnualRainfallData, param::ModelParameters)
    tank = Tank(0.0) # initialize empty by default
    return run_timesteps(tank, annual_data, param)
end
