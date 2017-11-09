# Arne De Herdt
#
# Website, Image downloader v1.
# This ruby script will parse a raw URL and download all images from it.
require "net/http"
require "uri"
require "rubygems"
require "nokogiri"
require "open-uri"
require "openssl"

puts "=================================="
puts "                                  "
puts " Oli's amazing script!            "
puts " v1.0.3                           "
puts "=================================="
puts ""
puts "configuring SSL..."
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

base_url = "https://xs.ruk.cuni.cz/Leset-web/"

# Prepare the download directory if it doesn't exist.
puts "Verifying download folder..."
Dir.mkdir "downloads" unless File.exists?("downloads")

def download_images(link_url, base_url)
	full_page_url = File.join(base_url,link_url.gsub("./", ""))
	
	puts "Downloading images from #{full_page_url}"
	
	begin
		page = Nokogiri::HTML(open(URI.escape(full_page_url)))
		
		page.css("a").each do |link|
			file_name = link["href"].split("/").last		
			path = File.expand_path("downloads/#{file_name}")
			
			next if File.exists?(path)
			
			begin 
				File.open(path, "wb") do |file|
					domain = full_page_url.to_s.gsub("index.html","")
					file_uri = link["href"].gsub("./", "")
					encoded_uri = File.join(domain, file_uri)
					
					print "Downloading #{encoded_uri} ..."
					
					file << open(URI.escape(encoded_uri)).read
					
					print "\r"
				end
			rescue OpenURI::HTTPError => e
				# We can't do anything if the server reports a 404
				puts "#{file_name} could not be downloaded due HTTP 404 response" 
			end
		end
	rescue OpenURI::HTTPError => e
		puts "[ERROR] Could not open #{URI.escape(full_page_url)} - skipping..."
	end
end

# Travel the links from the page recursively
page = Nokogiri::HTML(open(base_url))
	
page.css("a").reverse.each do |link|
	next unless link["href"].include?("index.html")
	download_images(link["href"], base_url)
end
