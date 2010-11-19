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
	doc = Hpricot(xml_call.body_str)
		
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
				
				
			end
			
		end
		
	end
	
	# Remove the final comma Close the JSON string
	json.chop! << "}"
	
	content_type :json
	json
	
end