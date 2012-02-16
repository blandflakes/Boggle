#Represents a node in the dictionary graph.  As the graph is built,
#each node is given links to possible letters that follow in this string.
#A node represents a character in a word so far - i.e. There might be a node
#for the character a in the string ca, which would have pointers to nodes
#containing t, n, etc for the words cat, can, and so on.  There will be multiple
#a nodes in the entire graph for different string beginnings.
#The nodes have no notion of the string that came before them; this is managed
#by the calling program.
class WordNode
    def initialize(letter)
        @ends_word = false
        @successors = Hash.new
        @letter = letter
        @exhausted = false
    end
    
    #Returns true if this letter in this string was the end of a word.
    def ends_word?
        @ends_word
    end
    
    def set_ends_word
        @ends_word = true
    end
    
    def letter
        @letter
    end
    
    #successors are nodes that can follow the string so far.
    def successors
        @successors
    end
    
    #A node is exhausted if all solutions of the string beyond its point have
    #been found in a grid.
    def exhausted?
        @exhausted
    end
    
    def exhausted= (val)
        @exhausted = val
    end
    
    #Checks the exhausted status of the successor nodes.
    def successors_exhausted?
        if @successors.empty?
            return true
        end
        @successors.each_value do |node|
            if !node.exhausted?
                return false
            end
        end
        return true
    end
end
     
#The DictionaryMap represents a directed graph of words found in a dictionary.
#There are 26 starting nodes (assuming there is at least one word in the
#dictionary beginning with each letter of the alphabet).  Each of those nodes
#Point to succeeding nodes that form the beginnings (and eventually the ends)
#of words.   
class DictionaryMap
    
    def initialize(file_path)
	    @start_nodes = Hash.new
        open(file_path, 'r').each do |line|
            update_map(@start_nodes, line.downcase.chomp)
        end
    end
    
    #adds information about the word to the map
    def update_map(init_nodes, word)
        current_nodes = init_nodes   
        char = nil
        #follow the chain of characters in this word
        0.upto(word.size - 1) do |index|
            char = word[index]
            #if we find a point where the letters haven't yet been added, update
            if !current_nodes[char]
                current_nodes[char] = WordNode.new(char)
            end
            #if we're at the last character, denote this node as word-ending
            if index == word.size - 1
                current_nodes[char].set_ends_word
            #advance position in the map
            else
                current_nodes = current_nodes[char].successors
            end
        end
    end
    
    def start_nodes
        @start_nodes
    end
    
    #clears the exhausted status of the provided node and its successors
    def reset_node(node)
        node.exhausted = false
        node.successors.each_value do |new_node|
            reset_node(new_node)
        end
    end
    
    #resets the exhausted status of all nodes
    def reset
        @start_nodes.each_value do |node|
            reset_node(node)
        end
    end
    
    #searches the dictionary quickly for word
    def include? (word)
        if word.nil? || word.empty?
            return false
        end
        cur_node = self.start_nodes[word[0]]
        index = 1
        #as long as we have more characters in the word and this word has successors, keep moving
        while index < word.size && cur_node.successors[word[index]] do
            cur_node = cur_node.successors[word[index]]
            index += 1
        end
        #if the loop ended, we either ran out of characters in the word
        #or there were no more successors.  If we ran out of characters in the word,
        #this node must be the end or we don't yet have a word 
        #if we had more characters and the dictionary didn't have an answer, this can't be word.
        #things like "nodenasdfasd" count as words.
        #in conclusion, we must be kicked out by the index < word.size test to even be
        #considered. 
        return index == word.size && cur_node.ends_word?
    end
            
end

#Collapses the map back into words.
#Failure of a comment, above.  Ammended:
#Returns a list of all words beginning with string.
#map should be the list of nodes succeeding in the Dictionary
#after the last character in string.  For example,
#for all words in the dictionary, send dictionary.start_nodes only.
#For all words that start with x, call get_map (dictionary.start_nodes['x'].successors, 'x')
def get_map(map, string = '')
    words = []
    if map.empty?
        puts "Error, made it to the end of string #{string} and found no end node."
        return words
    end
    new_string = nil
    map.each do |letter, node|
        new_string = string + letter
        if node.ends_word?
            words << new_string
        end
        if !node.successors.empty?
            words = words + get_map(node.successors, new_string) 
        end
    end
    return words 
end
