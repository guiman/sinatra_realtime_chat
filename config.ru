require './chat'
use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'
use Rack::Deflater
run ChatApp