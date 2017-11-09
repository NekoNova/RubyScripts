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
puts " v1.0.5                           "
puts "=================================="
puts ""
puts "configuring SSL..."
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

base_url = "https://xs.ruk.cuni.cz/Leset-web/"

# Prepare the download directory if it doesn't exist.
puts "Verifying download folder..."
Dir.mkdir "downloads" unless File.exists?("downloads")

def escape_url(url)
	return (URI.unescape(url) == url) ? URI.escape(url) : url
end

def download_images(link_url, base_url)
	full_page_url = File.join(base_url,link_url.gsub("./", ""))
	
	puts "Downloading images from #{full_page_url}"
	
	begin
		page = Nokogiri::HTML(open(escape_url(full_page_url)))
		
		page.css("a").each do |link|
			file_name = link["href"].split("/").last		
			path = File.expand_path("downloads/#{file_name}")
			
			next if File.exists?(path)
			
			begin 
				File.open(path, "wb") do |file|
					collection_uri = full_page_url.to_s.gsub("index.html","")
					file_uri = link["href"].gsub("./", "")
					complete_uri = File.join(collection_uri, file_uri)
					
					print "Downloading #{complete_uri} ..."
					
					file << open(escape_url(complete_uri)).read
					
					print "\r"
				end
			rescue OpenURI::HTTPError => e
				puts "[ERROR] #{file_name} could not be downloaded due HTTP 404 response"
				puts "[ERROR] #{e.message}"
			end
		end
	rescue OpenURI::HTTPError => e
		puts "[ERROR] Could not open #{full_page_url} - skipping..."
		puts "[ERROR] #{e.message}"
	end
end

# Travel the links from the page recursively
page = Nokogiri::HTML(open(base_url))
	
page.css("a").reverse.each do |link|
	next unless link["href"].include?("index.html")
	
	if link["href"] == "./sl-smiÞ/index.html"
		puts "cause we don't support Þ, so let's use ř"
		download_images("./sl-smiř/index.html", base_url)
	else
		download_images(link["href"], base_url)
	end
end
