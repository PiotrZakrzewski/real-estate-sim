using Agents

@agent Rental GridAgent{2} begin
    rent::Int
    quality::Int
    minimum_rent::Int
    months_vacant::Int
    months_occupied::Int
    tenant::Int
end

@agent Renter GridAgent{2} begin
    max_rent::Int
    min_quality::Int
    desired_quality::Int
    months_renting::Int
    address::Int
end

function agent_step(agent::Renter, model)
    if agent.address != 0
        agent.months_renting += 1
    end
    if agent.address == 0 || agent.months_renting % getproperty(model, :contract_duration) == 0
        println("Renter $(agent.id) is looking for a new rental!")
        all_agents = collect(allagents(model))
        # filter to leave only rentals
        all_agents = filter(x -> x isa Rental, all_agents)
        all_unoccupied = filter(x -> x.tenant == 0, all_agents)
        # sort on how close they are to the desired quality, descending
        all_unoccupied = sort(all_unoccupied, by=x -> abs(x.quality - agent.desired_quality), rev=true)
        # sort on rent descending
        all_unoccupied = sort(all_unoccupied, by=x -> x.rent, rev=true)
        # filter out the ones that are too expensive or below the minimum quality
        all_unoccupied = filter(x -> x.rent <= agent.max_rent && x.quality >= agent.min_quality, all_unoccupied)
        if length(all_unoccupied) > 0
            # if the agent already had an address, we need to free it
            if agent.address != 0
                println("Renter $(agent.id) is moving out of rental $(agent.address)!")
                old_address = model[agent.address]
                old_address.tenant = 0
            end
            chosen = all_unoccupied[1]
            agent.address = chosen.id
            chosen.tenant = agent.id
            occupied_pos = (chosen.pos[1], 2)
            move_agent!(agent, occupied_pos, model)
            println("Renter $(agent.id) is moving into rental $(chosen.id)!")
        else 
            println("Renter $(agent.id) couldn't find a rental!")
        end
    end
    return
end

function agent_step(agent::Rental, model)
    if agent.tenant == 0
        agent.months_occupied = 0
        agent.months_vacant += 1
        rent_decrease = getproperty(model, :rent_decrease_perc) * agent.rent
        # round up to the nearest integer
        rent_decrease = Int(ceil(rent_decrease))
        agent.rent -= rent_decrease
        agent.rent = max(agent.rent, agent.minimum_rent)
        println("Rent decreased by $rent_decrease for rental $(agent.id) to $(agent.rent)!")
    else
        agent.months_vacant = 0
        agent.months_occupied += 1
        if agent.months_occupied % getproperty(model, :contract_duration) == 0
            rent_increase = getproperty(model, :max_rent_increase_perc) * agent.rent
            # round up to the nearest integer
            rent_increase = Int(ceil(rent_increase))
            # log the rent increase
            println("Rent increased by $rent_increase for agent $(agent.id) to $(agent.rent + rent_increase)!")
            agent.rent += rent_increase
        end
    end
    return
end

function init_model(size::Int=10)
    space = GridSpace((size, 3))
    model_properties = Dict(:contract_duration => 12, :max_rent_increase_perc => 0.05, :rent_decrease_perc => 0.05)
    return ABM(Union{Rental,Renter}, space; properties=model_properties)
end

