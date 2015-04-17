###############################################################################
# Installation guide:
#
# Run the following command to ensure that the required gems are available:
#
# gem install nokogiri
#
#
# Usage:
#
# ruby transform.rb -i input -o output
#
# - input = the source XML file or source directory
# - output = the output XML file or output directory
#
# Can be absolute paths, or relative paths, makes no difference to ruby.
# The script asssumes Ruby 2.1 or higher to be installed on the system.
# Directories MUST exist, script will not create them
#
# Author: Arne De Herdt (arne.de.herdt@gmail.com)
################################################################################
require "nokogiri"
require "optparse"
require "ostruct"
require "pp"
require "pathname"

###############################################################################
# Before anything, change the working directory to the location of our script
# This ensures that everything works as expected.
###############################################################################
Dir.chdir(File.dirname(__FILE__))

###############################################################################
# Construct a class that will parse the required options for our script
# This makes it easier to extend the script later on.
###############################################################################
class OptParser
	#
	# Return a structure describing the options
	#
	def self.parse(args)
		# The options specified on the command line will be collected in *options*.
		# We set the default values here.
		options = OpenStruct.new
		
		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: transform.rb [options]"
			opts.separator ""
			opts.separator "Specific options:"
			
			# Mandatory -i argument
			opts.on("-i", "--input PATH", "The XML file that will act as input, or a directory containing the input files") do |p|
				options.input_path = p
				options.input_is_dir = Pathname.new(p).directory?
			end
			
			# Mandatory -o argument
			opts.on("-o", "--output PATH", "The XML file that will act as output, or a directory containing the output files") do |p|
				options.output_path = p
				options.output_is_dir = Pathname.new(p).directory?
			end
			
			# Tail output
			opts.on_tail("-h", "--help", "Shows this message") do
				puts opts
				exit
			end
		end
		
		opt_parser.parse!(args)
		options
	end
end

###############################################################################
# This function generates the output name based on the provided input xml file.
###############################################################################
def output_name(input)
  return "#{File.basename(input, ".xml")}.output.xml"
end

###############################################################################
# This function basically takes the name of the input XML file and 
# optionally the output name.
# If no output name is defined, then the output file will be 
# inputname.output.xml. The function performs the entire transformation
#
# If the output is a directory, the third param needs to be set to true,
# so the function knows that it is dealing with an input that needs to be
# stored somewhere else.
###############################################################################
def transform_xml(input, output = nil, output_is_dir = false)
  # Generate the output file name.
  output_file = output
  if output.nil? or output_is_dir
    output_file = output_name(input)
  end
  
  # If we're dealing with a directory, then update the output name
  # This means appending the output dir + file name to be safe.
  if output_is_dir
    output_file = "#{output}/#{output_file}"
  end
  
  # Perform a bit of output
  puts "Parsing #{input} into #{output_file}"
  
  # Load the XML file
  f_in = File.open(input)
  f_out = File.new(output_file, "w+")
  doc_in = Nokogiri::XML(f_in)
  
  # Generate the output XML
  doc_out = Nokogiri::XML::Builder.new do |xml|
    # TODO: Parsing goes here
  end
  
  # Write to the output file
  f_out.write(doc_out.to_xml)
  
  # Close the file handlers
  f_in.close
  f_out.close
end

###############################################################################
# Parse the options we have received.
###############################################################################
options = OptParser.parse(ARGV)

###############################################################################
# Perform the parsing:
#
# - check 1 : input and output are both folders, so we copy from input
#             to output, file per file
# - check 2 : input and output are files, so we perform the operation once
#
# In all other cases, we do nothing
###############################################################################
if options.input_is_dir && options.output_is_dir
  # Loop over each file in the input dir.
  Dir.foreach(options.input_path) do |p|
    file = Pathname.new(p)
    
    # We only want to parse XML files, no directories or symlinks
    unless(p == "." or p == ".." or file.directory? or file.extname != ".xml")
      transform_xml(p, options.output_path, true) 
    end
  end
elsif !options.input_is_dir && !options.output_is_dir
  transform_xml(options.input_path, options.output_path)
elsif !options.input_is_dir && options.output_is_dir
  transform_xml(options.input_path, options.output_path, true)
else
  pp "options received:"
  pp options
  pp "We cannot do anything with this combination. Either provide:"
  pp "- an input & output file"
  pp "- input & output folder"
  pp "- input file & output folder"
end