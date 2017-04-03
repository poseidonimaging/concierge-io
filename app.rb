# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'
require 'json'


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

#get "/:object/:record" do
  #@space = Space.find_by_sfid(params[:record])
  #@venue = Venue.find_by_handle(params[:venue])

#  @space = Space.where(:record => @venue.id)

#  erb :index
#end

get "/space/:record" do
  @space = Space.find_by_sfid(params[:record])

  erb :space
end

get "/spaces/:venue_id" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])

  erb :index
end

get "/:space_id/space.json" do
  @space = Space.find_by_sfid(params[:space_id])
  content_type :json
  { "#{@space.sfid}" => "#{@space.name}", :privacy => "#{@space.privacy__c}" }.to_json
end

get "/venue/:venue_id/spaces.json" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  content_type :json
  { :name => @space.name, :privacy => @space.privacy }.to_json
end

get "/:object/:record/output.json" do
  @space = Space.find_by_sfid(params[:record])
  content_type :json
  { :name => @space.name, :privacy => @space.privacy }.to_json
end

get '/example.json' do
  content_type :json
  { :name => 'value1', :privacy => 'value2' }.to_json
end

get "/create" do
  dashboard_url = 'https://dashboard.heroku.com/'
  match = /(.*?)\.herokuapp\.com/.match(request.host)
  dashboard_url << "apps/#{match[1]}/resources" if match && match[1]
  redirect to(dashboard_url)
end
