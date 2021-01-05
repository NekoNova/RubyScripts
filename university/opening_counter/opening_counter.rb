# This script performs some basic statistical calculation on the files in the current directory.
# The script will look for a file called data.txt, which holds the information per line.
# Each line will be parsed, and added to a local hash to count the information.

puts 'Loading data from file...'
score = {}

# Loop over the lines in the file, and parse the line individually.
File.foreach('data.log') do |line|
  # Each line starts and ends with a vertical pipe, so let's strip those first.
  line[0] = ''
  line[line.length - 1] = ''

  # Remove all whitespace from the line as well
  line.strip!

  # Now we can parse the data.
  # We will set the score to 0 initially if there's no key entry yet for the given PID.
  # The count value will simply be added to the existing value
  _id, pid, count = line.split('|')

  score[pid] = 0 unless score.key?(pid)
  score[pid] += count.to_i
end

# Now that we have calculated the entire section for all the files present, we can output the top 5.
top_five = Hash[score.sort_by { |_pid, count| count }.reverse[0..4]]

puts 'Calculation finished!'
puts 'Top 5 winners are:'

top_five.each do |pid, count|
  puts "#{pid} => #{count}"
end
