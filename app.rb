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
  
  puts "Got the data"
  
  @parent_spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0)
  puts "Retrieved Parent Spaces"

  @spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Retrieved and Mapped Spaces"

  @sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Retrieved and Mapped Sub Spaces"

  puts "Entering Loop"
  @parent_spaces.each do |space|
    space_id = "#{space.sfid}"
    @included_spaces = Included_Space.where("belongs_to__c = ?", space_id)
    puts "Posting #{space.name} - #{space.sfid} to Zapier"
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
    { 
      :body => @included_spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    })
  end
  puts "Out of Loop"

  puts "Writing Spaces"
  @parent_spaces.to_json
end

# Returns Spaces and adds the Booking ID to the array. Sends to Zapier.
# Maybe /hook/spaces/:venue/:booking?
post "/hook/:booking/:venue/:calendar/:start/:end" do
  
  puts "Got the data"
  
  @parent_spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0)
  puts "Retrieved Parent Spaces"

  @spaces = Space.where("venue__c = ? AND included_spaces__c > ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Retrieved and Mapped Spaces"

  @sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", params[:venue],0).map do |s|
    s.attributes.merge("booking": params[:booking],"calendar": params[:calendar],"start": params[:start],"end": params[:end])
  end
  puts "Retrieved and Mapped Sub Spaces"


  puts "Entering Loop"
  @parent_spaces.each do |space|
    space = "#{space.sfid}"
    @included_spaces = Included_Space.where("belongs_to__c = ?", space)
    puts "Posting #{space.sfid} to Zapier"
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
    { 
      :body => @included_spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      # Sends Parent/Included Space Relationships to Compile Parent Space Storage Zap
    })
  end
  puts "Out of Loop"


  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1znao4/",
  { 
    :body => @sub_spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    # Sends all Included Spaces to Check Availability Zap
  })
  puts "Sent Sub Spaces Hook"

  HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1adgpy/",
  { 
    :body => @spaces.to_json,
    :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    # Sends Parent Space to Compile Parent Space Availability
    # Zap delayed from above two, compiling the information from both into Parent Availability
  })
  puts "Sent Spaces Hook"

  puts "Writing Spaces"
  @spaces.to_json
end


# Properly parsed JSON that takes data from Zapier, processes it and returns JSON array
post "/hook/availability/venue" do
  puts request.env
  if request.env['HTTP_AUTH_TOKEN'] === "abcd1234"
    data = JSON.parse(request.body.read)
    # converted data hash
    #  {"end"=>"2017-06-15T00:00:00.000+0000",
    #    "name"=>"Side Patio",
    #    "booking_name"=>"Another Testwood 2",
    #    "venue"=>"a054100000FsEA8AAN",
    #    "start"=>"2017-06-14T20:00:00.000+0000",
    #    "calendar"=>"spacesift.com_oifjmejd2uui1bp254l4u2gloc@group.calendar.google.com",
    #    "sfid"=>"a014100000AYiWHAA1",
    #    "booking"=>"a004100000EHiJDAA1"}

    #  query each value of the hash by data['name of the key']
    #  Example data['end']
    puts "Got the data"
    
    @parent_spaces = Space.where("venue__c = ? AND included_spaces__c > ?", data['venue'],0)
    puts "Retrieved Parent Spaces"
    
    @spaces = Space.where("venue__c = ? AND included_spaces__c > ?", data['venue'],0).map do |s|
      s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
      data['start'],"end": data['end'])
    end
    puts "Retrieved and Mapped Spaces"

    @sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", data['venue'],0).map do |s|
      s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
      data['start'],"end": data['end'])
    end   
    puts "Retrieved and Mapped Sub Spaces"

    puts "Entering Loop"
    @parent_spaces.each do |space|
      @included_spaces = Included_Space.where("belongs_to__c = ?", space.sfid)
      puts "Posting #{space.name} to Zapier"
      HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
      {
        :body => @included_spaces.to_json,
        :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
        # Sends Parent/Included Space Relationships to Compile Parent Space Storage Zap
      })
    end   
    puts "Out of Loop"

    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1znao4/",
    {
      :body => @sub_spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      # Sends all Included Spaces to Check Availability Zap
    })
    puts "Sent Sub Spaces Hook"
  
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1adgpy/",
    {
      :body => @spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      # Sends Parent Space to Compile Parent Space Availability
      # Zap delayed from above two, compiling the information from both into Parent Availability
    })
    puts "Sent Spaces Hook"
    puts "Writing Spaces"
    @spaces.to_json
    [200, {}, "Success"]
  else
    [400, {}, "Authorization Failed"]
  end
end


# Properly parsed JSON that takes data from Zapier, processes it and returns JSON array
post "/hook/availability/space" do
  puts request.env
  if request.env['HTTP_AUTH_TOKEN'] === "abcd1234"
    data = JSON.parse(request.body.read)
    # converted data hash
    #  {"end"=>"2017-06-15T00:00:00.000+0000",
    #    "name"=>"Side Patio",
    #    "booking_name"=>"Another Testwood 2",
    #    "venue"=>"a054100000FsEA8AAN",
    #    "start"=>"2017-06-14T20:00:00.000+0000",
    #    "calendar"=>"spacesift.com_oifjmejd2uui1bp254l4u2gloc@group.calendar.google.com",
    #    "sfid"=>"a014100000AYiWHAA1",
    #    "booking"=>"a004100000EHiJDAA1"}

    #  query each value of the hash by data['name of the key']
    #  Example data['end']

    # This route should only retrieve one parent space, all the included space relationships.
    # Should work as the above route, but we only need to send sub_space data on spaces
    # that are included in the single parent_space

    puts "Got the data"
    
    @included_spaces = Included_Space.where("belongs_to__c = ?", data['sfid'])
    puts "Have Included Spaces"
      
    @included_spaces.each do |space|
      @sub_spaces = Space.where("sfid = ?", space.space__c).map do |s|
        s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
        data['start'],"end": data['end'],"parent": space.belongs_to__c)
      end

      puts "Posting #{space.name} to Zapier for Availability Check"
      HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1znao4/",
      {
        :body => @sub_spaces.to_json,
        :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
        # Sends all Included Spaces to Check Availability Zap
      })
    end

    @spaces = Space.where("sfid = ?", data['sfid']).map do |s|
      s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
      data['start'],"end": data['end'])
    end

    puts "Posting Parent Space to Zapier"
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1adgpy/",
    {
      :body => @spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      # Sends Parent Space to Compile Parent Space Availability
      # Zap delayed from above two, compiling the information from both into Parent Availability
    })

    puts "Posting Relationships to Zapier"
    HTTParty.post("https://hooks.zapier.com/hooks/catch/962269/1efcdv/",
    {
      :body => @included_spaces.to_json,
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      # Sends Parent/Included Space Relationships to Compile Parent Space Storage Zap
    })

    puts "Writing Spaces"
    @spaces.to_json
    [200, {}, "Success"]
  else
    [400, {}, "Authorization Failed"]
  end
end

