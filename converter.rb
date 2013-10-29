require 'rubygems'
require 'sinatra'
require 'curb'
require 'json'
require 'hpricot'
require 'cgi'

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}

# By default present a little homepage
get '/' do
	
	content_type :html
	<<-eos
		<html>
			<title>Tumblr XML to JSON Converter</title>
			<h1>Tumblr XML to JSON Converter</h1>
			<p>By <a href="http://jimwhimpey.com">Jim Whimpey</a></p>
			<p>This is a helper tool for <a href='http://makenosound.com/'>Max Wheeler's</a> idea to
				use <a href="http://mustache.github.com/">Mustache</a> to make <a href="http://www.tumblr.com/docs/en/custom_themes">
				Tumblr theme</a> development much easier.</p>
			<p>It takes the output of a Tumblr blog filled with dummy content using an XML theme and converts it to
				JSON that Mustache can use natively.</p>
			<h2>Usage</h2>
			<ul>
				<li><a href="/content">http://tumblrxmltojson.heroku.com/content</a> for default dummy data</li>
				<li><a href="/content/tumblrthemr.tumblr.com">http://tumblrxmltojson.heroku.com/content/tumblrthemr.tumblr.com</a> for your own dummy data</li>
			</ul>
			<p>Code hosted on <a href="https://github.com/jimwhimpey/Tumblr-XML-to-JSON">github</a></p>
		</html>
  eos
	
end


# Load up a particular URL
get %r{/content/?(.*)} do
	
	# If it's empty use the default
	if (params[:captures][0].empty?)
		url = "http://tumblrthemr.tumblr.com/"
	else 
		url = "http://" + params[:captures][0]
	end
	
	# Pull out the callback function name
	if request.query_string.match(/callback=([^&]+)/)
		callback_name = request.query_string.match(/callback=([^&]+)/)[1]
	end
	
	# Get the XML and process it into a nokogiri doc
	curl = Curl::Easy.new(url)
	curl.follow_location = true
	curl.http_get
	doc = Hpricot::XML(curl.body_str)
	
	# If it has a callback serve jsonp, if not serve regular json
	if callback_name.nil?
		# Call the recursive convertXML function
		json = convertXML(doc.search("//data"))
	else
		# Call the recursive convertXML function
		json = callback_name + "(" + convertXML(doc.search("//data")) + ");"
	end
	
	content_type 'application/javascript'
	response.headers['Access-Control-Allow-Origin'] = '*'
	
	# Crude error checking
	if json == "}"
		{ :Error => "You're not using the proper Tumblr XML theme" }.to_json
	elsif !callback_name.nil? && json == callback_name + "(});"
		callback_name + "({'Error': 'You\'re not using the proper Tumblr XML theme'});" 
	else
		json
	end
	
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
				
				# Work around to stop Tumblr auto inserting it's iFrame code following the body element
				element.name == "FakeBody" ? element_name = "Body" : element_name = element.name
				
				# Add it to the JSON, escaping the quotes
				json += '"' + element_name.gsub(/themr/, '') + '": "' + element.inner_html.gsub(/[\\]/, '\\\\\\').gsub(/["]/, '\"').gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '').gsub(/\n/, '').strip + '",'
				
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
