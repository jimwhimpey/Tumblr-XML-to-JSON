require 'rubygems'
require 'sinatra'
require 'curb'
require 'json'
require 'nokogiri'
require 'hpricot'
require 'htmlentities'

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}

get '/' do
	
	# Start up the JSON string
	json = "{"
	
	# Get the XML and process it into a nokogiri doc
	xml_call = Curl::Easy.perform("http://daydreamtheme.tumblr.com/")
	doc = Hpricot::XML(xml_call.body_str)
	
	# Call the recursive convertXML function
	json = convertXML(doc.search("//data"))
	
	puts json
	
	content_type :json
	json
	
end




# Takes a given block of XML, loops through and converts it to JSON.
# If it finds a bit of XML with children it needs to delve further into it'll
# call itself and keep doing that until it reaches the fartherest branches of the tree
def convertXML(xml)
	
	# Start up the JSON string we'll eventually return
	json = "{"
	
	# Start the loop
	xml.search("/").each do |element|
		
		# Only get elements, not text or comments
		if (element.is_a?(Hpricot::Elem))
			
			# If it's not a block element
			if (!/^block./.match(element.name))
				
				# Add it to the JSON, escaping the quotes
				json += '"' + element.name + '": "' + element.inner_html.gsub(/["]/, '\'').gsub(/[\\]/, '').strip + '",'
				
			else
				
				# Check if it contains items and will need to be an array
				if (element.search("/item").length > 0)
					
					# Contains items, needs to be an array
					json += '"' + element.name + '": ['
					
					# Loop through them and convert to JSON
					element.search("/item").each do |item|
						if (element.is_a?(Hpricot::Elem))
							json += convertXML(Hpricot::XML(item.inner_html))
							json += ","
						end
					end
					
					# Close it up
					json.chop! << "],"
					
				else
					
					# Just a regular block, output it
					json += '"' + element.name + '": '
					json += convertXML(Hpricot::XML(element.inner_html))
					json += ','
					
				end
				
			end
			
		end
		
	end
	
	# Remove the final comma Close the JSON string
	return json.chop! << "}"
	
end
