class MessageStrategy
  def self.execute(parser, data)
    parser.propagate_response = true
    Message.create(owner: data["owner"], body: data["message"])
  end
end
