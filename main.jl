using Random
using Statistics
using Distributions
using Plots
using DelimitedFiles


mutable struct Invi <:Number
    chromosome::Vector{Float64}
    σ::Float64
    fit::Float64
	diffarr::Vector
end

mutable struct Generation <: Number
    individuals::Vector{Invi}
end


output_function(data, chromosome ,i) = chromosome[1]*(data[i]^2 - chromosome[2]*cos(chromosome[3]*π*data[i]))

function show_individal(population, i, generation=1)
    println(
            "Individual nr.", i, '\t', "Gen:\t", generation, '\n', 
            "a:\t", population[generation].individuals[i].chromosome[1], '\n', 
            "b:\t", population[generation].individuals[i].chromosome[2], '\n', 
            "c:\t", population[generation].individuals[i].chromosome[3], '\n', 
            "σ:\t", population[generation].individuals[i].σ, '\n', 
            "fit:\t", population[generation].individuals[i].fit, '\n'
        )
end

function show_individal(i, selected)
    println(
            "Individual nr.", i, '\n', 
            "a:\t", selected[i].chromosome[1], '\n', 
            "b:\t", selected[i].chromosome[2], '\n', 
            "c:\t", selected[i].chromosome[3], '\n', 
            "σ:\t", selected[i].σ, '\n', 
            "fit:\t", selected[i].fit, '\n'
        )
end

function initialize_population(population, n=20)
    append!(population, Generation(Vector{Invi}()))
    generation = 1
    this = population[generation].individuals
    for i in 1:n
        
        append!(
            this, 
            Invi(
                [
                    rand(-10:0.001:10),  # a
                    rand(-10:0.001:10),  # b
                    rand(-10:0.001:10)   # c
                ],
                rand(1:0.001:5),         # σ a
				NaN,				     # fit
                []                       # diffarray
            )
        )
        
    end
end

function select_tournament(population, generation=1, number=10)
    population[generation].individuals = sort(population[generation].individuals, by=v -> v.fit)
	return population[generation].individuals[1:number]
end

function show_generation(population, generation)
    for i in 1:length(population[generation].individuals)
        show_individal(population, i, generation)
    end
end

function evaluate_generation(data, population, population_quantity, data_quantity, generation=1)
    this = population[generation].individuals
	for i in 1:population_quantity
        if isempty(this[i].diffarr)
            append!(this[i].diffarr, Vector())
            for j in 1:Int(floor(data_quantity/2))
                append!(
                    this[i].diffarr, 
                    output_function(data, this[i].chromosome, j)
                )
            end
            this[i].fit = std(abs.(data[(Int(data_quantity/2) + 1):data_quantity]-this[i].diffarr))
        end
	end
end

function new_generation(population, generation, selected)
    offspring = crossover(population, generation, selected, rand(1:2))
    offspring = mutation(offspring, generation)
    return Generation(Vector{Invi}(vcat(selected, offspring)))
end

function mutation(offspring, generation)
    len = length(offspring)
    for i in 1:len
        gen = rand(1:3)
        index = rand(1:len)
        offspring[index].chromosome[gen] = rand(Normal(
            offspring[index].chromosome[gen], 
            offspring[index].σ/(generation*1.5)
        ))
    end
    return offspring
end

function crossover(population, generation, selected, separator)
    len_s = length(selected)
    len_p = length(population[1].individuals)
    offspring = []
    for i in 1:(len_p-len_s)
        parent1 = rand(1:len_s)
        leftover = [r for r in 1:len_s-1 if r!=parent1]
        parent2 = rand(leftover)
        child = cross_two(selected[parent1], selected[parent2], separator)
        append!(offspring, child)
    end
    return offspring
end

function cross_two(parent_first, parent_second, separator)
    return Invi(
        vcat(parent_first.chromosome[1:separator], parent_second.chromosome[separator+1:end]),
        rand(1:0.001:5),  # σ a
        NaN,
        []
    )
end

function EvolutionarAlgorithm(data, population_quantity::Int=200, iterations::Int=40, top=50)
    iteration = 0
    generation = 1
    population = []
    data_quantity = length(data)
    
    initialize_population(population, population_quantity)
    evaluate_generation(data, population, population_quantity, data_quantity, generation)

    while iteration < iterations
        iteration += 1
        selected = select_tournament(population, generation, top)
        next_generation = new_generation(population, generation, selected)
        append!(population, next_generation)
        generation +=1
        evaluate_generation(data, population, population_quantity, data_quantity, generation)
    end
    
    show_generation(population, generation)
    return select_tournament(population, generation, top)
end

function main()
    data = readdlm("ES_data_30.dat")
    best = EvolutionarAlgorithm(data, 100, 40, 40)
    
    p1 = plot([data[i] for i in 1:101], [output_function(data, best[1].chromosome, i) for i in 1:101])
    p2 = plot([data[i] for i in 1:101],[data[i] for i in 102:202])
    
    p3 = scatter([data[i] for i in 1:101], [output_function(data, best[1].chromosome, i) for i in 1:101], color="blue")
    p4 = scatter([data[i] for i in 1:101],[data[i] for i in 102:202])

    plot(p1, p2, p3, p4, layout=(2,2))
end


main()
