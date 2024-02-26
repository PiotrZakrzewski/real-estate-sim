using Test

include("main.jl")


@testset "Test agent_step: Vacancy duration tracking" begin
    test_model1 = init_model()

    rental1 = add_agent!(Rental, test_model1, 1, 1, 1, 0, 0, 0)
    renter1 = add_agent!(Renter, test_model1, 1, 1, 1, 0, 0)

    rental1.tenant = renter1.id
    renter1.address = rental1.id
    @test 0 == rental1.months_vacant
    @test 0 == rental1.months_occupied
    @test 0 == renter1.months_renting

    step!(test_model1, agent_step, 1)

    @test 1 == rental1.months_occupied
    @test 1 == renter1.months_renting
    @test 0 == rental1.months_vacant
end

@testset "Test agent_step: Lowering rent when vacant" begin
    test_model2 = init_model()

    rental2 = add_agent!(Rental, test_model2, 1000, 50, 500, 10, 0, 0)

    step!(test_model2, agent_step, 1)
    @test 11 == rental2.months_vacant
    @test 0 == rental2.months_occupied
    @test 950 == rental2.rent
end

@testset "Test agent_step: Increasing the rent when occupied" begin
    test_model3 = init_model()

    rental3 = add_agent!(Rental, test_model3, 1000, 50, 500, 0, 11, 0)
    renter3 = add_agent!(Renter, test_model3, 1000, 50, 500, 0, 0)

    rental3.tenant = renter3.id
    renter3.address = rental3.id

    step!(test_model3, agent_step, 1)
    @test 0 == rental3.months_vacant
    @test 12 == rental3.months_occupied
    @test 1050 == rental3.rent

    step!(test_model3, agent_step, 1)
    @test 0 == rental3.months_vacant
    @test 13 == rental3.months_occupied
    @test 1050 == rental3.rent

    step!(test_model3, agent_step, 11)
    @test 0 == rental3.months_vacant
    @test 24 == rental3.months_occupied
    @test 1103 == rental3.rent
end

@testset "Test agent_step: Renter picks a Rental according to their parameters" begin
    test_model4 = init_model()
    too_expensive_rental = add_agent!(Rental, test_model4, 2000, 50, 500, 0, 0, 0)
    too_low_quality_rental = add_agent!(Rental, test_model4, 900, 40, 500, 0, 0, 0)
    good_rental = add_agent!(Rental, test_model4, 800, 60, 500, 0, 0, 0)
    alreaedy_occupied_rental = add_agent!(Rental, test_model4, 800, 60, 500, 0, 0, 0)

    another_renter = add_agent!(Renter, test_model4, 1000, 55, 500, 0, 0)
    alreaedy_occupied_rental.tenant = another_renter.id
    another_renter.address = alreaedy_occupied_rental.id

    renter4 = add_agent!(Renter, test_model4, 1000, 50, 500, 0, 0)

    step!(test_model4, agent_step, 1)

    @test 0 == too_expensive_rental.tenant
    @test 0 == too_low_quality_rental.tenant
    @test good_rental.id == renter4.address
    @test renter4.id == good_rental.tenant
    @test another_renter.id == alreaedy_occupied_rental.tenant
end
