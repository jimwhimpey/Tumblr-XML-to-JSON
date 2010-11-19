require 'rubygems'
require 'sinatra'
require 'curb'
require 'nokogiri'
require 'htmlentities'

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}

get '/' do
  # Render the HAML template
  haml :home
end