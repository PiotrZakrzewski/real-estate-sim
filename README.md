# Agent Simulation of a Real Estate Market
The goal of the first iteration is to simulate entry of 30% ruling workers to the Amsterdam market
- Use 2d grid, each cell represents one housing unit
- Two types of agents: Housing Unit (known as rental) and a renter
- rental has the following properties: quality, price, minimum price, months_occupied, months_vacant
- rental starting price is given by its quality
- renter has the following properties: minimum quality, desired_quality, budget
- Every step is one month
- every step rental evaluates its price using the following algorithm:
    - (only if empty) number of months the rental remained empty determines the % chance of lowering the price
    - (if occupied) every 12 months of being occupied rise price by max allowed
- every step renter will evaluate their living situation:
    - if homeless: will take the rental closest to their desired quality that first into the budget, will never take a rental below min quality
    - if currently renting: every 12 months will upgrade to a rental closer to their desired quality