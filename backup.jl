using Random            # For random values
using Statistics        # For Mean and standard deviation
using Distributions     # For Normal distributions 
using Plots             # For Plotting the results and the original data
using DelimitedFiles    # For efficient handling of delimited files
using JSON              # For saving the results in structured format


# Taus for the new sigma calcualtions with Normal distribution
const τ₁ = 1/sqrt(6)
const τ₂ = 1/sqrt(2*sqrt(3))


# The data structure to hold all relevant information about single idividual
mutable struct Invi <:Number
    chromosome::Vector{Float64}
    σ::Vector{Float64}
    fit::Float64
	diffarr::Vector
end

# Simple overlay over the vector to improve the code logics
mutable struct Generation <: Number
    individuals::Vector{Invi}
end

# Output functions, returns the value of the function at i with the variables a,b, and c stored in chromosome
output_function(data, chromosome, i) = chromosome[1]*(data[i]^2 - chromosome[2]*cos(chromosome[3]*π*data[i]))
output_function(data, a, b, c, i) = a*(data[i]^2 - b*cos(c*π*data[i]))

# Shows data encapsulated inside of the individual in the generation inside the population
function show_individal(population::Vector{Any}, i::Int, generation::Int=1)
    println(
            "Individual nr.", i, '\t', "Gen:\t", generation, '\n', 
            "a:\t", population[generation].individuals[i].chromosome[1], '\n', 
            "b:\t", population[generation].individuals[i].chromosome[2], '\n', 
            "c:\t", population[generation].individuals[i].chromosome[3], '\n', 
            "σ:\t", population[generation].individuals[i].σ, '\n', 
            "fit:\t", population[generation].individuals[i].fit, '\n'
        )
end

# Shows the informations about the individual in the selected group of individuals
function show_individal(i::Int, selected::Vector{Invi}, generation::Int)
    println(
            "Individual nr.", i, 
            "a:\t", selected[i].chromosome[1], '\n', 
            "b:\t", selected[i].chromosome[2], '\n', 
            "c:\t", selected[i].chromosome[3], '\n', 
            "σ:\t", selected[i].σ, '\n', 
            "fit:\t", selected[i].fit, '\n'
        )
end

# Initializes the first generation of individual according to the given population quantity
function initialize_population(population, n=20)

    # We need to initialize the Vector of Invi in form of the Generation
    append!(population, Generation(Vector{Invi}()))
    generation = 1

    # Just shortcut 
    this = population[generation].individuals

    for i in 1:n
        
        append!(
            this, 
            Invi(
                [
                    rand(-10:0.01:10),  # a
                    rand(-10:0.01:10),  # b
                    rand(-10:0.01:10)   # c
                ],
                [
                    rand(0:0.01:1),    # σ a
                    rand(0:0.01:1),    # σ b
                    rand(0:0.01:1)     # σ c
                ],                      
				NaN,				    # fit
                []                      # diffarray
            )
        )
        
    end
end

# Sorting the current generation and returning top x of the generation as possible parents
function select_parents(population, generation=1)
    population[generation].individuals = sort(population[generation].individuals, by=v -> v.fit)
    number = Int(floor(length(population[1].individuals)/10))
	return population[generation].individuals[1:number]
end

function rulette_selection(population, generation=1)
    result = Vector{Invi}()
    population = sort(population[generation].individuals, by=v->v.fit)
    best = population[1].fit

    for individual in population
        probability = best/individual.fit
        chance = rand(Uniform(0.0, 1.0))
        if probability > chance
            append!(result, individual)
        end
    end

    if length(result) < 2
        append!(result, population[1])
    end
    
    return result
end

function rulette_selection(generation::Generation, desired_quantity::Int=100)
    result = Vector{Invi}()
    population = sort_generation(generation, desired_quantity)
    best = population.individuals[1].fit

    for individual in population.individuals
        probability = (best)/individual.fittness
        print(probability)
        chance = rand(Uniform(0.0, 1.0))
        if probability > chance
            append!(result, individual)
        end
    end

    if length(result) < 2
        append!(result, population.individuals[best_index])
    end
    
    return Generation(result)
end

function advanced_selection(population, generation=1, number=10)
    result = Vector{Invi}()
    best = Inf
    second_best = Inf
    best_index = 1
    second_best_index = 1
    for i in 1:length(population[generation].individuals)
        candidate =  population[generation].individuals[i].fit
        if best >= candidate
            second_best = best
            second_best_index = best_index

            best = candidate
            best_index = i
        end
    end

    for i in 1:length(population[generation].individuals)
        if abs(population[generation].individuals[i].fit - best) < best*2
            append!(result, population[generation].individuals[i])
        end
    end

    if length(result) < 2
        append!(result, population[generation].individuals[best_index])
    end

    return Generation(result)
end

function sort_generation(generation::Generation, desired_quantity::Int=100)
    generation.individuals = sort(generation.individuals, by=v -> v.fit)[1:desired_quantity]
	return generation
end


function show_generation(population, generation)
    for i in 1:length(population[generation].individuals)
        show_individal(population, i, generation)
    end
end

# Calculates the fitness value for every individual
function evaluate_generation(data, population, population_quantity, data_quantity, generation=1)
    this = population[generation].individuals

    # For every individual
	for i in 1:population_quantity
        # if have not been evaluated
        if isempty(this[i].diffarr)
            # add empty vector
            append!(this[i].diffarr, Vector())

            # For every x in acquired data
            for j in 1:Int(floor(data_quantity/2))
                # add evaluation at x(i) with a b and c of individual
                append!(
                    this[i].diffarr, 
                    output_function(data, this[i].chromosome, j)
                )
            end
            # Calculate fittness value based on difference of value of y(i) and evaluated value for individual
            this[i].fit = std(data[(Int(data_quantity/2) + 1):data_quantity]-this[i].diffarr)^2
        else
            this[i].diffarr = Vector()
            # For every x in acquired data
            for j in 1:Int(floor(data_quantity/2))
                # add evaluation at x(i) with a b and c of individual
                append!(
                    this[i].diffarr, 
                    output_function(data, this[i].chromosome, j)
                )
            end
            # Calculate fittness value based on difference of value of y(i) and evaluated value for individual
            this[i].fit = std(data[(Int(data_quantity/2) + 1):data_quantity]-this[i].diffarr)^2
        end
	end
end

function evaluate_generation(data, generation::Generation, population_quantity, data_quantity)
    # For every individual
	for i in 1:population_quantity
        # if have not been evaluated
        if isempty(generation.individuals[i].diffarr)
            # add empty vector
            append!(generation.individuals[i].diffarr, Vector())

            # For every x in acquired data
            for j in 1:Int(floor(data_quantity/2))
                # add evaluation at x(i) with a b and c of individual
                append!(
                    generation.individuals[i].diffarr, 
                    output_function(data, generation.individuals[i].chromosome, j)
                )
            end
            # Calculate fittness value based on difference of value of y(i) and evaluated value for individual
            generation.individuals[i].fit = std(data[(Int(data_quantity/2) + 1):data_quantity]-generation.individuals[i].diffarr)^2
        else
            generation.individuals[i].diffarr = Vector()
            # For every x in acquired data
            for j in 1:Int(floor(data_quantity/2))
                # add evaluation at x(i) with a b and c of individual
                append!(
                    generation.individuals[i].diffarr, 
                    output_function(data, generation.individuals[i].chromosome, j)
                )
            end
            # Calculate fittness value based on difference of value of y(i) and evaluated value for individual
            generation.individuals[i].fit = std(data[(Int(data_quantity/2) + 1):data_quantity]-generation.individuals[i].diffarr)^2
        end
	end
    return generation
end

function evaluate_individual(data, individual, data_quantity)
    # if difference array is empty, proceed
    if isempty(individual.diffarr)
        # initialize vector in diffarray
        append!(individual.diffarr, Vector())
        # For every x in acquired data
        for j in 1:Int(floor(data_quantity/2))
            # add evaluation for individual with his a, b, and c 
            append!(
                individual.diffarr, 
                output_function(data, individual.chromosome, j)
            )
        end 
        # Calculate fittness
        individual.fit = ((data[(Int(data_quantity/2) + 1):data_quantity]-individual.diffarr).^2)/Int(data_quantity/2)
    end
end

function new_generation_evo(data, data_quantity, population, selected)
    # Make crossover based on selected data and generate 5*population quantity of children
    offspring = crossover(data, data_quantity, population, selected, rand(1:2))
    # Mutate all of children
    offspring = Generation(mutation(offspring))
    # Mutate parents
    selected = mutation(selected)
    # Evaluate new generation
    offspring = evaluate_generation(data, offspring, length(offspring.individuals), data_quantity)
    # Select the best from the population λ + γ and return
    return sort_generation(Generation(Vector{Invi}(vcat(selected, offspring.individuals))), length(population[1].individuals))
end

function new_generation_gen(data, data_quantity, population, selected)
    # crossover generating childs up to yhr population quantity
    offspring = crossover_evo(population, selected)
    # Mutate all of the children
    offspring = mutation(offspring)
    # Return the new generation
    return Generation(Vector{Invi}(vcat(selected, offspring)))
end

# Mutation based on the taus and Normal random distributions
function mutation(offspring, gens_count=3)
    # Length of given ofspring vector
    nr_of_genes = length(offspring[1].chromosome)
    len = length(offspring)
    # For every individual 
    for i in 1:len
        # calculate τ₁ for given chromosome
        gen_tau_1 = exp(rand(Normal(0, τ₁)))
        # For every gen in chromosome
        for gen in 1:nr_of_genes

            # Mutate every gene
            offspring[i].chromosome[gen] = offspring[i].chromosome[gen] + rand(Normal(
                0,
                offspring[i].σ[gen]
            ))
            # Mutate every σ
            offspring[i].σ[gen] = offspring[i].σ[gen]*gen_tau_1*exp(rand(Normal(0, τ₂)))

        end
    end
    # REsturn the offspring after mutation
    return offspring
end

function crossover(data, data_quantity, population, selected, separator)
    len_s = length(selected)
    len_p = length(population[1].individuals)
    offspring = []

    # We are generating 5*difference between the sizes of the base population 
    for i in 1:len_p*5
        # Choosing the first parent randomly
        parent1 = rand(1:len_s)
        # Choosing the second parent randomly from population without parent1
        leftover = [r for r in 1:len_s-1 if r!=parent1]  
        parent2 = rand(leftover)
        # Creating Child
        child = cross_two(data, data_quantity, selected[parent1], selected[parent2], separator)
        # Adding the child to the offspring
        append!(offspring, child)
    end
    # Return the offspring
    return offspring
end

function crossover_evo(population, selected)
    len_s = length(selected)
    len_p = length(population[1].individuals)
    offspring = []
    for i in 1:(len_p-len_s)
        
        append!(offspring, cross_one(mutation(selected[i])))
    end
    return offspring
end

function cross_two(data, data_quantity, parent_first, parent_second, separator)
    # Creating the child based on the prroperties of the parents
    individual = Invi(
        vcat(parent_first.chromosome[1:separator], parent_second.chromosome[separator+1:end]),
        [ 0.5*(parent_first.σ[1] + parent_second.σ[1]), 0.5*(parent_first.σ[2] + parent_second.σ[2]), 0.5*(parent_first.σ[3] + parent_second.σ[3])],
        NaN,
        []
    )
    
    return individual
end

function cross_one(parent_first)
    individual = Invi(
        parent_first.chromosome,
        parent_first.σ,
        NaN,
        []
    )
    return individual
end

function EvolutionAlgorithm(data, population_quantity::Int=200, epsilon=0.000001, save_results::Bool=false, selection_method::String="RuletteSelection")
    top = Int(floor(population_quantity/10))
    generation = 1
    population = []
    data_quantity = length(data)
    
    initialize_population(population, population_quantity)
    evaluate_generation(data, population, population_quantity, data_quantity, generation)
    population[1] = sort_generation(population[1], population_quantity)

    while generation < population_quantity
        if selection_method == "RuletteSelection"
            selected = rulette_selection(population, generation)
        else
            selected = select_parents(population, generation)
        end
        
        next_generation = new_generation_evo(data, data_quantity, population, selected)
        generation +=1
        append!(population, next_generation)
        new_best = population[generation].individuals[1].fit
        best = mean([x.fit for x in population[generation-1].individuals[1:2]])

        if abs(new_best - best) > epsilon
            best = new_best
        else
            break
        end

        evaluate_generation(
            data, 
            population, 
            population_quantity, 
            data_quantity, 
            generation
        )
    end

    # show_generation(population, generation)
    
    if save_results
        write_results(population)
    end
    return select_parents(population, generation)
end

function write_results(population)
    pop = []
    individuals = []
    for gen in 1:length(population)
        for individual in 1:length(population[gen].individuals)
            append!(individuals, Dict(individual => Dict(
                "chromosome" => population[gen].individuals[individual].chromosome,
                "σ"          => population[gen].individuals[individual].σ,
                "fit"        => population[gen].individuals[individual].fit
            )))
        end
        append!(pop, Dict(gen => individuals))
    end

    JSON.json(pop)
    open("Results.json", "w+") do f
        JSON.print(f, pop, 2)
    end
end


function main()
    data = readdlm("ES_data_14.dat")
    best = EvolutionAlgorithm(data, 100, 1e-6, false)

    p1 = plot([data[i] for i in 1:101], [output_function(data, best[1].chromosome, i) for i in 1:101])
    p2 = plot([data[i] for i in 1:101],[[data[i] for i in 102:202], [output_function(data, best[1].chromosome, i) for i in 1:101]])
    
    p3 = scatter([data[i] for i in 1:101], [output_function(data, best[1].chromosome, i) for i in 1:101], color="blue")
    p4 = scatter([data[i] for i in 1:101],[data[i] for i in 102:202])

    plot(p1, p2, p3, p4, layout=(2,2))
    
end


main()
