load 'boggle.rb'

puts "What is the filename of the board you would like to solve? "
board_path = gets.chomp
puts "What is the filename of the dictionary you would like to use? "
dict_path = gets.chomp
puts "What is the name of the file you would like the output stored in? "
out_path = gets.chomp
agent = BoggleAgent.new(board_path, dict_path)
agent.solve(out_path)
puts "Execution successful!"