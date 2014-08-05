class ParseRequest
  def initialize(data)
    parsed_data = JSON.parse(data)
    parsed_method = parsed_data.fetch("method", :missing).to_sym
    @method = available_methods.include?(parsed_method) ? parsed_method : :unknown
    @body = parsed_data["body"]
  end

  def available_methods
    [:unknown, :missing, :messages, :users]
  end

  def response
    StreamResponse.new(@method, find_handler_by_method.execute)
  end

  def find_handler_by_method
    Object.const_get("#{@method.to_s.capitalize}Strategy")
  end
end
