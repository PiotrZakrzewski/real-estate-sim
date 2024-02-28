
include("/home/gieku/sideprojects/real-estate-sim/main.jl")
using Agents
using CairoMakie # choosing a plotting backend
using Random

test_model1 = init_model()

function add_rentals!(number::Int, rent_average::Int, quality_average::Int, model)
    for i in 1:number
        pos = (i, 3) # rentals are always on the third row
        rent = rent_average + rand(-100:100)
        minimum_rent = rent - rand(100:300)
        quality = quality_average + rand(-10:10)
        add_agent!(pos, Rental, model, rent, quality, minimum_rent, 0, 0, 0)
    end
end

function add_renters!(number::Int, max_rent_average::Int, min_quality_average::Int, desired_quality_average::Int, model)
    for i in 1:number
        pos = (i, 1) # homeless agents are on the first row, they will move to the second row when they find a rental
        max_rent = max_rent_average + rand(-100:100)
        min_quality = min_quality_average + rand(-10:10)
        desired_quality = desired_quality_average + rand(-10:10)
        add_agent!(pos, Renter, model, max_rent, min_quality, desired_quality, 0, 0)
    end
end

function average_rent(model)
    all_agents = collect(allagents(model))
    all_agents = filter(x -> x isa Rental, all_agents)
    total_rent = sum([x.rent for x in all_agents])
    return total_rent / length(all_agents)
end

add_rentals!(10, 1000, 50, test_model1)
add_renters!(10, 1100, 40, 55, test_model1)
run!(test_model1, agent_step, 2)

groupcolor(a) = a isa Renter ? :blue : :orange
groupmarker(a) = a isa Renter ? :circle : :rect
text_labels = ["", "", "Out of Town", "", "Residents", "", "Rentals", "", ""]
axis_customizations = (
    title = "",
    xlabel = "",
    ylabel = "",
    yticks = (0:0.5:4 ,text_labels),

)
fig, ax, abmobs = abmplot(test_model1, ac=groupcolor, am=groupmarker, axis=axis_customizations)

Label(fig[0, :], "Average Rent: $(average_rent(test_model1))", fontsize=60)
# hidedecorations!(ax)

elem_1 = [MarkerElement(color=:blue, marker=:circle, markersize=15, strokecolor=:black)]
elem_2 = [MarkerElement(color=:orange, marker=:rect, markersize=15, strokecolor=:black)]


Legend(fig[2, :],
    [elem_1, elem_2],
    ["Renter", "Rental"],
    patchsize=(35, 35), rowgap=10)

save("rental_simulation.png", fig, px_per_unit=1)
