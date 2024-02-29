
include("/home/gieku/sideprojects/real-estate-sim/main.jl")
using Agents
using CairoMakie # choosing a plotting backend
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

function average_rent(model)
    all_agents = collect(allagents(model))
    all_agents = filter(x -> x isa Rental, all_agents)
    total_rent = sum([x.rent for x in all_agents])
    return total_rent / length(all_agents)
end

add_rentals!(2, 1000, 50, test_model1)
add_renters!(1, 2000, 40, 55, test_model1)

is_rental(a) = a isa Rental

agent_df, model_df = run!(test_model1, agent_step, 48, adata = [(:rent, mean, is_rental)])

println(agent_df)
