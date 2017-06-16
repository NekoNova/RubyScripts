# This script will scan the folder it's currently in for all XML files.
# Then it will load all XML files and scan their contents for the pattern clause=""
# where any error code can be match.
# When it's done it will output in a small text file, every error code found and it's occurance.
require 'csv'

puts "Scanning for files..."
files = Dir.new('.').select { |e| File.file?(e) && File.extname(e) == ".xml" }

puts "#{files.length} XML files found"
data = {}

# Now we loop over the files and proceed with scanning their contents.
# If any of the lines match the content we're looking for, extract the error
# and store it inside the data hash. If the key already exists, increment it's value
files.each do |path|
  puts "Scanning #{path} for error entries..."
  
  File.foreach(path) do |line|
    # If we encounter the clause line...
    if line =~ %r{clause="(\d\.?)+"}
      # Extract the error code by looking up the match and stripping the useless parts
      # Regexp.last_mach(0) is the first matching entry, and we strip of the wrapping data.
      error_code = Regexp.last_match(0).gsub('clause=', '').gsub('"', '')
      
      # If the error key already exists in the hash, increment the counter.
      # Otherwise just add it as one.
      if data.key?(error_code)
        data[error_code] += 1
      else
        data[error_code] = 1
      end
    end
  end
end

# Sort the hash cause the keys are strings.
data = Hash[data.sort]

# Write the found information into a single file.
# We will make 2 columns, writing the error code and it's count
CSV.open('scanner_results.csv', 'wb') do |csv|
  data.each do |key, value|
    csv << [key, value]
  end
end
