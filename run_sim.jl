
include("sim.jl")
using Agents
using GLMakie
using Random
using Statistics


function add_rentals!(number::Int, rent_average::Int, quality_average::Int, model)
    for _ in 1:number
        rent = rent_average + rand(-100:100)
        minimum_rent = rent - rand(100:300)
        quality = quality_average + rand(-10:10)
        add_agent!(Rental, model, rent, quality, minimum_rent, 0, 0, 0)
    end
end

function add_renters!(number::Int, max_rent_average::Int, min_quality_average::Int, desired_quality_average::Int, model)
    for _ in 1:number
        max_rent = max_rent_average + rand(-100:100)
        min_quality = min_quality_average + rand(-10:10)
        desired_quality = desired_quality_average + rand(-10:10)
        add_agent!(Renter, model, max_rent, min_quality, desired_quality, 0, 0, 0.01)
    end
end


is_rental(a) = a isa Rental
is_renter(a) = a isa Renter

is_empty(tenant) = tenant == 0
is_homeless(address) = address == 0

count_empty_rentals(tenants) = count(is_empty, tenants)
count_homeless(addresses) = count(is_homeless, addresses)


f = Figure()
ax1 = Axis(f[1, 1],
    title="Average rent over time",
    xlabel="Time [month]",
    ylabel="Average Rent [€]",
)
ax2 = Axis(f[1, 2],
    title="Homeless renters over time",
    xlabel="Time [month]",
    ylabel="Number of homeless renters",
)
ax3 = Axis(f[2, 1],
    title="Housing satisfaction over time",
    xlabel="Time [month]",
    ylabel="Score (100 is optimal)",
)
ax4 = Axis(f[2, 2],
    title="Empty rentals over time",
    xlabel="Time [month]",
    ylabel="Empty rentals",
)


function run_sim(steps)
    empty!(ax1)
    empty!(ax2)
    empty!(ax3)
    empty!(ax4)
    test_model1 = init_model()

    add_rentals!(20, 1000, 50, test_model1)
    add_renters!(21, 2000, 40, 55, test_model1)
    agent_df, model_df = run!(test_model1, agent_step, model_step, steps, adata=[
        (:rent, mean, is_rental),
        (:tenant, count_empty_rentals, is_rental),
        (:address, count_homeless, is_renter),
    ],
    mdata=[:housing_satisfaction]
    )
    println(model_df)
    lines!(ax1, agent_df[!, :step], agent_df[!, :mean_rent_is_rental], color=:blue)
    lines!(ax2, agent_df[!, :step], agent_df[!, :count_homeless_address_is_renter], color=:red)
    lines!(ax3, model_df[!, :step], model_df[!, :housing_satisfaction], color=:green)
    lines!(ax4, agent_df[!, :step], agent_df[!, :count_empty_rentals_tenant_is_rental], color=:orange)
end

sg = SliderGrid(
    f[3, :],
    (label="Months", range=1:48, startvalue=18),
    width=350,
    tellheight=false)
f[4, :] = buttongrid = GridLayout(tellwidth=false)
run_button = buttongrid[1, 1] = Button(f, label="Run")
on(run_button.clicks) do n
    run_sim(to_value(sg.sliders[1].value))
end

display(f, title="Rental Market Simulation")