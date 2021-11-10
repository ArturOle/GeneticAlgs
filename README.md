# EvoAlg

## Introduction

Evolutionary Strategies which is implemented in this project belongs to the family of genetic algorithms. This project takes (λ + γ) approach, this mean that for the next generation we take individuals from both parents and offsprings/children. Evolutionary Strategies take advantege of sigma-besed mustation proces which is the main drive for improvment in this implementation.

#
## Algorithm

1. **Initialization** - Initialization of the base population (generation 1)
2. **Evaluation** - Evaluation of generation 1
3. **Selection** - Selection of "parents" for creating new generation (Rulette or Steady State)
4. **Generating new generation** - Generating the new generationfor future calculations with lambda \ gamma approach
5. **Evaluation** - Evaluating the most current generation
6. **Check if done** - Checking the stop condition
7. **Loop** - loop until stop condition is met

```julia
function EvolutionAlgorithm(data, population_quantity::Int=200, epsilon=0.000001, save_results::Bool=false)
    top = Int(floor(population_quantity/10))
    generation = 1
    population = []
    data_quantity = length(data)
    best = Inf
    
    initialize_population(population, population_quantity)
    evaluate_generation(data, population, population_quantity, data_quantity, generation)

    while true
        selected = select_parents(population, generation, top)
        next_generation = new_generation_evo(data, data_quantity, population, selected)
        generation +=1
        append!(population, next_generation)
        best = population[generation].individuals[1].fit
        new_best = population[generation].individuals[1+top].fit

        if abs(new_best - best) >= epsilon
            best = new_best
        else
            break
        end

        evaluate_generation(
            data, population, 
            population_quantity, 
            data_quantity, 
            generation
        )
    end

    show_generation(population, generation)
    
    if save_results
        write_results(population)
    end
    return select_parents(population, generation, top)
end
```
## Inintialization

Initialization is start of the program. It is a part where we create our "generation 1". This is also the place for initialization of all necessary variables.

```julia

top = Int(floor(population_quantity/10))
generation = 1
population = []
data_quantity = length(data)
best = Inf
    
initialize_population(population, population_quantity)
evaluate_generation(data, population, population_quantity, data_quantity, generation)

```
#
## Selection

Project includes two diffrent approaches to the selection of parents.


### Rulette Selection

First impelementation is the **Rulette Selection** which uses the culmulative fitness value
and fitness values of every individual to create chances of getting into maiting pool.
In our algorithm, as we want to minimize the fitness value ( best case is 0 ), we are creating chances by deviding the best fitness value by fitness value of the candidate.
In this way we have chance equal 1 to choose the best candidate and other candidates heve equally fair chances ( based on thir fitness value ).


```julia

```

### Steady State Selection

Second implementation is the **Solid State Selection**.
In this method we sort the whole population by fitness value and choose x of the best candidates. The x is dependent on the population size and in our implementation is calculated as population_quantity / 10 to get 10% of current generation.

```julia
function select_parents(population, generation=1, number=10)
    population[generation].individuals = sort(population[generation].individuals, by=v -> v.fit)
	return population[generation].individuals[1:number]
end
```



















