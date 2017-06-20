# Author: Arne De Herdt
#
# Calculates the binary gap for any given number.
# The binary gap is the largest repeating amount of 0
# in the binary notation of a given number.
#
# For example:
# n = 1041=10000010001_2 => 5
# n = 16 = 10000 => 4
#
def binary_gap(n)
  highest_count = 0
  binary_notation = "%b" % n
  counter = 0
  
  binary_notation.each_char do |character|
    if character == "1"
      highest_count = counter if counter >= highest_count
      counter = 0
    else
      counter += 1
    end
  end
  
  return highest_count
end
