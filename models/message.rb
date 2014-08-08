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
