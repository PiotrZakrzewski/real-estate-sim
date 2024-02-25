using Agents

space = GridSpaceSingle((10, 10); periodic = false)

@agent Rental GridAgent{2} begin
    rent::Int
    quality::Int
    minimum_price::Int
    months_vacant::Int
    months_occupied::Int
end

@agent Renter GridAgent{2} begin
    max_rent::Int
    min_quality::Int
    desired_quality::Int
    months_renting::Int
end

model_properties = Dict(:contract_duration => 12, :max_rent_increase_perc => 0.05)

RentalMarketModel = ABM(GridAgent{2}, space; properties = model_properties)