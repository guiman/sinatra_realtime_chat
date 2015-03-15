class StreamResponse
  attr_accessor :method, :data

  def initialize(method, data)
    @method = method
    @data = data
  end

  def send(output)
    output.send({ method: @method, body: @data }.to_json)
  end
end
