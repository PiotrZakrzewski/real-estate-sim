using Agents
using Statistics
using Random

@agent Rental NoSpaceAgent begin
    rent::Int
    quality::Int
    minimum_rent::Int
    months_vacant::Int
    months_occupied::Int
    tenant::Int
end

@agent Renter NoSpaceAgent begin
    max_rent::Int
    min_quality::Int
    desired_quality::Int
    months_renting::Int
    address::Int
    leave_chance::Float64
end

function agent_step(agent::Renter, model)
    if rand() < agent.leave_chance
        println("Renter $(agent.id) is leaving the simulation!")
        if agent.address != 0
            old_address = model[agent.address]
            old_address.tenant = 0
        end
        remove_agent!(agent, model)
        return
    end
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
        # if the renter already had an address filter out lower quality rentals than the current one
        if agent.address != 0
            all_unoccupied = filter(x -> x.quality >= model[agent.address].quality, all_unoccupied)
        end
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
        # first month vacant - this is the time the landlord will look at the average market rent and use it as a new one
        if agent.months_vacant == 1
            all_agents = collect(allagents(model))
            other_rentals = filter(x -> (x isa Rental && x.id != agent.id), all_agents)
            similar_quality = filter(x -> abs(x.quality - agent.quality) < 5, other_rentals)
            if length(similar_quality) < 2
                println("Not enough similar rentals to calculate the market rent for rental $(agent.id)! Will keep the current rent.")
                return
            end
            agent.rent = Int(ceil(mean([x.rent for x in similar_quality])))
            println("Market rent for rental $(agent.id) is $(agent.rent)!")
            return
        end

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

function housing_satisfaction(model)
    renters = filter(x -> x isa Renter, collect(allagents(model)))
    satisfaction = []
    for renter in renters
        if renter.address != 0
            rental = model[renter.address]
            push!(satisfaction, min(100 - (renter.desired_quality - rental.quality), 100))
        end
    end
    if length(satisfaction) == 0
        return 0
    end
    return round(mean(satisfaction))
end

function model_step(model)
    println("Running model step!")
    housing_satisfaction_score = housing_satisfaction(model)
    model.housing_satisfaction = housing_satisfaction_score
    newcomers_max = getproperty(model, :newcomers_max)
    newcomers_min = getproperty(model, :newcomers_min)
    newcomers_avr_quality = getproperty(model, :newcomers_avr_quality)
    newcomers_avr_max_rent = getproperty(model, :newcomers_avr_max_rent)
    newcomers_leave_chance = getproperty(model, :newcomers_leave_chance)
    newcomers = rand(newcomers_min:newcomers_max)
    if newcomers > 0
        for i in 1:newcomers
            max_rent = rand(0.8*newcomers_avr_max_rent:1.2*newcomers_avr_max_rent)
            quality = rand(0.8*newcomers_avr_quality:1.2*newcomers_avr_quality)
            add_agent!(Renter, model, max_rent, 0, quality, 0, 0, newcomers_leave_chance)
            println("New renter with max rent $(max_rent) and quality $(quality) joined the model!")
        end
    end
end

function init_model(newcomers_max=0, newcomers_min=0, newcomers_avr_quality=50, newcomers_avr_max_rent=1000, newcomers_leave_chance=0.0)
    model_properties = Dict(
        :contract_duration => 12,
        :max_rent_increase_perc => 0.05,
        :rent_decrease_perc => 0.05,
        :newcomers_max => newcomers_max,
        :newcomers_min => newcomers_min,
        :newcomers_avr_quality => newcomers_avr_quality,
        :newcomers_avr_max_rent => newcomers_avr_max_rent,
        :newcomers_leave_chance => newcomers_leave_chance,
        :housing_satisfaction => 0
    )
    return ABM(Union{Rental,Renter}; properties=model_properties, warn=false)
end

