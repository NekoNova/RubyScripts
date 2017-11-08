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

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

base_url = "https://xs.ruk.cuni.cz/Leset-web/"

def download_images(url, base_url)
	full_url = URI.join(base_url,url.gsub("./", ""))
	
	puts "Downloading images from #{full_url}"
	page = Nokogiri::HTML(open(full_url))
	
	page.css("a").each do |link|
		file_name = link["href"].split("/").last
		puts "Image Found: #{file_name}"
		
		File.open(File.expand_path("downloads/#{file_name}"), "wb") do |file|
			file << open(URI.join(full_url.to_s.gsub("index.html",""), link["href"].gsub("./", ""))).read
		end
	end
end

# Prepare the download directory if it doesn't exist.
Dir.mkdir "downloads" unless File.exists?("downloads")

# Travel the links from the page recursively
page = Nokogiri::HTML(open(base_url))
	
page.css("a").each do |link|
	next unless link["href"].include?("index.html")
	download_images(link["href"], base_url)
end