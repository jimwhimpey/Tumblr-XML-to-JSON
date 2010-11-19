require 'rubygems'
require 'sinatra'
require 'curb'
require 'json'
require 'nokogiri'
require 'hpricot'
require 'htmlentities'
require 'activesupport'

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}

get '/' do
	
	# Get the XML and process it into a nokogiri doc
	xml_call = Curl::Easy.perform("http://daydreamtheme.tumblr.com/")
	doc = Hpricot(xml_call.body_str)
		
	json = Hash.from_xml(xml_call.body_str).to_json
	
	content_type :json
	json
	
end