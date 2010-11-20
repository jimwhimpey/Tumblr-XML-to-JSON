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
	
	# Start a looping
	doc.search("//data/").each do |element|
		
		# Only get elements, not text or comments
		if (element.is_a?(Hpricot::Elem))
			
			# If it's not a block element
			if (!/^block./.match(element.name))
				
				# Add it to the JSON, escaping the quotes
				json += '"' + element.name + '": "' + element.inner_html.gsub(/["]/, '\\\\"') + '",'
				
			else
				
				# It's a block so we'll dive deeper
				# If it contains items
				if (element.search("/item").length > 0)
					# Has items
					puts element.name + " has items"
				else
					
					# No items, regular data
					json += '"' + element.name + '": {'
					element.search("/").each do |child|
						if (child.is_a?(Hpricot::Elem))
							json += '"' + child.name + '": "' + child.inner_html.gsub(/["]/, '\\\\"') + '",'
						end
					end
					json.chop! << "},"
					
				end
				
			end
			
		end
		
	end
	
	# Remove the final comma Close the JSON string
	json.chop! << "}"
	
	puts json
	
	content_type :json
	json
	
end