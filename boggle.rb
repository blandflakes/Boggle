load 'dict_map.rb'
require 'set'
#A GridNode represents a square on the Boggle grid.
class GridNode
    def initialize(letter)
        @letter = letter
        @visited = false
        @adjacent = []
    end
    
    #Returns true if we've already visited this node on this word possibility.
    def visited= (val)
        @visited = val
    end
    
    def visited?
        @visited
    end
    
    #Adds a node to the list of adjacent nodes.  By calculating them once when
    #creating the grid, we avoid excessive bounds checking and conditionals
    #when attempting to find new words.
    def add_adjacent(node)
        @adjacent << node
    end
    
    def adjacent
        @adjacent
    end
    
    def to_s
        @letter
    end
    
    def letter
        @letter
    end
end

#Represents a found word with a scored value.
class Word
    def initialize(word)
        @word = word
        @value = get_value(word)
    end
    
    def get_value(word)
        case word.size
        when 0, 1, 2
            return 0
        when 3, 4
            return 1
        when 5
            return 2
        when 6
            return 3
        when 7
            return 5
        else
            return 11
        end
    end
    
    #eql? and hash are to remove duplicates in the result set, although the
    #optimizations I put in place should avoid duplicates showing up.
    def eql? other
        @word == other.word
    end
    
    def word
        @word
    end
    
    def value
        @value
    end
    
    def hash
        @word.hash
    end
end

#This is the agent that solves Boggle.  The general strategy is to consider
#each square in the grid as a potential starting location for a word.
#At any point, the possible next locations are considered by looking at unvisited
#locations.  By examing this character in the DictionaryMap, we can disregard
#paths that would lead to strings not in the dictionary instead of creating
#random strings and then checking against a list.
class BoggleAgent

    def initialize(grid_path, dict_path)
        @dictionary = DictionaryMap.new(dict_path)
        #puts "Dictionary loaded."
        if grid_path
            @grid = get_grid(grid_path)
            #puts "Grid loaded."
        end
    end
    
    #Clears the visited flag for all nodes in the grid
    def reset
        @dictionary.reset
        #puts "Dictionary reset."
        @grid.each do |row|
            row.each do |location|
                location.visited = false
            end
        end
        #puts "Grid reset."
    end
    
    #Loads a new grid into the program to be solved
    def new_puzzle(grid_path)
        @dictionary.reset
       #puts "Dictionary reset."
        @grid = get_grid(grid_path)
        #puts "New grid loaded."
    end
    
    #Creates the grid from a csv file.  Also calculates and assigns
    #adjacent nodes for path navigating.
    def get_grid(grid_path)
        #read csv into array of gridnodes.
        grid = open(grid_path, 'r').readlines.map {|line| line.chomp.split(',').map {|letter| GridNode.new(letter)}}
        current = nil
        0.upto(grid.size - 1) do |row_index|
            0.upto(grid[row_index].size - 1) do |col_index|

                current = grid[row_index][col_index]
                
                
                if col_index > 0
                    #Add node directly left
                    current.add_adjacent(grid[row_index][col_index - 1])
                    if row_index > 0
                        #add node above and left
                        current.add_adjacent(grid[row_index - 1][col_index - 1])
                    end
                    if row_index < grid.size - 1
                        #add node below and left
                        current.add_adjacent(grid[row_index + 1][col_index - 1])
                    end
                end
        
                if row_index > 0
                    #add node directly above
                    current.add_adjacent(grid[row_index - 1][col_index])
                end
                if row_index < grid.size - 1
                    #add node directly below
                    current.add_adjacent(grid[row_index + 1][col_index])
                end

                if col_index < grid[row_index].size - 1
                    #add node directly right
                    current.add_adjacent(grid[row_index][col_index + 1])
                    if row_index > 0
                        #add node above and right
                        current.add_adjacent(grid[row_index - 1][col_index + 1])
                    end
                    if row_index < grid.size - 1
                        #add node below and right
                        current.add_adjacent(grid[row_index + 1][col_index + 1])
                    end
                end
                
            end#end column iteration
        end#end row iteration
        return grid
    end
    
    def grid
        @grid
    end
    
    #recursive function for finding all words from a particular location.
    #At each point, considers all surrounding blocks that are in the dictionary
    #for the word up to this character.
    def solve_location(location, successors, string)
        #puts "Searching for successors around #{location}, current word is #{string}"
        #puts "Options are #{location.adjacent.select{|possible_move| !possible_move.visited?}}"
        new_string = nil
        next_node = nil
        words = []
        #only want nodes that haven't been visited in this run yet (visible
        #has been set by calling stack frame)
        location.adjacent.select{|possible_move| !possible_move.visited?}.each do |move|
            #puts "Checking dictionary for words with next letter of #{move.letter} for string #{string}"
            next_node = successors[move.letter]
            if next_node and !next_node.exhausted? #if this is found, we can make more words
                #puts "Successor found."
                new_string = string
                #avoid using block twice
                move.visited = true
                
                new_string += next_node.letter
                if next_node.ends_word?#if this character is the end of a word, add it to our list
                    #puts "Word found, adding: #{new_string}"
                    words << Word.new(new_string)
                    if next_node.successors_exhausted?#update exhausted status since we used this word
                        #puts "Exhausted node #{next_node.letter} with string '#{string}'."
                        next_node.exhausted = true
                    end
                end
                if !next_node.successors.empty?#if we have successors, keep going
                    words = words + solve_location(move, next_node.successors, new_string)
                    if next_node.successors_exhausted?#if the successors are exhausted, so are we.
                        #puts "Exhausted node #{next_node.letter} with string '#{string}'."
                        next_node.exhausted = true
                    end
                else
                    #puts "No more successors, giving up on #{string}"
                end
                #unflag this position so that other paths can use it
                move.visited = false
            end
        end
        return words
    end
    
    #This calls the recursive solve - goes over each square in the grid, calling
    #solve_location with the proper resources.  If a filepath is provided,
    #the score will be output into a CSV.
    def solve (file_path = nil)
        words = Set.new
        @grid.each do |row|
            row.each do |location|
                if @dictionary.start_nodes[location.letter] and !@dictionary.start_nodes[location.letter].exhausted?
                    location.visited = true
                    words = words + solve_location(location, @dictionary.start_nodes[location.letter].successors, location.letter)
                    if @dictionary.start_nodes[location.letter].successors_exhausted?
                        #puts "Exhausted starting letter #{location.letter}."
                        @dictionary.start_nodes[location.letter].exhausted = true
                    end
                    location.visited = false
                else
                    #puts "No word in dictionary begins with #{location.letter}"
                end
            end
        end
        if file_path
            out = open(file_path, 'w')
            out.puts "Total score: #{score(words)}"
            out.puts "Value,Word"
            words.each do |word|
                out.puts "#{word.value},#{word.word}"
            end
         else
            puts "Total score: #{score(words)}"
            puts "Value,Word"
            words.each do |word|
                puts "#{word.value},#{word.word}"
            end
         end   
        return words
    end        
    
    def score(word_list)
        word_list.inject(0) {|score, word| score + word.value}
    end    
end
