using Agents

@agent Rental GridAgent{2} begin
rent::Int
quality::Int
minimum_price::Int
months_vacant::Int
months_occupied::Int
tenant::Int
end

@agent Renter GridAgent{2} begin
max_rent::Int
min_quality::Int
desired_quality::Int
months_renting::Int
address::NTuple{2, Int}
end

OUT_OF_TOWN = (1, 1)

function agent_step(agent, model)
    neighbours = Agents.nearby_agents(agent, model, 1)
    if agent isa Rental
        if agent.tenant == 0
            agent.months_vacant += 1
        else
            agent.months_occupied += 1
        end
    elseif agent isa Renter
        if agent.address != OUT_OF_TOWN
            agent.months_renting += 1
        end
    end
    return
end

function init_model()
    space = GridSpaceSingle((10, 10); periodic = false)
    model_properties = Dict(:contract_duration => 12, :max_rent_increase_perc => 0.05)
    market_model = ABM(Union{Rental, Renter}, space; properties = model_properties)
    return market_model
end
    