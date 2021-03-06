class Race
  include ActiveModel::Serialization
  attr_accessor :id, :initiator, :destination, :participants, :invitees

  include GlobalID::Identification

  def self.find(id)
    self.new(id)
  end

  def id
    @id
  end

  def initialize(race_id = nil, user_id = nil)
    firebase = Firebase::Client.new(Rails.configuration.x.firebase_uri)

    # create a new race
    if race_id.nil?
      response = firebase.push('races', {:initiator => user_id})
      @id = response.body['name']
      @initiator = User.new(user_id)
      return
    end

    # load the given race
    @id = race_id
    @destination = nil
    @participants = []
    @invitees = []
    load
  end

  def load
    firebase = Firebase::Client.new(Rails.configuration.x.firebase_uri)
    response = firebase.get("races/#{@id}/")

    # the race exists; let's load it up
    if defined? response.body['initiator']
      @initiator = User.new(response.body['initiator'])
      @destination = response.body['destination'] || nil
      @participants = response.body['participants'] || nil
      @invitees = response.body['invitees'] || nil
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def attributes
    {
        :id => @id,
        :initiator => @initiator,
        :destination => @destination,
        :participants => @participants,
        :invitees => @invitees
    }
  end


  # Adds a user to the race's confirmed participants.
  def rsvp (user, accepted_invitation)
    case accepted_invitation
      when false
        accepted_invitation = 'declined'
      when true
        accepted_invitation = 'accepted'
    end

    firebase = Firebase::Client.new(Rails.configuration.x.firebase_uri)
    response = firebase.update("races/#{@id}/invitees", { user.id => accepted_invitation })
    response.success?
  end
end