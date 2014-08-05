class ParseRequest
  def initialize(data)
    parsed_data = JSON.parse(data)
    @method = parsed_data["method"] || :unknown
    @body = parsed_data["body"]
  end

  def response
    StreamResponse.new(@method, find_handler_by_method.execute)
  end

  def find_handler_by_method
    Object.const_get("#{@method.to_s.capitalize}Strategy")
  end
end
