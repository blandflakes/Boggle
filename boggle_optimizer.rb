load 'boggle.rb'

class BoggleSpawn

    def initialize(string, agent)
        @string = string
        @agent = agent
        @fitness_score = nil
    end
    
    def write_to_file(file_path)
        i = 1
        out = open(file_path, 'w')
        @string.each_char do |char|
            out.print char
            if i % 5 == 0
                out.print "\n"
            else
                out.print ","
            end
            i += 1
        end
        out.close
    end
    
    def string
        @string
    end
    
    def to_s
        @string
    end
    
    def fitness
        if !@fitness_score
            self.write_to_file('temp_boggle.txt')
            @agent.new_puzzle('temp_boggle.txt')
            @fitness_score = @agent.score(@agent.solve('temp_out.txt'))
        end
        return @fitness_score
    end
    
    def <=> (other)
        return self.fitness <=> other.fitness
    end
end

class GenePool

    def initialize(agent, num_spawn, mutation_probability, cull_threshold = -1, cull_delay = 1000)
        @pop = []
        1.upto(num_spawn) do |i|
            @pop << BoggleSpawn.new(25.times.map {(97 + Random.rand(25)).chr}.join, agent)
        end
        @agent = agent
        @mutation = mutation_probability
        @cull = cull_threshold
        @cull_delay = cull_delay
    end
    
    def random_selection(population, generation)
        #puts "Selecting parents"
        selected = []
        candidates = []
        population.select {|spawn| @cull == -1 or generation < @cull_delay or spawn.fitness >= @cull}.each do |candidate|
            1.upto(candidate.fitness) do |x|
                candidates << candidate
            end
        end
        1.upto(population.size) do |x|
            selected << candidates[Random.rand(candidates.size)]
        end
        return selected
    end
    
    def reproduce(parent1, parent2, agent)
        #puts "Reproducing"
        crossover = Random.rand(parent1.string.size)
        child1 = BoggleSpawn.new(parent1.string[0,crossover] + parent2.string[crossover,parent2.string.size], agent)
        child2 = BoggleSpawn.new(parent2.string[0,crossover] + parent1.string[crossover,parent2.string.size], agent)
        return [child1, child2]
    end
    
    def mutate(child)
        #puts "Running mutation subroutine"
        0.upto(child.string.size - 1) do |str_index|
            if Random.rand(100) < @mutation
                child.string[str_index] = (97 + Random.rand(25)).chr
            end
        end
        return child
    end
    
    def evolve(num_generations)
        1.upto(num_generations) do |generation|
            new_pop = []
            parents = random_selection(@pop, generation)
            (0..@pop.size - 1).step(2) do |index|
                new_pop = new_pop + reproduce(parents[index], parents[index + 1], @agent).map {|child| mutate(child)}
            end
            best = new_pop.sort[-1]
            worst = new_pop.sort[0]
            puts "---------------------------------------------"
            puts "Best: #{best} with score #{best.fitness}"
            puts "Worst: #{worst} with score #{worst.fitness}"
            best.write_to_file("boards/generation_#{generation}_#{best.fitness}.txt")
            @pop = new_pop
        end
    end
end

#main
agent = BoggleAgent.new(nil, 'test_dict.txt')
pool = GenePool.new(agent, 100, 5, 70)
puts "How many generations? "
generations = gets.chomp.to_i
pool.evolve(generations)
