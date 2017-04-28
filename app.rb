# app.rb

require 'sinatra'
require 'sinatra/activerecord'
#require 'sinatra/namespace'
require './environments'
require 'json'
require 'httparty'

class Venue < ActiveRecord::Base
  self.table_name = 'salesforce.venue__c'

  #has_many :spaces
end

class Space < ActiveRecord::Base
  self.table_name = 'salesforce.space__c'

  #belongs_to :venue
  #has_many :included_spaces
end

class Included_Space < ActiveRecord::Base
  self.table_name = 'salesforce.included_spaces__c'

  #belongs_to :space
end

# Routes

get "/" do
  erb :home
end

get "/venues" do
  @venues = Venue.all
  erb :index
end

get "/space/:record" do
  @space = Space.find_by_sfid(params[:record])

  erb :space
end

get "/spaces/:venue_id" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  @spaces = 
  erb :index
end

get "/:space_id/space.json" do
  @space = Space.find_by_sfid(params[:space_id])
  content_type :json
  { "#{@space.name}" => "#{@space.sfid}", :privacy => "#{@space.privacy__c}" }.to_json
end

get "/:venue_id/spaces" do
  @spaces = Space.where("venue__c = ?", params[:venue_id])
  
  @spaces
end

# Returns Spaces and adds the Booking ID to the array
get "/archive/:booking/:venue" do
  @spaces = Space.where("venue__c = ?", params[:venue]).map do |s|
    s.attributes.merge("booking": params[:booking])
  end

  @spaces.to_json
end

# Returns Spaces and adds the Booking ID to the array. Sends to Zapier.
# Maybe /hook/spaces/:venue/:booking?
post "/archive/:booking/:venue" do
  @spaces = Space.where("venue__c = ?", params[:venue]).map do |s|
    s.attributes.merge("booking": params[:booking])
  end

  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1tx4k1/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })

  @spaces.to_json
end


# Returns Spaces and adds the Booking ID to the array. Sends to Zapier.
# Maybe /hook/spaces/:venue/:booking?
get "/hook/:booking/:venue/:calendar/:start/:end" do
  #@sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", params[:venue],0).map do |s|
  #  s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  #end
  #puts "Made Sub Spaces Hash"

  @spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0)

  puts "Made Spaces Hash"

  puts "Entering Loop"
  @spaces.each do |space|
    puts "#{space.name}"
  #  space = "#{space.id}"
  #  @included_spaces = Included_Space.where("belongs_to__c = ?", space)
  #  puts '#{space.id}'
  #  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
  #  { 
  #    :body => @included_spaces.to_json,
  #    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  #  })
  end
  puts "Backend of Loop"

  #@included_spaces = Included_Spaces.where("belongs_to__c = ?", params[:space])
  #@included_spaces = Space.joins(:venue)
  #.joins(:included_spaces)
  #.where(venue_id: params[:venue])
  #.select('spaces.name')

  puts "Writing Spaces"
  @spaces.to_json
end

# Returns Spaces and adds the Booking ID to the array. Sends to Zapier.
# Maybe /hook/spaces/:venue/:booking?
post "/hook/:booking/:venue/:calendar/:start/:end" do
  puts "Got the data"
  @sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Made Sub Spaces Hash"

  @spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Made Spaces Hash"

  puts "Entering Loop"
  @spaces.each do |s|
    #space = s.sfid
    @included_spaces = Included_Space.where("belongs_to__c = ?", s.sfid)
    puts '#{s.sfid}'
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
    { 
      :body => @included_spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    })
  end
  puts "Backend of Loop"

  #@included_spaces = Space.joins(:venue)
  #.joins(:included_spaces)
  #.where(venue_id: params[:venue])
  #.select('spaces.name')

  #Included_Space.joins(:space).where(:space{:venue => params[:venue]})


  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1znao4/",
  { 
    :body => @sub_spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  puts "Sent Sub Spaces Hook"

  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1adgpy/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  })
  puts "Sent Spaces Hook"

end

# Goal is to Return Included Spaces
get "/included/:space" do
  @spaces = Included_Space.where("belongs_to__c = ?", params[:space])

  #HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1znao4/",
  #{ 
  #  :body => @spaces.to_json,
  #  :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  #})

  puts "Entering Loop"
  @spaces.each do |space|
    puts "#{space.belongs_to__c}"
  #  space = "#{space.id}"
  #  @included_spaces = Included_Space.where("belongs_to__c = ?", space)
  #  puts '#{space.id}'
  #  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
  #  { 
  #    :body => @included_spaces.to_json,
  #    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
  #  })
  end
  
  @spaces.to_json
end

# Returns Spaces that belong to a Parent 
get "/space/:space_id/included_spaces.json" do
  @space = Space.where("space__c = ?",  params[:space_id])

 # if @space.included_spaces__c = 0
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
