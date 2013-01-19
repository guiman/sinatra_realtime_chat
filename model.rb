class Message
  include DataMapper::Resource
  
  property :id, Serial
  property :owner, String
  property :body, Text
  property :created_at, Time
    
  def to_json(*a)
    {
      'owner' => owner,
      'body'  => body,
      'created_at' => created_at
    }.to_json(*a)
  end
end

class User
  include DataMapper::Resource
  
  property :id, Serial
  property :username, String
  
  def to_json(*a)
    { 'username' => username }.to_json(*a)
  end
end

class StreamResponse
  attr_accessor :type, :data, :body
  
  def initialize(type, data)
    @type = type
    @data = data
  end
  
  def send(output)
    output << "event: #{type.to_s}\n"
    output << "data: #{data.to_json}\n\n"
  end
end
