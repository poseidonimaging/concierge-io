# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require './environments'
require 'json'
require 'httparty'


class Space < ActiveRecord::Base
  self.table_name = 'salesforce.space__c'
end

class Venue < ActiveRecord::Base
  self.table_name = 'salesforce.venue__c'
end

namespace '/api/v1 ' do

  before do
    content_type 'application/json'
  end

  get '/spaces' do
    Space.all.to_json
  end
end  

get "/" do
  erb :home
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
  { "#{@space.name}" => "#{@space.sfid}", :privacy => "#{@space.privacy__c}" }.to_json
end

# This route works
get "/venue/:venue_id/spaces.json" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  #content_type :json
  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1tx4k1/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  @spaces.to_json
end

# Returns Spaces that below to a Parent 
get "/space/:space_id/included_spaces.json" do
  @space = Space.where("space__c = ?",  params[:space_id])

  if @space.included_spaces__c = 0
    # Use the current Space
  @spaces = Included_Space.where("belongs_to__c = ?", params[:space_id])
  #content_type :json
  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1tx4k1/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  @spaces.to_json
end

# Test Webhook
get "/venue/:venue_id/spaces" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  #content_type :json
  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1tx4k1/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  @spaces.to_json
end

get "/venue/spaces.json" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  #content_type :json
  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1tx4k1/",
  { 
    :body => [ {:name => 'value1', :privacy => 'value2'} ].to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  @spaces.to_json
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
