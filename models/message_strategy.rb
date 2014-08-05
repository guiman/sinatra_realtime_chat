class MessageStrategy
  def self.execute(parser, data)
    Message.create(owner: data["owner"], body: data["message"])
    parser.propagate = true
  end
end
