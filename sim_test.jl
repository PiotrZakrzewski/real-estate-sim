using Test

include("main.jl")


@testset "Test agent_step: vacany duration tracking" begin
    test_model1 = init_model()

    rental1 = add_agent!((1, 2), Rental, test_model1, 1, 1, 1, 0, 0, 0)
    renter1 = add_agent!(OUT_OF_TOWN, Renter, test_model1, 1, 1, 1, 0, OUT_OF_TOWN)

    rental1.tenant = renter1.id
    renter1.address = (1, 2)
    @test 0 == rental1.months_vacant
    @test 0 == rental1.months_occupied
    @test 0 == renter1.months_renting

    step!(test_model1, agent_step, 1)

    @test 1 == rental1.months_occupied
    @test 1 == renter1.months_renting
    @test 0 == rental1.months_vacant
end

@testset "Test agent_step: lowering rent when vacant" begin
    test_model2 = init_model()

    rental2 = add_agent!((1, 2), Rental, test_model2, 1000, 50, 500, 10, 0, 0)

    step!(test_model2, agent_step, 1)
    @test 11 == rental2.months_vacant
    @test 0 == rental2.months_occupied
    @test 950 == rental2.rent
end
