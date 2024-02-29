
include("main.jl")
using Agents
using CairoMakie
using Random
using Statistics

test_model1 = init_model()

function add_rentals!(number::Int, rent_average::Int, quality_average::Int, model)
    for i in 1:number
        rent = rent_average + rand(-100:100)
        minimum_rent = rent - rand(100:300)
        quality = quality_average + rand(-10:10)
        add_agent!(Rental, model, rent, quality, minimum_rent, 0, 0, 0)
    end
end

function add_renters!(number::Int, max_rent_average::Int, min_quality_average::Int, desired_quality_average::Int, model)
    for i in 1:number
        max_rent = max_rent_average + rand(-100:100)
        min_quality = min_quality_average + rand(-10:10)
        desired_quality = desired_quality_average + rand(-10:10)
        add_agent!(Renter, model, max_rent, min_quality, desired_quality, 0, 0)
    end
end

add_rentals!(2, 1000, 50, test_model1)
add_renters!(1, 2000, 40, 55, test_model1)

is_rental(a) = a isa Rental
is_renter(a) = a isa Renter

is_empty(tenant) = tenant == 0
is_homeless(address) = address == 0

count_empty_rentals(tenants) = count(is_empty, tenants)
count_homeless(addresses) = count(is_homeless, addresses)

function housing_satisfaction(agent_ids)
    renters = [test_model1[agent_id] for agent_id in agent_ids if is_renter(test_model1[agent_id])]
    satisfaction = []
    for renter in renters
        if renter.address != 0
            rental = test_model1[renter.address]
            push!(satisfaction, 100 - (renter.desired_quality - rental.quality))
        end
    end
    if length(satisfaction) == 0
        return 0
    end
    return mean(satisfaction)
end


agent_df, model_df = run!(test_model1, agent_step, 48, adata=[
    (:rent, mean, is_rental),
    (:tenant, count_empty_rentals, is_rental),
    (:address, count_homeless, is_renter),
    (:id, housing_satisfaction)
],
)

println(agent_df)
