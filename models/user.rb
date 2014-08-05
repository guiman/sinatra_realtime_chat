class User
  include DataMapper::Resource

  property :id, Serial
  property :username, String

  def to_json(*a)
    { 'username' => username }.to_json(*a)
  end
end
