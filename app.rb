# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'


get "/" do
  erb :home
end


class Space < ActiveRecord::Base
  self.table_name = 'salesforce.space__c'
end

class Venue < ActiveRecord::Base
  self.table_name = 'salesforce.venue__c'
end

get "/spaces" do
  @spaces = Space.all
  erb :index
end

get "/venues" do
  @venues = Venue.all
  erb :index
end

get "/create" do
  dashboard_url = 'https://dashboard.heroku.com/'
  match = /(.*?)\.herokuapp\.com/.match(request.host)
  dashboard_url << "apps/#{match[1]}/resources" if match && match[1]
  redirect to(dashboard_url)
end
