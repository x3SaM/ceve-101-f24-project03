using Base: @kwdef

@kwdef struct ModelParameters{T<:AbstractFloat}
    runoff_coefficient::T
    roof_area_m2::T
    first_flush_mm::T
    tank_capacity_L::T
end

mutable struct Tank
    volume::Float64
end

struct AnnualRainfallData
    dates::Vector{Date}
    precipitation::Vector{Float64}

    function AnnualRainfallData(dates, precipitation)
        @assert length(dates) == length(precipitation) "Dates and precipitation must have the same length"
        new(dates, precipitation)
    end
end

struct RainfallData
    station_info::Dict{String,Any}
    annual_data::Dict{Int,AnnualRainfallData}
end

function Base.show(io::IO, rd::RainfallData)
    println(io, "RainfallData for station: $(rd.station_info["name"])")
    println(io, "  Location: $(rd.station_info["latitude"]), $(rd.station_info["longitude"])")
    println(io, "  Years of data: $(length(rd.annual_data))")
    println(io, "  Total days: $(sum(length(year.dates) for year in values(rd.annual_data)))")
end

function split_years(rainfall_df)
    annual_dfs = [rainfall_df[year.(rainfall_df.date).==y, :] for y in unique(year.(rainfall_df.date))]
    return [AnnualRainfallData(ad.date, ad.prcp_mm) for ad in annual_dfs]
end

function clean_data(rainfall_data::RainfallData, n_min_days::Int)
    cleaned_annual_data = filter(ad -> length(ad.dates) >= n_min_days, rainfall_data.annual_data)
    return RainfallData(rainfall_data.station_info, cleaned_annual_data)
end

function RainfallData(filepath::String; n_min_days::Int=363)
    # Read the CSV file
    raw_data = CSV.read(filepath, DataFrame; delim=';')

    # Get station info from first row
    station_info = Dict(
        "name" => raw_data[1, :Postos],
        "longitude" => raw_data[1, :Longitude],
        "latitude" => raw_data[1, :Latitude]
    )

    # Initialize vectors for our results
    dates = Date[]
    precipitation = Float64[]

    # Process each row (each row is a month of data)
    for row in eachrow(raw_data)
        year = row.Anos
        month = row.Meses

        # Process each day column
        for day in 1:31
            day_col = Symbol("Dia$day")

            # Skip if the column doesn't exist
            if !hasproperty(row, day_col)
                continue
            end

            value = row[day_col]

            # Try to create the date, skip invalid dates (e.g., Feb 31)
            try
                date = Date(year, month, day)

                # Only add valid precipitation values (not 888.0 or missing)
                if !ismissing(value) && value != 888.0 && value != 999.0
                    push!(dates, date)
                    push!(precipitation, value)
                end
            catch
                continue
            end
        end
    end

    # Create the final DataFrame and sort by date
    rainfall_df = sort(DataFrame(date=dates, prcp_mm=precipitation), :date)

    # Split into annual data
    annual_data_vector = split_years(rainfall_df)

    # Convert to dictionary
    annual_data_dict = Dict(year(ad.dates[1]) => ad for ad in annual_data_vector)

    # Clean the data
    cleaned_annual_data = Dict(year => ad for (year, ad) in annual_data_dict if length(ad.dates) >= n_min_days)

    RainfallData(station_info, cleaned_annual_data)
end
