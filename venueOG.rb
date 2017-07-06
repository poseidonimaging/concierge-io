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
      data['start'],"end": data['end'],"slack_timestamp": data['slack_timestamp'])
    end
    puts "Retrieved and Mapped Spaces"

    @sub_spaces = Space.where("venue__c = ? AND included_spaces__c = ?", data['venue'],0).map do |s|
      s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
      data['start'],"end": data['end'],"slack_timestamp": data['slack_timestamp'])
    end   
    puts "Retrieved and Mapped Sub Spaces"

    puts "Entering Loop"
    @parent_spaces.each do |space|
      @included_spaces = Included_Space.where("belongs_to__c = ?", space.sfid).where.not(space__c: data['exclude'] ).map do |s|
        s.attributes.merge("booking": data['booking'],"calendar": data['calendar'],"start":
        data['start'],"end": data['end'], "slack_timestamp": data['slack_timestamp'])
      end

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
    [200, {status: "success"}.to_json]
  else
    [401, {status: "authorization failed"}.to_json]
  end
end